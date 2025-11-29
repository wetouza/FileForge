/**
 * FileForge API Server - Real File Conversion
 * Supports: Images (sharp), Audio/Video (ffmpeg), Documents (pdf-lib, mammoth)
 */
import express from 'express';
import cors from 'cors';
import multer from 'multer';
import { v4 as uuid } from 'uuid';
import { writeFile, readFile, mkdir, unlink, copyFile } from 'fs/promises';
import { join, extname } from 'path';
import { existsSync, createReadStream, createWriteStream } from 'fs';
import sharp from 'sharp';
import ffmpeg from 'fluent-ffmpeg';

// Try to use @ffmpeg-installer/ffmpeg, fallback to system ffmpeg
try {
  const ffmpegInstaller = require('@ffmpeg-installer/ffmpeg');
  ffmpeg.setFfmpegPath(ffmpegInstaller.path);
  console.log('📦 FFmpeg path (npm):', ffmpegInstaller.path);
} catch {
  console.log('📦 FFmpeg path: system (Docker/installed)');
}

const app = express();
const PORT = process.env.PORT || 3000;

// In-memory storage for jobs
const jobs = new Map<string, any>();
const files = new Map<string, any>();

// Temp directory
const TEMP_DIR = join(process.cwd(), 'temp');
const UPLOADS_DIR = join(TEMP_DIR, 'uploads');
const RESULTS_DIR = join(TEMP_DIR, 'results');

// Ensure directories exist
async function ensureDirs() {
  for (const dir of [TEMP_DIR, UPLOADS_DIR, RESULTS_DIR]) {
    if (!existsSync(dir)) {
      await mkdir(dir, { recursive: true });
    }
  }
}
ensureDirs();

// Middleware
app.use(cors());
app.use(express.json());

const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 100 * 1024 * 1024 } // 100MB
});

// Formats catalog with conversion support
const FORMATS: Record<string, any> = {
  // Images - supported by sharp
  jpg: { extension: 'jpg', category: 'image', name: 'JPEG', convertibleTo: ['png', 'webp', 'gif', 'avif', 'tiff'] },
  jpeg: { extension: 'jpeg', category: 'image', name: 'JPEG', convertibleTo: ['png', 'webp', 'gif', 'avif', 'tiff'] },
  png: { extension: 'png', category: 'image', name: 'PNG', convertibleTo: ['jpg', 'webp', 'gif', 'avif', 'tiff'] },
  webp: { extension: 'webp', category: 'image', name: 'WebP', convertibleTo: ['jpg', 'png', 'gif', 'avif'] },
  gif: { extension: 'gif', category: 'image', name: 'GIF', convertibleTo: ['jpg', 'png', 'webp'] },
  avif: { extension: 'avif', category: 'image', name: 'AVIF', convertibleTo: ['jpg', 'png', 'webp'] },
  tiff: { extension: 'tiff', category: 'image', name: 'TIFF', convertibleTo: ['jpg', 'png', 'webp'] },
  bmp: { extension: 'bmp', category: 'image', name: 'BMP', convertibleTo: ['jpg', 'png', 'webp'] },
  
  // Audio - requires ffmpeg
  mp3: { extension: 'mp3', category: 'audio', name: 'MP3', convertibleTo: ['wav', 'ogg', 'flac', 'aac'] },
  wav: { extension: 'wav', category: 'audio', name: 'WAV', convertibleTo: ['mp3', 'ogg', 'flac', 'aac'] },
  ogg: { extension: 'ogg', category: 'audio', name: 'OGG', convertibleTo: ['mp3', 'wav', 'flac'] },
  flac: { extension: 'flac', category: 'audio', name: 'FLAC', convertibleTo: ['mp3', 'wav', 'ogg'] },
  aac: { extension: 'aac', category: 'audio', name: 'AAC', convertibleTo: ['mp3', 'wav', 'ogg'] },
  
  // Video - requires ffmpeg
  mp4: { extension: 'mp4', category: 'video', name: 'MP4', convertibleTo: ['avi', 'mkv', 'webm', 'mov', 'gif'] },
  avi: { extension: 'avi', category: 'video', name: 'AVI', convertibleTo: ['mp4', 'mkv', 'webm'] },
  mkv: { extension: 'mkv', category: 'video', name: 'MKV', convertibleTo: ['mp4', 'avi', 'webm'] },
  webm: { extension: 'webm', category: 'video', name: 'WebM', convertibleTo: ['mp4', 'avi', 'mkv'] },
  mov: { extension: 'mov', category: 'video', name: 'MOV', convertibleTo: ['mp4', 'avi', 'webm'] },
  
  // Documents
  pdf: { extension: 'pdf', category: 'document', name: 'PDF', convertibleTo: ['txt'] },
  txt: { extension: 'txt', category: 'document', name: 'TXT', convertibleTo: ['pdf'] },
  docx: { extension: 'docx', category: 'document', name: 'DOCX', convertibleTo: ['txt', 'pdf'] },
};

