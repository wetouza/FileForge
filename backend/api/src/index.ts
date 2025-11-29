import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { WebSocketServer } from 'ws';
import { createServer } from 'http';
import { config } from './config/index.js';
import { logger } from './utils/logger.js';
import { errorHandler } from './middleware/errorHandler.js';
import { uploadRouter } from './routes/upload.js';
import { convertRouter } from './routes/convert.js';
import { statusRouter } from './routes/status.js';
import { formatsRouter } from './routes/formats.js';
import { setupWebSocket } from './websocket/index.js';

const app = express();
const server = createServer(app);

// Middleware
app.use(helmet());
app.use(cors({ origin: config.corsOrigins }));
app.use(express.json());

// Health check
app.get('/health', (_, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));

// Routes
app.use('/api/upload', uploadRouter);
app.use('/api/convert', convertRouter);
app.use('/api/status', statusRouter);
app.use('/api/formats', formatsRouter);

// Error handler
app.use(errorHandler);

// WebSocket
const wss = new WebSocketServer({ server, path: '/ws' });
setupWebSocket(wss);

// Start server
server.listen(config.port, () => {
  logger.info(`🚀 FileForge API running on port ${config.port}`);
});

export { app, server };
