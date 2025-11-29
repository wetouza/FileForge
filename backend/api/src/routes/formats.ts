import { Router } from 'express';
import { FORMATS, getFormatsByCategory, getCategories } from '../services/formats.js';

export const formatsRouter = Router();

// GET /api/formats - все форматы
formatsRouter.get('/', (_req, res) => {
  res.json({
    success: true,
    data: {
      formats: FORMATS,
      categories: getCategories(),
    },
  });
});

// GET /api/formats/:category - форматы по категории
formatsRouter.get('/:category', (req, res) => {
  const { category } = req.params;
  const formats = getFormatsByCategory(category as any);

  res.json({
    success: true,
    data: { formats },
  });
});