// Health check
app.get('/health', (_, res) => {
  res.json({ status: 'ok', mode: 'standalone', timestamp: new Date().toISOString() });
});

// Get formats
app.get('/api/formats', (_, res) => {
  res.json({
    success: true,
    data: {
      formats: FORMATS,
      categories: ['audio', 'video', 'image', 'document'],
    },
  });
});

// Upload file
app.post('/api/upload', upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ success: false, error: 'No file provided' });
    }

    const ext = file.originalname.split('.').pop()?.toLowerCase() || '';
    const format = FORMATS[ext];
    
    if (!format) {
      return res.status(400).json({ success: false, error: `Unsupported format: ${ext}` });
    }

    const fileId = uuid();
    const filePath = join(UPLOADS_DIR, `${fileId}.${ext}`);
    
    await writeFile(filePath, file.buffer);
    
    files.set(fileId, {
      id: fileId,
      originalName: file.originalname,
      path: filePath,
      format: ext,
      size: file.size,
      category: format.category,
    });

    console.log(`📁 File uploaded: ${file.originalname} (${fileId})`);

    res.json({
      success: true,
      data: {
        fileId,
        fileName: file.originalname,
        format: ext,
        category: format.category,
        size: file.size,
        convertibleTo: format.convertibleTo,
      },
    });
  } catch (error: any) {
    console.error('Upload error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Start conversion
app.post('/api/convert', async (req, res) => {
  try {
    const { fileId, targetFormat } = req.body;
    
    const fileInfo = files.get(fileId);
    if (!fileInfo) {
      return res.status(404).json({ success: false, error: 'File not found' });
    }

    const sourceFormat = fileInfo.format;
    const formatInfo = FORMATS[sourceFormat];
    
    if (!formatInfo?.convertibleTo?.includes(targetFormat)) {
      return res.status(400).json({ 
        success: false, 
        error: `Cannot convert ${sourceFormat} to ${targetFormat}` 
      });
    }

    const jobId = uuid();
    const job = {
      id: jobId,
      fileId,
      sourceFormat,
      targetFormat,
      status: 'processing',
      progress: 0,
      createdAt: new Date(),
      category: fileInfo.category,
    };
    
    jobs.set(jobId, job);

    console.log(`🔄 Conversion started: ${jobId} (${sourceFormat} -> ${targetFormat})`);

    // Start real conversion
    performConversion(jobId, fileInfo, targetFormat);

    res.json({
      success: true,
      data: {
        jobId,
        status: 'processing',
        sourceFormat,
        targetFormat,
      },
    });
  } catch (error: any) {
    console.error('Convert error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get job status
app.get('/api/status/:jobId', (req, res) => {
  const { jobId } = req.params;
  const job = jobs.get(jobId);

  if (!job) {
    return res.status(404).json({ success: false, error: 'Job not found' });
  }

  res.json({
    success: true,
    data: {
      jobId: job.id,
      status: job.status,
      progress: job.progress,
      sourceFormat: job.sourceFormat,
      targetFormat: job.targetFormat,
      downloadUrl: job.status === 'completed' ? `/api/download/${jobId}` : undefined,
      resultFileName: job.resultFileName,
      resultSize: job.resultSize,
      error: job.error,
    },
  });
});

// Download result
app.get('/api/download/:jobId', async (req, res) => {
  const { jobId } = req.params;
  const job = jobs.get(jobId);

  if (!job || job.status !== 'completed') {
    return res.status(404).json({ success: false, error: 'File not ready' });
  }

  try {
    const buffer = await readFile(job.resultPath);
    const fileName = job.resultFileName || `converted.${job.targetFormat}`;
    
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    res.setHeader('Content-Length', buffer.length);
    res.send(buffer);
  } catch (error) {
    res.status(500).json({ success: false, error: 'File not found' });
  }
});


// Real conversion logic
async function performConversion(jobId: string, fileInfo: any, targetFormat: string) {
  const job = jobs.get(jobId);
  if (!job) return;

  try {
    const resultPath = join(RESULTS_DIR, `${jobId}.${targetFormat}`);
    const originalName = fileInfo.originalName.replace(/\.[^/.]+$/, '');
    
    job.progress = 10;
    console.log(`  ⏳ Job ${jobId}: Starting conversion...`);

    // Route to appropriate converter based on category
    switch (fileInfo.category) {
      case 'image':
        await convertImage(fileInfo.path, resultPath, targetFormat, job);
        break;
      case 'audio':
      case 'video':
        await convertMedia(fileInfo.path, resultPath, targetFormat, job);
        break;
      case 'document':
        await convertDocument(fileInfo.path, resultPath, fileInfo.format, targetFormat, job);
        break;
      default:
        throw new Error(`Unsupported category: ${fileInfo.category}`);
    }

    // Get result file size
    const resultBuffer = await readFile(resultPath);
    
    job.progress = 100;
    job.status = 'completed';
    job.resultPath = resultPath;
    job.resultFileName = `${originalName}.${targetFormat}`;
    job.resultSize = resultBuffer.length;
    
    console.log(`✅ Job ${jobId} completed! Output: ${job.resultFileName} (${formatBytes(job.resultSize)})`);
  } catch (error: any) {
    console.error(`❌ Job ${jobId} failed:`, error.message);
    job.status = 'failed';
    job.error = error.message;
  }
}

// Image conversion using sharp
async function convertImage(inputPath: string, outputPath: string, targetFormat: string, job: any) {
  job.progress = 30;
  
  let image = sharp(inputPath);
  
  // Get image metadata for logging
  const metadata = await image.metadata();
  console.log(`  📷 Image: ${metadata.width}x${metadata.height}, ${metadata.format}`);
  
  job.progress = 50;
  
  // Convert based on target format
  switch (targetFormat) {
    case 'jpg':
    case 'jpeg':
      image = image.jpeg({ quality: 90 });
      break;
    case 'png':
      image = image.png({ compressionLevel: 6 });
      break;
    case 'webp':
      image = image.webp({ quality: 85 });
      break;
    case 'gif':
      image = image.gif();
      break;
    case 'avif':
      image = image.avif({ quality: 80 });
      break;
    case 'tiff':
      image = image.tiff({ compression: 'lzw' });
      break;
    default:
      throw new Error(`Unsupported image format: ${targetFormat}`);
  }
  
  job.progress = 80;
  await image.toFile(outputPath);
  job.progress = 95;
}

// Media conversion using fluent-ffmpeg (audio/video)
async function convertMedia(inputPath: string, outputPath: string, targetFormat: string, job: any) {
  return new Promise<void>((resolve, reject) => {
    job.progress = 20;
    
    let command = ffmpeg(inputPath);
    
    // Format-specific options
    switch (targetFormat) {
      case 'mp3':
        command = command.audioCodec('libmp3lame').audioQuality(2);
        break;
      case 'wav':
        command = command.audioCodec('pcm_s16le');
        break;
      case 'ogg':
        command = command.audioCodec('libvorbis').audioQuality(5);
        break;
      case 'flac':
        command = command.audioCodec('flac');
        break;
      case 'aac':
        command = command.audioCodec('aac').audioBitrate('192k');
        break;
      case 'mp4':
        command = command.videoCodec('libx264').addOptions(['-preset', 'fast', '-crf', '23']).audioCodec('aac');
        break;
      case 'avi':
        command = command.videoCodec('mpeg4').addOptions(['-qscale:v', '5']).audioCodec('libmp3lame');
        break;
      case 'mkv':
        command = command.videoCodec('libx264').addOptions(['-preset', 'fast']).audioCodec('aac');
        break;
      case 'webm':
        command = command.videoCodec('libvpx-vp9').addOptions(['-crf', '30', '-b:v', '0']).audioCodec('libopus');
        break;
      case 'mov':
        command = command.videoCodec('libx264').audioCodec('aac');
        break;
      case 'gif':
        command = command.addOptions(['-vf', 'fps=10,scale=480:-1:flags=lanczos', '-loop', '0']);
        break;
    }
    
    console.log(`  🎬 Converting to ${targetFormat}...`);
    
    command
      .on('progress', (progress) => {
        if (progress.percent) {
          job.progress = Math.min(95, 20 + Math.floor(progress.percent * 0.75));
          console.log(`  ⏳ Progress: ${Math.floor(progress.percent)}%`);
        }
      })
      .on('end', () => {
        job.progress = 95;
        resolve();
      })
      .on('error', (err) => {
        reject(new Error(`FFmpeg error: ${err.message}`));
      })
      .save(outputPath);
  });
}

// Document conversion
async function convertDocument(inputPath: string, outputPath: string, sourceFormat: string, targetFormat: string, job: any) {
  job.progress = 30;
  
  if (sourceFormat === 'txt' && targetFormat === 'pdf') {
    // TXT to PDF using pdf-lib
    const { PDFDocument, StandardFonts, rgb } = await import('pdf-lib');
    
    const text = await readFile(inputPath, 'utf-8');
    const pdfDoc = await PDFDocument.create();
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
    
    job.progress = 50;
    
    const lines = text.split('\n');
    const fontSize = 12;
    const margin = 50;
    const lineHeight = fontSize * 1.2;
    const pageHeight = 842; // A4
    const pageWidth = 595;
    const linesPerPage = Math.floor((pageHeight - 2 * margin) / lineHeight);
    
    for (let i = 0; i < lines.length; i += linesPerPage) {
      const page = pdfDoc.addPage([pageWidth, pageHeight]);
      const pageLines = lines.slice(i, i + linesPerPage);
      
      pageLines.forEach((line, index) => {
        page.drawText(line.substring(0, 80), {
          x: margin,
          y: pageHeight - margin - (index * lineHeight),
          size: fontSize,
          font,
          color: rgb(0, 0, 0),
        });
      });
    }
    
    job.progress = 80;
    const pdfBytes = await pdfDoc.save();
    await writeFile(outputPath, pdfBytes);
    
  } else if (sourceFormat === 'pdf' && targetFormat === 'txt') {
    // PDF to TXT - basic extraction
    // Note: For production, use pdf-parse or similar
    job.progress = 50;
    const pdfBuffer = await readFile(inputPath);
    
    // Simple text extraction (basic implementation)
    const text = extractTextFromPDF(pdfBuffer);
    await writeFile(outputPath, text);
    
  } else if (sourceFormat === 'docx' && targetFormat === 'txt') {
    // DOCX to TXT using mammoth
    const mammoth = await import('mammoth');
    const result = await mammoth.extractRawText({ path: inputPath });
    job.progress = 70;
    await writeFile(outputPath, result.value);
    
  } else if (sourceFormat === 'docx' && targetFormat === 'pdf') {
    // DOCX to PDF - first extract text, then create PDF
    const mammoth = await import('mammoth');
    const { PDFDocument, StandardFonts, rgb } = await import('pdf-lib');
    
    job.progress = 40;
    const result = await mammoth.extractRawText({ path: inputPath });
    const text = result.value;
    
    job.progress = 60;
    const pdfDoc = await PDFDocument.create();
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
    
    const lines = text.split('\n');
    const fontSize = 12;
    const margin = 50;
    const lineHeight = fontSize * 1.2;
    const pageHeight = 842;
    const pageWidth = 595;
    const linesPerPage = Math.floor((pageHeight - 2 * margin) / lineHeight);
    
    for (let i = 0; i < lines.length; i += linesPerPage) {
      const page = pdfDoc.addPage([pageWidth, pageHeight]);
      const pageLines = lines.slice(i, i + linesPerPage);
      
      pageLines.forEach((line, index) => {
        page.drawText(line.substring(0, 80), {
          x: margin,
          y: pageHeight - margin - (index * lineHeight),
          size: fontSize,
          font,
          color: rgb(0, 0, 0),
        });
      });
    }
    
    job.progress = 80;
    const pdfBytes = await pdfDoc.save();
    await writeFile(outputPath, pdfBytes);
    
  } else {
    throw new Error(`Document conversion from ${sourceFormat} to ${targetFormat} not supported`);
  }
  
  job.progress = 95;
}

// Basic PDF text extraction (simplified)
function extractTextFromPDF(buffer: Buffer): string {
  // This is a very basic implementation
  // For production, use pdf-parse library
  const content = buffer.toString('latin1');
  const textMatches = content.match(/\(([^)]+)\)/g) || [];
  const text = textMatches
    .map(m => m.slice(1, -1))
    .filter(t => t.length > 1 && !/^[\\\/\d]+$/.test(t))
    .join(' ');
  return text || 'PDF text extraction requires pdf-parse library for better results.';
}

// Utility functions
function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Start server
app.listen(PORT, () => {
  console.log('');
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║                                                                ║');
  console.log('║   🔄 FileForge API Server - Real Conversion Engine             ║');
  console.log('║                                                                ║');
  console.log(`║   🌐 http://localhost:${PORT}                                     ║`);
  console.log('║                                                                ║');
  console.log('║   Supported conversions:                                       ║');
  console.log('║   • Images: JPG, PNG, WebP, GIF, AVIF, TIFF (via sharp)        ║');
  console.log('║   • Audio: MP3, WAV, OGG, FLAC, AAC (requires ffmpeg)          ║');
  console.log('║   • Video: MP4, AVI, MKV, WebM, MOV (requires ffmpeg)          ║');
  console.log('║   • Documents: PDF, TXT, DOCX                                  ║');
  console.log('║                                                                ║');
  console.log('║   Endpoints:                                                   ║');
  console.log('║   • GET  /health          - Health check                       ║');
  console.log('║   • GET  /api/formats     - List formats                       ║');
  console.log('║   • POST /api/upload      - Upload file                        ║');
  console.log('║   • POST /api/convert     - Start conversion                   ║');
  console.log('║   • GET  /api/status/:id  - Job status                         ║');
  console.log('║   • GET  /api/download/:id - Download result                   ║');
  console.log('║                                                                ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');
  console.log('');
});
