import archiver from 'archiver';
import extractZip from 'extract-zip';
import { writeFile, readFile, readdir, unlink, mkdtemp, rm } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';
import { createWriteStream } from 'fs';
import { logger } from '../utils/logger.js';

// Конвертация архивов
export const convertArchive = async (
  input: Buffer,
  sourceFormat: string,
  targetFormat: string
): Promise<Buffer> => {
  logger.debug(`Converting archive: ${sourceFormat} -> ${targetFormat}`);

  const tempDir = await mkdtemp(join(tmpdir(), 'archive-'));
  const extractDir = join(tempDir, 'extracted');
  const inputPath = join(tempDir, `input.${sourceFormat}`);
  const outputPath = join(tempDir, `output.${targetFormat}`);

  try {
    await writeFile(inputPath, input);

    // Распаковка
    if (sourceFormat === 'zip') {
      await extractZip(inputPath, { dir: extractDir });
    } else {
      throw new Error(`Extraction not supported for: ${sourceFormat}`);
    }

    // Создание нового архива
    await createArchive(extractDir, outputPath, targetFormat);

    return await readFile(outputPath);
  } finally {
    await rm(tempDir, { recursive: true, force: true }).catch(() => {});
  }
};

// Создание архива
const createArchive = async (sourceDir: string, outputPath: string, format: string): Promise<void> => {
  return new Promise((resolve, reject) => {
    const output = createWriteStream(outputPath);
    
    let archive: archiver.Archiver;
    
    switch (format) {
      case 'zip':
        archive = archiver('zip', { zlib: { level: 9 } });
        break;
      case 'tar':
        archive = archiver('tar');
        break;
      case 'gz':
        archive = archiver('tar', { gzip: true });
        break;
      default:
        reject(new Error(`Unsupported archive format: ${format}`));
        return;
    }

    output.on('close', resolve);
    archive.on('error', reject);

    archive.pipe(output);
    archive.directory(sourceDir, false);
    archive.finalize();
  });
};
