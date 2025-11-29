// Данные задачи конвертации
export interface ConversionJobData {
  jobId: string;
  sourceKey: string;
  sourceFormat: string;
  targetFormat: string;
  options?: ConversionOptions;
}

// Опции конвертации
export interface ConversionOptions {
  quality?: number;
  resolution?: string;
  bitrate?: string;
  codec?: string;
  fps?: number;
  sampleRate?: number;
  channels?: number;
  compression?: number;
}

// Результат конвертации
export interface ConversionResult {
  resultKey: string;
  size: number;
  duration?: number;
}

// Категория формата
export type FormatCategory = 'audio' | 'video' | 'image' | 'document' | 'archive' | 'subtitle' | 'font';

// Маппинг форматов к категориям
export const FORMAT_CATEGORIES: Record<string, FormatCategory> = {
  // Аудио
  mp3: 'audio', wav: 'audio', flac: 'audio', aac: 'audio', ogg: 'audio', m4a: 'audio', wma: 'audio',
  // Видео
  mp4: 'video', avi: 'video', mkv: 'video', mov: 'video', webm: 'video', flv: 'video', wmv: 'video',
  // Изображения
  jpg: 'image', jpeg: 'image', png: 'image', webp: 'image', gif: 'image', bmp: 'image', tiff: 'image', svg: 'image', ico: 'image', heic: 'image',
  // Документы
  pdf: 'document', docx: 'document', doc: 'document', txt: 'document', rtf: 'document', odt: 'document', html: 'document', md: 'document', epub: 'document',
  // Архивы
  zip: 'archive', rar: 'archive', '7z': 'archive', tar: 'archive', gz: 'archive',
  // Субтитры
  srt: 'subtitle', vtt: 'subtitle', ass: 'subtitle', ssa: 'subtitle',
  // Шрифты
  ttf: 'font', otf: 'font', woff: 'font', woff2: 'font',
};

export const getCategory = (format: string): FormatCategory | undefined => {
  return FORMAT_CATEGORIES[format.toLowerCase()];
};
