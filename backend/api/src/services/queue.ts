import { Queue, QueueEvents } from 'bullmq';
import IORedis from 'ioredis';
import { config } from '../config/index.js';
import { ConversionJob, ConversionOptions } from '../types/index.js';
import { logger } from '../utils/logger.js';

// Redis подключение
const connection = new IORedis(config.redis.url, { maxRetriesPerRequest: null });

// Очередь конвертации
export const conversionQueue = new Queue<ConversionJobData>('conversion', { connection });

// События очереди
export const queueEvents = new QueueEvents('conversion', { connection });

// Данные задачи
export interface ConversionJobData {
  jobId: string;
  sourceKey: string;
  sourceFormat: string;
  targetFormat: string;
  options?: ConversionOptions;
}

// Добавить задачу в очередь
export const addConversionJob = async (
  jobId: string,
  sourceKey: string,
  sourceFormat: string,
  targetFormat: string,
  options?: ConversionOptions
): Promise<void> => {
  await conversionQueue.add('convert', {
    jobId,
    sourceKey,
    sourceFormat,
    targetFormat,
    options,
  }, {
    jobId,
    attempts: 3,
    backoff: { type: 'exponential', delay: 1000 },
    removeOnComplete: { age: 3600 },
    removeOnFail: { age: 86400 },
  });

  logger.info(`Job ${jobId} added to queue: ${sourceFormat} -> ${targetFormat}`);
};

// Слушатели событий
queueEvents.on('completed', ({ jobId }) => {
  logger.info(`Job ${jobId} completed`);
});

queueEvents.on('failed', ({ jobId, failedReason }) => {
  logger.error(`Job ${jobId} failed: ${failedReason}`);
});
