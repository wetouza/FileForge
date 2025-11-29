import { spawn } from 'child_process';
import { writeFile, readFile, unlink, mkdtemp } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';
import { ConversionOptions } from '../types.js';
import { logger } from '../utils/logger.js';

// Конвертация документов через LibreOffice/Pandoc
export const convertDocument = async (
  input: Buffer,
  sourceFormat: string,
  targetFormat: string,
  _options?: ConversionOptions
): Promise<Buffer> => {
  logger.debug(`Converting document: ${sourceFormat} -> ${targetFormat}`);

  // Простые текстовые конвертации
  if (isTextFormat(sourceFormat) && isTextFormat(targetFormat)) {
    return convertText(input, sourceFormat, targetFormat);
  }

  // Markdown конвертации через Pandoc
  if (sourceFormat === 'md' || targetFormat === 'md') {
    return convertWithPandoc(input, sourceFormat, targetFormat);
  }

  // Office документы через LibreOffice
  return convertWithLibreOffice(input, sourceFormat, targetFormat);
};

const isTextFormat = (format: string): boolean => {
  return ['txt', 'md', 'html'].includes(format);
};

// Простая текстовая конвертация
const convertText = async (input: Buffer, source: string, target: string): Promise<Buffer> => {
  const text = input.toString('utf-8');

  if (source === 'md' && target === 'html') {
    // Простой Markdown -> HTML
    const html = `<!DOCTYPE html><html><head><meta charset="utf-8"></head><body>${simpleMarkdownToHtml(text)}</body></html>`;
    return Buffer.from(html, 'utf-8');
  }

  if (source === 'html' && target === 'txt') {
    // HTML -> TXT (удаляем теги)
    const plainText = text.replace(/<[^>]*>/g, '');
    return Buffer.from(plainText, 'utf-8');
  }

  return input;
};

// Простой Markdown парсер
const simpleMarkdownToHtml = (md: string): string => {
  return md
    .replace(/^### (.*$)/gm, '<h3>$1</h3>')
    .replace(/^## (.*$)/gm, '<h2>$1</h2>')
    .replace(/^# (.*$)/gm, '<h1>$1</h1>')
    .replace(/\*\*(.*)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*)\*/g, '<em>$1</em>')
    .replace(/\n/g, '<br>');
};

// Конвертация через Pandoc
const convertWithPandoc = async (input: Buffer, source: string, target: string): Promise<Buffer> => {
  const tempDir = await mkdtemp(join(tmpdir(), 'pandoc-'));
  const inputPath = join(tempDir, `input.${source}`);
  const outputPath = join(tempDir, `output.${target}`);

  try {
    await writeFile(inputPath, input);

    await new Promise<void>((resolve, reject) => {
      const proc = spawn('pandoc', [inputPath, '-o', outputPath]);
      proc.on('close', (code) => code === 0 ? resolve() : reject(new Error(`Pandoc exited with code ${code}`)));
      proc.on('error', reject);
    });

    return await readFile(outputPath);
  } finally {
    await unlink(inputPath).catch(() => {});
    await unlink(outputPath).catch(() => {});
  }
};

// Конвертация через LibreOffice
const convertWithLibreOffice = async (input: Buffer, source: string, target: string): Promise<Buffer> => {
  const tempDir = await mkdtemp(join(tmpdir(), 'libreoffice-'));
  const inputPath = join(tempDir, `input.${source}`);

  try {
    await writeFile(inputPath, input);

    const filterMap: Record<string, string> = {
      pdf: 'pdf',
      docx: 'docx',
      odt: 'odt',
      txt: 'txt',
      html: 'html',
    };

    await new Promise<void>((resolve, reject) => {
      const proc = spawn('libreoffice', [
        '--headless',
        '--convert-to', filterMap[target] || target,
        '--outdir', tempDir,
        inputPath,
      ]);
      proc.on('close', (code) => code === 0 ? resolve() : reject(new Error(`LibreOffice exited with code ${code}`)));
      proc.on('error', reject);
    });

    const outputPath = join(tempDir, `input.${target}`);
    return await readFile(outputPath);
  } finally {
    await unlink(inputPath).catch(() => {});
  }
};
