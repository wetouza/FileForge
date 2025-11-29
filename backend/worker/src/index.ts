import { Worker, Job } from 'bullmq';
import IORedis from 'ioredis';
import dotenv from 'dotenv';
import { logger } from './utils/logger.js';
import { processConversion } from './processors/index.js';
import { ConversionJobData } from './types.js';

dotenv.config();

const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', {
  maxRetriesPerRequest: null,
});

// Worker для обработки конвертаций
const worker = new Worker<ConversionJobData>(
  'conversion',
  async (job: Job<ConversionJobData>) => {
    logger.info(`Processing job ${job.id}: ${job.data.sourceFormat} -> ${job.data.targetFormat}`);
    
    try {
      const result = await processConversion(job);
      logger.info(`Job ${job.id} completed successfully`);
      return result;
    } catch (error) {
      logger.error(`Job ${job.id} failed:`, error);
      throw error;
    }
  },
  {
    connection,
    concurrency: 3,
    limiter: {
      max: 10,
      duration: 60000, // 10 задач в минуту
    },
  }
);

// События worker'а
worker.on('completed', (job) => {
  logger.info(`✅ Job ${job.id} completed`);
});

worker.on('failed', (job, err) => {
  logger.error(`❌ Job ${job?.id} failed: ${err.message}`);
});

worker.on('error', (err) => {
  logger.error('Worker error:', err);
});

logger.info('🔧 FileForge Worker started');

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('Shutting down worker...');
  await worker.close();
  process.exit(0);
});
