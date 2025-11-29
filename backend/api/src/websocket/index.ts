import { WebSocketServer, WebSocket } from 'ws';
import { queueEvents } from '../services/queue.js';
import { getJob } from '../services/jobs.js';
import { logger } from '../utils/logger.js';
import { WsMessage } from '../types/index.js';

// Подписки клиентов на задачи
const subscriptions = new Map<string, Set<WebSocket>>();

export const setupWebSocket = (wss: WebSocketServer) => {
  wss.on('connection', (ws) => {
    logger.debug('WebSocket client connected');

    ws.on('message', async (data) => {
      try {
        const message: WsMessage = JSON.parse(data.toString());
        
        if (message.type === 'subscribe' && message.jobId) {
          // Подписка на обновления задачи
          if (!subscriptions.has(message.jobId)) {
            subscriptions.set(message.jobId, new Set());
          }
          subscriptions.get(message.jobId)!.add(ws);
          
          // Отправить текущий статус
          const job = await getJob(message.jobId);
          if (job) {
            ws.send(JSON.stringify({
              type: 'progress',
              jobId: message.jobId,
              data: { status: job.status, progress: job.progress },
            }));
          }
        }
        
        if (message.type === 'unsubscribe' && message.jobId) {
          subscriptions.get(message.jobId)?.delete(ws);
        }
      } catch (error) {
        logger.error('WebSocket message error:', error);
      }
    });

    ws.on('close', () => {
      // Удалить из всех подписок
      subscriptions.forEach((clients) => clients.delete(ws));
      logger.debug('WebSocket client disconnected');
    });
  });

  // Слушать события очереди и рассылать обновления
  queueEvents.on('progress', ({ jobId, data }) => {
    broadcastToJob(jobId, {
      type: 'progress',
      jobId,
      data,
    });
  });

  queueEvents.on('completed', async ({ jobId }) => {
    const job = await getJob(jobId);
    broadcastToJob(jobId, {
      type: 'completed',
      jobId,
      data: { status: 'completed', resultFileId: job?.resultFileId },
    });
  });

  queueEvents.on('failed', ({ jobId, failedReason }) => {
    broadcastToJob(jobId, {
      type: 'error',
      jobId,
      data: { status: 'failed', error: failedReason },
    });
  });
};

// Рассылка сообщения подписчикам задачи
const broadcastToJob = (jobId: string, message: WsMessage) => {
  const clients = subscriptions.get(jobId);
  if (!clients) return;

  const data = JSON.stringify(message);
  clients.forEach((ws) => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(data);
    }
  });
};
