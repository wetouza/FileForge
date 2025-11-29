import { Job } from 'bullmq';
import { ConversionJobData, ConversionResult, getCategory } from '../types.js';
import { downloadFile, uploadFile } from '../utils/storage.js';
import { logger } from '../utils/logger.js';
import { convertAudio, convertVideo } from './ffmpeg.js';
import { convertImage } from './image.js';
import { convertDocument } from './document.js';
import { convertArchive } from './archive.js';
import { convertSubtitle } from './subtitle.js';

// MIME типы для результатов
const MIME_TYPES: Record<string, string> = {
  mp3: 'audio/mpeg', wav: 'audio/wav', flac: 'audio/flac', aac: 'audio/aac', ogg: 'audio/ogg', m4a: 'audio/mp4',
  mp4: 'video/mp4', avi: 'video/x-msvideo', mkv: 'video/x-matroska', mov: 'video/quicktime', webm: 'video/webm',
  jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', webp: 'image/webp', gif: 'image/gif', bmp: 'image/bmp', tiff: 'image/tiff',
  pdf: 'application/pdf', docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', txt: 'text/plain', html: 'text/html',
  zip: 'application/zip', tar: 'application/x-tar', '7z': 'application/x-7z-compressed',
  srt: 'application/x-subrip', vtt: 'text/vtt', ass: 'text/x-ass',
};

// Главный процессор конвертации
export const processConversion = async (job: Job<ConversionJobData>): Promise<ConversionResult> => {
  const { jobId, sourceKey, sourceFormat, targetFormat, options } = job.data;

  // Скачиваем исходный файл
  logger.info(`Downloading source file: ${sourceKey}`);
  await job.updateProgress(10);
  const sourceBuffer = await downloadFile(sourceKey);

  // Определяем категорию и выбираем конвертер
  const category = getCategory(sourceFormat);
  logger.info(`Converting ${category}: ${sourceFormat} -> ${targetFormat}`);
  await job.updateProgress(20);

  let resultBuffer: Buffer;

  switch (category) {
    case 'audio':
      resultBuffer = await convertAudio(sourceBuffer, sourceFormat, targetFormat, options, (p) => job.updateProgress(20 + p * 0.6));
      break;
    case 'video':
      resultBuffer = await convertVideo(sourceBuffer, sourceFormat, targetFormat, options, (p) => job.updateProgress(20 + p * 0.6));
      break;
    case 'image':
      resultBuffer = await convertImage(sourceBuffer, sourceFormat, targetFormat, options);
      await job.updateProgress(80);
      break;
    case 'document':
      resultBuffer = await convertDocument(sourceBuffer, sourceFormat, targetFormat, options);
      await job.updateProgress(80);
      break;
    case 'archive':
      resultBuffer = await convertArchive(sourceBuffer, sourceFormat, targetFormat);
      await job.updateProgress(80);
      break;
    case 'subtitle':
      resultBuffer = await convertSubtitle(sourceBuffer, sourceFormat, targetFormat);
      await job.updateProgress(80);
      break;
    default:
      throw new Error(`Unsupported format category: ${category}`);
  }

  // Загружаем результат
  const resultKey = `results/${jobId}.${targetFormat}`;
  const mimeType = MIME_TYPES[targetFormat] || 'application/octet-stream';
  
  logger.info(`Uploading result: ${resultKey}`);
  await uploadFile(resultKey, resultBuffer, mimeType);
  await job.updateProgress(100);

  return {
    resultKey,
    size: resultBuffer.length,
  };
};
