import { spawn } from 'child_process';
import { writeFile, readFile, unlink, mkdtemp } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';
import { ConversionOptions } from '../types.js';
import { logger } from '../utils/logger.js';

// Конвертация аудио через FFmpeg
export const convertAudio = async (
  input: Buffer,
  sourceFormat: string,
  targetFormat: string,
  options?: ConversionOptions,
  onProgress?: (progress: number) => void
): Promise<Buffer> => {
  return runFFmpeg(input, sourceFormat, targetFormat, buildAudioArgs(targetFormat, options), onProgress);
};

// Конвертация видео через FFmpeg
export const convertVideo = async (
  input: Buffer,
  sourceFormat: string,
  targetFormat: string,
  options?: ConversionOptions,
  onProgress?: (progress: number) => void
): Promise<Buffer> => {
  return runFFmpeg(input, sourceFormat, targetFormat, buildVideoArgs(targetFormat, options), onProgress);
};

// Построение аргументов для аудио
const buildAudioArgs = (targetFormat: string, options?: ConversionOptions): string[] => {
  const args: string[] = [];
  
  if (options?.bitrate) args.push('-b:a', options.bitrate);
  if (options?.sampleRate) args.push('-ar', options.sampleRate.toString());
  if (options?.channels) args.push('-ac', options.channels.toString());
  
  // Кодеки по умолчанию
  const codecs: Record<string, string[]> = {
    mp3: ['-codec:a', 'libmp3lame'],
    aac: ['-codec:a', 'aac'],
    ogg: ['-codec:a', 'libvorbis'],
    flac: ['-codec:a', 'flac'],
    wav: ['-codec:a', 'pcm_s16le'],
  };
  
  if (codecs[targetFormat]) args.push(...codecs[targetFormat]);
  
  return args;
};

// Построение аргументов для видео
const buildVideoArgs = (targetFormat: string, options?: ConversionOptions): string[] => {
  const args: string[] = [];
  
  if (options?.resolution) {
    const [w, h] = options.resolution.split('x');
    args.push('-vf', `scale=${w}:${h}`);
  }
  if (options?.bitrate) args.push('-b:v', options.bitrate);
  if (options?.fps) args.push('-r', options.fps.toString());
  if (options?.codec) args.push('-codec:v', options.codec);
  
  // Кодеки по умолчанию
  const codecs: Record<string, string[]> = {
    mp4: ['-codec:v', 'libx264', '-codec:a', 'aac'],
    webm: ['-codec:v', 'libvpx-vp9', '-codec:a', 'libopus'],
    avi: ['-codec:v', 'mpeg4'],
    mkv: ['-codec:v', 'libx264', '-codec:a', 'aac'],
    gif: ['-vf', 'fps=10,scale=320:-1:flags=lanczos'],
  };
  
  if (codecs[targetFormat] && !options?.codec) args.push(...codecs[targetFormat]);
  
  return args;
};

// Запуск FFmpeg
const runFFmpeg = async (
  input: Buffer,
  sourceFormat: string,
  targetFormat: string,
  extraArgs: string[],
  onProgress?: (progress: number) => void
): Promise<Buffer> => {
  const tempDir = await mkdtemp(join(tmpdir(), 'ffmpeg-'));
  const inputPath = join(tempDir, `input.${sourceFormat}`);
  const outputPath = join(tempDir, `output.${targetFormat}`);

  try {
    await writeFile(inputPath, input);

    const args = [
      '-i', inputPath,
      '-y', // Перезаписать выходной файл
      ...extraArgs,
      outputPath,
    ];

    logger.debug(`FFmpeg args: ${args.join(' ')}`);

    await new Promise<void>((resolve, reject) => {
      const proc = spawn('ffmpeg', args);
      let progress = 0;

      proc.stderr.on('data', (data) => {
        const str = data.toString();
        // Парсинг прогресса из вывода FFmpeg
        const timeMatch = str.match(/time=(\d+):(\d+):(\d+)/);
        if (timeMatch && onProgress) {
          progress = Math.min(progress + 5, 100);
          onProgress(progress);
        }
      });

      proc.on('close', (code) => {
        if (code === 0) resolve();
        else reject(new Error(`FFmpeg exited with code ${code}`));
      });

      proc.on('error', reject);
    });

    return await readFile(outputPath);
  } finally {
    // Очистка временных файлов
    await unlink(inputPath).catch(() => {});
    await unlink(outputPath).catch(() => {});
  }
};
