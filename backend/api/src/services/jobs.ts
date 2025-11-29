import IORedis from 'ioredis';
import { config } from '../config/index.js';
import { ConversionJob, JobStatus, ConversionOptions } from '../types/index.js';
import { v4 as uuid } from 'uuid';

const redis = new IORedis(config.redis.url);

const JOB_PREFIX = 'job:';
const JOB_TTL = 86400; // 24 часа

// Создать новую задачу
export const createJob = async (
  sourceFileId: string,
  sourceFormat: string,
  targetFormat: string,
  options?: ConversionOptions
): Promise<ConversionJob> => {
  const job: ConversionJob = {
    id: uuid(),
    sourceFileId,
    sourceFormat,
    targetFormat,
    status: 'pending',
    progress: 0,
    createdAt: new Date(),
    updatedAt: new Date(),
    options,
  };

  await redis.setex(`${JOB_PREFIX}${job.id}`, JOB_TTL, JSON.stringify(job));
  return job;
};

// Получить задачу
export const getJob = async (jobId: string): Promise<ConversionJob | null> => {
  const data = await redis.get(`${JOB_PREFIX}${jobId}`);
  if (!data) return null;
  
  const job = JSON.parse(data);
  job.createdAt = new Date(job.createdAt);
  job.updatedAt = new Date(job.updatedAt);
  return job;
};

// Обновить статус задачи
export const updateJobStatus = async (
  jobId: string,
  status: JobStatus,
  progress?: number,
  resultFileId?: string,
  error?: string
): Promise<void> => {
  const job = await getJob(jobId);
  if (!job) return;

  job.status = status;
  job.updatedAt = new Date();
  if (progress !== undefined) job.progress = progress;
  if (resultFileId) job.resultFileId = resultFileId;
  if (error) job.error = error;

  await redis.setex(`${JOB_PREFIX}${jobId}`, JOB_TTL, JSON.stringify(job));
};

// Обновить прогресс
export const updateJobProgress = async (jobId: string, progress: number): Promise<void> => {
  await updateJobStatus(jobId, 'processing', progress);
};
