import { FormatInfo, FormatCategory } from '../types/index.js';

// Полный каталог поддерживаемых форматов
export const FORMATS: Record<string, FormatInfo> = {
  // Аудио
  mp3: { extension: 'mp3', mimeType: 'audio/mpeg', category: 'audio', name: 'MP3', convertibleTo: ['wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'] },
  wav: { extension: 'wav', mimeType: 'audio/wav', category: 'audio', name: 'WAV', convertibleTo: ['mp3', 'flac', 'aac', 'ogg', 'm4a'] },
  flac: { extension: 'flac', mimeType: 'audio/flac', category: 'audio', name: 'FLAC', convertibleTo: ['mp3', 'wav', 'aac', 'ogg', 'm4a'] },
  aac: { extension: 'aac', mimeType: 'audio/aac', category: 'audio', name: 'AAC', convertibleTo: ['mp3', 'wav', 'flac', 'ogg', 'm4a'] },
  ogg: { extension: 'ogg', mimeType: 'audio/ogg', category: 'audio', name: 'OGG', convertibleTo: ['mp3', 'wav', 'flac', 'aac', 'm4a'] },
  m4a: { extension: 'm4a', mimeType: 'audio/mp4', category: 'audio', name: 'M4A', convertibleTo: ['mp3', 'wav', 'flac', 'aac', 'ogg'] },
  wma: { extension: 'wma', mimeType: 'audio/x-ms-wma', category: 'audio', name: 'WMA', convertibleTo: ['mp3', 'wav', 'flac'] },

  // Видео
  mp4: { extension: 'mp4', mimeType: 'video/mp4', category: 'video', name: 'MP4', convertibleTo: ['avi', 'mkv', 'mov', 'webm', 'gif', 'mp3'] },
  avi: { extension: 'avi', mimeType: 'video/x-msvideo', category: 'video', name: 'AVI', convertibleTo: ['mp4', 'mkv', 'mov', 'webm', 'gif'] },
  mkv: { extension: 'mkv', mimeType: 'video/x-matroska', category: 'video', name: 'MKV', convertibleTo: ['mp4', 'avi', 'mov', 'webm', 'gif'] },
  mov: { extension: 'mov', mimeType: 'video/quicktime', category: 'video', name: 'MOV', convertibleTo: ['mp4', 'avi', 'mkv', 'webm', 'gif'] },
  webm: { extension: 'webm', mimeType: 'video/webm', category: 'video', name: 'WebM', convertibleTo: ['mp4', 'avi', 'mkv', 'mov', 'gif'] },
  flv: { extension: 'flv', mimeType: 'video/x-flv', category: 'video', name: 'FLV', convertibleTo: ['mp4', 'avi', 'mkv', 'webm'] },
  wmv: { extension: 'wmv', mimeType: 'video/x-ms-wmv', category: 'video', name: 'WMV', convertibleTo: ['mp4', 'avi', 'mkv', 'webm'] },

  // Изображения
  jpg: { extension: 'jpg', mimeType: 'image/jpeg', category: 'image', name: 'JPEG', convertibleTo: ['png', 'webp', 'gif', 'bmp', 'tiff', 'ico', 'pdf'] },
  jpeg: { extension: 'jpeg', mimeType: 'image/jpeg', category: 'image', name: 'JPEG', convertibleTo: ['png', 'webp', 'gif', 'bmp', 'tiff', 'ico', 'pdf'] },
  png: { extension: 'png', mimeType: 'image/png', category: 'image', name: 'PNG', convertibleTo: ['jpg', 'webp', 'gif', 'bmp', 'tiff', 'ico', 'pdf'] },
  webp: { extension: 'webp', mimeType: 'image/webp', category: 'image', name: 'WebP', convertibleTo: ['jpg', 'png', 'gif', 'bmp', 'tiff'] },
  gif: { extension: 'gif', mimeType: 'image/gif', category: 'image', name: 'GIF', convertibleTo: ['jpg', 'png', 'webp', 'mp4'] },
  bmp: { extension: 'bmp', mimeType: 'image/bmp', category: 'image', name: 'BMP', convertibleTo: ['jpg', 'png', 'webp', 'gif', 'tiff'] },
  tiff: { extension: 'tiff', mimeType: 'image/tiff', category: 'image', name: 'TIFF', convertibleTo: ['jpg', 'png', 'webp', 'bmp', 'pdf'] },
  svg: { extension: 'svg', mimeType: 'image/svg+xml', category: 'image', name: 'SVG', convertibleTo: ['png', 'jpg', 'pdf'] },
  ico: { extension: 'ico', mimeType: 'image/x-icon', category: 'image', name: 'ICO', convertibleTo: ['png', 'jpg'] },
  heic: { extension: 'heic', mimeType: 'image/heic', category: 'image', name: 'HEIC', convertibleTo: ['jpg', 'png', 'webp'] },

  // Документы
  pdf: { extension: 'pdf', mimeType: 'application/pdf', category: 'document', name: 'PDF', convertibleTo: ['docx', 'txt', 'jpg', 'png'] },
  docx: { extension: 'docx', mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', category: 'document', name: 'DOCX', convertibleTo: ['pdf', 'txt', 'odt', 'html', 'md'] },
  doc: { extension: 'doc', mimeType: 'application/msword', category: 'document', name: 'DOC', convertibleTo: ['pdf', 'docx', 'txt', 'odt'] },
  txt: { extension: 'txt', mimeType: 'text/plain', category: 'document', name: 'TXT', convertibleTo: ['pdf', 'docx', 'html', 'md'] },
  rtf: { extension: 'rtf', mimeType: 'application/rtf', category: 'document', name: 'RTF', convertibleTo: ['pdf', 'docx', 'txt'] },
  odt: { extension: 'odt', mimeType: 'application/vnd.oasis.opendocument.text', category: 'document', name: 'ODT', convertibleTo: ['pdf', 'docx', 'txt'] },
  html: { extension: 'html', mimeType: 'text/html', category: 'document', name: 'HTML', convertibleTo: ['pdf', 'txt', 'md'] },
  md: { extension: 'md', mimeType: 'text/markdown', category: 'document', name: 'Markdown', convertibleTo: ['pdf', 'html', 'docx', 'txt'] },
  epub: { extension: 'epub', mimeType: 'application/epub+zip', category: 'document', name: 'EPUB', convertibleTo: ['pdf', 'txt', 'html'] },

  // Архивы
  zip: { extension: 'zip', mimeType: 'application/zip', category: 'archive', name: 'ZIP', convertibleTo: ['tar', '7z'] },
  rar: { extension: 'rar', mimeType: 'application/vnd.rar', category: 'archive', name: 'RAR', convertibleTo: ['zip', 'tar', '7z'] },
  '7z': { extension: '7z', mimeType: 'application/x-7z-compressed', category: 'archive', name: '7Z', convertibleTo: ['zip', 'tar'] },
  tar: { extension: 'tar', mimeType: 'application/x-tar', category: 'archive', name: 'TAR', convertibleTo: ['zip', '7z', 'gz'] },
  gz: { extension: 'gz', mimeType: 'application/gzip', category: 'archive', name: 'GZ', convertibleTo: ['zip', 'tar'] },

  // Субтитры
  srt: { extension: 'srt', mimeType: 'application/x-subrip', category: 'subtitle', name: 'SRT', convertibleTo: ['vtt', 'ass'] },
  vtt: { extension: 'vtt', mimeType: 'text/vtt', category: 'subtitle', name: 'VTT', convertibleTo: ['srt', 'ass'] },
  ass: { extension: 'ass', mimeType: 'text/x-ass', category: 'subtitle', name: 'ASS', convertibleTo: ['srt', 'vtt'] },
  ssa: { extension: 'ssa', mimeType: 'text/x-ssa', category: 'subtitle', name: 'SSA', convertibleTo: ['srt', 'vtt', 'ass'] },

  // Шрифты
  ttf: { extension: 'ttf', mimeType: 'font/ttf', category: 'font', name: 'TTF', convertibleTo: ['woff', 'woff2', 'otf', 'eot'] },
  otf: { extension: 'otf', mimeType: 'font/otf', category: 'font', name: 'OTF', convertibleTo: ['ttf', 'woff', 'woff2'] },
  woff: { extension: 'woff', mimeType: 'font/woff', category: 'font', name: 'WOFF', convertibleTo: ['ttf', 'woff2'] },
  woff2: { extension: 'woff2', mimeType: 'font/woff2', category: 'font', name: 'WOFF2', convertibleTo: ['ttf', 'woff'] },
};

// Получить формат по расширению
export const getFormat = (extension: string): FormatInfo | undefined => {
  return FORMATS[extension.toLowerCase().replace('.', '')];
};

// Получить форматы по категории
export const getFormatsByCategory = (category: FormatCategory): FormatInfo[] => {
  return Object.values(FORMATS).filter(f => f.category === category);
};

// Проверить возможность конвертации
export const canConvert = (from: string, to: string): boolean => {
  const format = getFormat(from);
  return format?.convertibleTo.includes(to.toLowerCase()) ?? false;
};

// Получить все категории
export const getCategories = (): FormatCategory[] => {
  return ['audio', 'video', 'image', 'document', 'archive', 'subtitle', 'font'];
};
