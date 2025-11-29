import { logger } from '../utils/logger.js';

// Конвертация субтитров
export const convertSubtitle = async (
  input: Buffer,
  sourceFormat: string,
  targetFormat: string
): Promise<Buffer> => {
  logger.debug(`Converting subtitle: ${sourceFormat} -> ${targetFormat}`);

  const text = input.toString('utf-8');

  // Парсинг исходного формата
  const entries = parseSubtitle(text, sourceFormat);

  // Генерация целевого формата
  const result = generateSubtitle(entries, targetFormat);

  return Buffer.from(result, 'utf-8');
};

interface SubtitleEntry {
  index: number;
  start: string;
  end: string;
  text: string;
}

// Парсинг субтитров
const parseSubtitle = (text: string, format: string): SubtitleEntry[] => {
  switch (format) {
    case 'srt':
      return parseSRT(text);
    case 'vtt':
      return parseVTT(text);
    case 'ass':
    case 'ssa':
      return parseASS(text);
    default:
      throw new Error(`Unsupported subtitle format: ${format}`);
  }
};

// Генерация субтитров
const generateSubtitle = (entries: SubtitleEntry[], format: string): string => {
  switch (format) {
    case 'srt':
      return generateSRT(entries);
    case 'vtt':
      return generateVTT(entries);
    case 'ass':
      return generateASS(entries);
    default:
      throw new Error(`Unsupported subtitle format: ${format}`);
  }
};

// SRT парсер
const parseSRT = (text: string): SubtitleEntry[] => {
  const entries: SubtitleEntry[] = [];
  const blocks = text.trim().split(/\n\n+/);

  for (const block of blocks) {
    const lines = block.split('\n');
    if (lines.length >= 3) {
      const index = parseInt(lines[0], 10);
      const [start, end] = lines[1].split(' --> ');
      const textContent = lines.slice(2).join('\n');
      entries.push({ index, start: start.trim(), end: end.trim(), text: textContent });
    }
  }

  return entries;
};

// VTT парсер
const parseVTT = (text: string): SubtitleEntry[] => {
  const entries: SubtitleEntry[] = [];
  const lines = text.split('\n');
  let index = 0;

  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('-->')) {
      const [start, end] = lines[i].split('-->');
      const textLines: string[] = [];
      i++;
      while (i < lines.length && lines[i].trim() !== '') {
        textLines.push(lines[i]);
        i++;
      }
      entries.push({
        index: ++index,
        start: start.trim(),
        end: end.trim(),
        text: textLines.join('\n'),
      });
    }
  }

  return entries;
};

// ASS/SSA парсер (упрощённый)
const parseASS = (text: string): SubtitleEntry[] => {
  const entries: SubtitleEntry[] = [];
  const lines = text.split('\n');
  let index = 0;

  for (const line of lines) {
    if (line.startsWith('Dialogue:')) {
      const parts = line.substring(10).split(',');
      if (parts.length >= 10) {
        entries.push({
          index: ++index,
          start: parts[1].trim(),
          end: parts[2].trim(),
          text: parts.slice(9).join(',').replace(/\\N/g, '\n'),
        });
      }
    }
  }

  return entries;
};

// SRT генератор
const generateSRT = (entries: SubtitleEntry[]): string => {
  return entries.map((e, i) => 
    `${i + 1}\n${e.start} --> ${e.end}\n${e.text}`
  ).join('\n\n');
};

// VTT генератор
const generateVTT = (entries: SubtitleEntry[]): string => {
  const header = 'WEBVTT\n\n';
  const body = entries.map(e => 
    `${e.start} --> ${e.end}\n${e.text}`
  ).join('\n\n');
  return header + body;
};

// ASS генератор
const generateASS = (entries: SubtitleEntry[]): string => {
  const header = `[Script Info]
Title: Converted Subtitles
ScriptType: v4.00+

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,20,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,2,2,10,10,10,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
`;

  const dialogues = entries.map(e => 
    `Dialogue: 0,${e.start},${e.end},Default,,0,0,0,,${e.text.replace(/\n/g, '\\N')}`
  ).join('\n');

  return header + dialogues;
};
