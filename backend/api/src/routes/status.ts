import { Router } from 'express';
import { getJob } from '../services/jobs.js';
import { getDownloadUrl } from '../services/storage.js';
import { AppError } from '../middleware/errorHandler.js';

export const statusRouter = Router();

// GET /api/status/:jobId - статус задачи
statusRouter.get('/:jobId', async (req, res, next) => {
  try {
    const { jobId } = req.params;
    const job = await getJob(jobId);

    if (!job) {
      throw new AppError(404, 'Job not found');
    }

    let downloadUrl: string | undefined;
    if (job.status === 'completed' && job.resultFileId) {
      downloadUrl = await getDownloadUrl(`results/${jobId}.${job.targetFormat}`);
    }

    res.json({
      success: true,
      data: {
        jobId: job.id,
        status: job.status,
        progress: job.progress,
        sourceFormat: job.sourceFormat,
        targetFormat: job.targetFormat,
        createdAt: job.createdAt,
        updatedAt: job.updatedAt,
        downloadUrl,
        error: job.error,
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/download/:jobId - скачивание результата
statusRouter.get('/download/:jobId', async (req, res, next) => {
  try {
    const { jobId } = req.params;
    const job = await getJob(jobId);

    if (!job) {
      throw new AppError(404, 'Job not found');
    }

    if (job.status !== 'completed') {
      throw new AppError(400, 'Conversion not completed yet');
    }

    const downloadUrl = await getDownloadUrl(`results/${jobId}.${job.targetFormat}`);
    res.redirect(downloadUrl);
  } catch (error) {
    next(error);
  }
});
