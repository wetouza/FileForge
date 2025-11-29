// Категории форматов
export type FormatCategory = 'audio' | 'video' | 'image' | 'document' | 'archive' | 'subtitle' | 'font';

// Информация о формате
export interface FormatInfo {
  extension: string;
  mimeType: string;
  category: FormatCategory;
  name: string;
  convertibleTo: string[];
}

// Статус задачи конвертации
export type JobStatus = 'pending' | 'processing' | 'completed' | 'failed';

// Задача конвертации
export interface ConversionJob {
  id: string;
  sourceFileId: string;
  sourceFormat: string;
  targetFormat: string;
  status: JobStatus;
  progress: number;
  createdAt: Date;
  updatedAt: Date;
  resultFileId?: string;
  error?: string;
  options?: ConversionOptions;
}

// Опции конвертации
export interface ConversionOptions {
  quality?: number;        // 1-100
  resolution?: string;     // "1920x1080"
  bitrate?: string;        // "128k"
  codec?: string;
  fps?: number;
  sampleRate?: number;
  channels?: number;
  compression?: number;
}

// Загруженный файл
export interface UploadedFile {
  id: string;
  originalName: string;
  mimeType: string;
  size: number;
  s3Key: string;
  createdAt: Date;
  expiresAt: Date;
}

// WebSocket сообщения
export interface WsMessage {
  type: 'subscribe' | 'unsubscribe' | 'progress' | 'completed' | 'error';
  jobId?: string;
  data?: unknown;
}

// API ответы
export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}
