import sharp from 'sharp';
import { ConversionOptions } from '../types.js';
import { logger } from '../utils/logger.js';

// Конвертация изображений через Sharp
export const convertImage = async (
  input: Buffer,
  sourceFormat: string,
  targetFormat: string,
  options?: ConversionOptions
): Promise<Buffer> => {
  logger.debug(`Converting image: ${sourceFormat} -> ${targetFormat}`);

  let pipeline = sharp(input);

  // Изменение размера
  if (options?.resolution) {
    const [width, height] = options.resolution.split('x').map(Number);
    pipeline = pipeline.resize(width, height, { fit: 'inside' });
  }

  // Качество
  const quality = options?.quality || 85;

  // Конвертация в целевой формат
  switch (targetFormat.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return pipeline.jpeg({ quality }).toBuffer();
    
    case 'png':
      return pipeline.png({ compressionLevel: Math.floor((100 - quality) / 10) }).toBuffer();
    
    case 'webp':
      return pipeline.webp({ quality }).toBuffer();
    
    case 'gif':
      return pipeline.gif().toBuffer();
    
    case 'bmp':
      return pipeline.raw().toBuffer();
    
    case 'tiff':
      return pipeline.tiff({ quality }).toBuffer();
    
    case 'avif':
      return pipeline.avif({ quality }).toBuffer();
    
    case 'ico':
      // ICO требует специальной обработки - конвертируем в PNG 256x256
      return pipeline.resize(256, 256, { fit: 'contain' }).png().toBuffer();
    
    default:
      throw new Error(`Unsupported image format: ${targetFormat}`);
  }
};
