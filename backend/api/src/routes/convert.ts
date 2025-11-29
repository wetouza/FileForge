import { Router } from 'express';
import { z } from 'zod';
import { createJob } from '../services/jobs.js';
import { addConversionJob } from '../services/queue.js';
import { canConvert, getFormat } from '../services/formats.js';
import { AppError } from '../middleware/errorHandler.js';
import { logger } from '../utils/logger.js';

export const convertRouter = Router();

// Схема валидации запроса
const convertSchema = z.object({
  fileId: z.string().uuid(),
  s3Key: z.string(),
  sourceFormat: z.string(),
  targetFormat: z.string(),
  options: z.object({
    quality: z.number().min(1).max(100).optional(),
    resolution: z.string().optional(),
    bitrate: z.string().optional(),
    codec: z.string().optional(),
    fps: z.number().optional(),
    sampleRate: z.number().optional(),
    channels: z.number().optional(),
    compression: z.number().optional(),
  }).optional(),
});

// POST /api/convert - запуск конвертации
convertRouter.post('/', async (req, res, next) => {
  try {
    const body = convertSchema.parse(req.body);
    const { fileId, s3Key, sourceFormat, targetFormat, options } = body;

    // Проверка форматов
    if (!getFormat(sourceFormat)) {
      throw new AppError(400, `Unknown source format: ${sourceFormat}`);
    }
    if (!getFormat(targetFormat)) {
      throw new AppError(400, `Unknown target format: ${targetFormat}`);
    }
    if (!canConvert(sourceFormat, targetFormat)) {
      throw new AppError(400, `Cannot convert ${sourceFormat} to ${targetFormat}`);
    }

    // Создание задачи
    const job = await createJob(fileId, sourceFormat, targetFormat, options);
    
    // Добавление в очередь
    await addConversionJob(job.id, s3Key, sourceFormat, targetFormat, options);

    logger.info(`Conversion started: ${job.id} (${sourceFormat} -> ${targetFormat})`);

    res.json({
      success: true,
      data: {
        jobId: job.id,
        status: job.status,
        sourceFormat,
        targetFormat,
      },
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return next(new AppError(400, `Validation error: ${error.errors.map(e => e.message).join(', ')}`));
    }
    next(error);
  }
});
