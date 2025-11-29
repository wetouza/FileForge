import { Router } from 'express';
import multer from 'multer';
import { uploadToS3 } from '../services/storage.js';
import { getFormat } from '../services/formats.js';
import { AppError } from '../middleware/errorHandler.js';
import { config } from '../config/index.js';
import { logger } from '../utils/logger.js';

export const uploadRouter = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: config.upload.maxFileSize },
});

// POST /api/upload - загрузка файла
uploadRouter.post('/', upload.single('file'), async (req, res, next) => {
  try {
    const file = req.file;
    if (!file) {
      throw new AppError(400, 'No file provided');
    }

    const ext = file.originalname.split('.').pop()?.toLowerCase() || '';
    const format = getFormat(ext);
    
    if (!format) {
      throw new AppError(400, `Unsupported format: ${ext}`);
    }

    const { key, id } = await uploadToS3(file.buffer, file.originalname, file.mimetype);

    logger.info(`File uploaded: ${id} (${file.originalname})`);

    res.json({
      success: true,
      data: {
        fileId: id,
        fileName: file.originalname,
        format: format.extension,
        category: format.category,
        size: file.size,
        convertibleTo: format.convertibleTo,
        s3Key: key,
      },
    });
  } catch (error) {
    next(error);
  }
});
