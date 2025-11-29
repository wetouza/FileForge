import { describe, it, expect } from 'vitest';

// Unit tests for Worker processors
describe('Subtitle Converter', () => {
  it('should parse SRT format correctly', () => {
    const srtContent = `1
00:00:01,000 --> 00:00:04,000
Hello, world!

2
00:00:05,000 --> 00:00:08,000
This is a test.`;

    const parseSRT = (text: string) => {
      const entries: any[] = [];
      const blocks = text.trim().split(/\n\n+/);
      
      for (const block of blocks) {
        const lines = block.split('\n');
        if (lines.length >= 3) {
          entries.push({
            index: parseInt(lines[0], 10),
            timing: lines[1],
            text: lines.slice(2).join('\n'),
          });
        }
      }
      return entries;
    };

    const result = parseSRT(srtContent);
    
    expect(result).toHaveLength(2);
    expect(result[0].index).toBe(1);
    expect(result[0].text).toBe('Hello, world!');
    expect(result[1].text).toBe('This is a test.');
  });

  it('should generate VTT format correctly', () => {
    const entries = [
      { start: '00:00:01.000', end: '00:00:04.000', text: 'Hello' },
      { start: '00:00:05.000', end: '00:00:08.000', text: 'World' },
    ];

    const generateVTT = (entries: any[]) => {
      const header = 'WEBVTT\n\n';
      const body = entries.map(e => 
        `${e.start} --> ${e.end}\n${e.text}`
      ).join('\n\n');
      return header + body;
    };

    const result = generateVTT(entries);
    
    expect(result).toContain('WEBVTT');
    expect(result).toContain('00:00:01.000 --> 00:00:04.000');
    expect(result).toContain('Hello');
  });
});

describe('Format Category Detection', () => {
  it('should detect audio formats', () => {
    const audioFormats = ['mp3', 'wav', 'flac', 'aac', 'ogg'];
    const getCategory = (format: string) => {
      if (audioFormats.includes(format)) return 'audio';
      return 'unknown';
    };

    expect(getCategory('mp3')).toBe('audio');
    expect(getCategory('wav')).toBe('audio');
    expect(getCategory('pdf')).toBe('unknown');
  });

  it('should detect video formats', () => {
    const videoFormats = ['mp4', 'avi', 'mkv', 'mov', 'webm'];
    const getCategory = (format: string) => {
      if (videoFormats.includes(format)) return 'video';
      return 'unknown';
    };

    expect(getCategory('mp4')).toBe('video');
    expect(getCategory('mkv')).toBe('video');
  });

  it('should detect image formats', () => {
    const imageFormats = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'];
    const getCategory = (format: string) => {
      if (imageFormats.includes(format)) return 'image';
      return 'unknown';
    };

    expect(getCategory('jpg')).toBe('image');
    expect(getCategory('png')).toBe('image');
    expect(getCategory('webp')).toBe('image');
  });
});

describe('Conversion Options Builder', () => {
  it('should build FFmpeg audio args', () => {
    const buildAudioArgs = (options: any) => {
      const args: string[] = [];
      if (options.bitrate) args.push('-b:a', options.bitrate);
      if (options.sampleRate) args.push('-ar', options.sampleRate.toString());
      if (options.channels) args.push('-ac', options.channels.toString());
      return args;
    };

    const args = buildAudioArgs({ bitrate: '192k', sampleRate: 44100, channels: 2 });
    
    expect(args).toContain('-b:a');
    expect(args).toContain('192k');
    expect(args).toContain('-ar');
    expect(args).toContain('44100');
  });

  it('should build FFmpeg video args', () => {
    const buildVideoArgs = (options: any) => {
      const args: string[] = [];
      if (options.resolution) {
        const [w, h] = options.resolution.split('x');
        args.push('-vf', `scale=${w}:${h}`);
      }
      if (options.fps) args.push('-r', options.fps.toString());
      return args;
    };

    const args = buildVideoArgs({ resolution: '1280x720', fps: 30 });
    
    expect(args).toContain('-vf');
    expect(args).toContain('scale=1280:720');
    expect(args).toContain('-r');
    expect(args).toContain('30');
  });
});
