import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { config } from '../config/index.js';
import { v4 as uuid } from 'uuid';
import { Readable } from 'stream';

// S3 клиент (совместим с MinIO)
const s3Client = new S3Client({
  endpoint: config.s3.endpoint,
  region: config.s3.region,
  credentials: {
    accessKeyId: config.s3.accessKey,
    secretAccessKey: config.s3.secretKey,
  },
  forcePathStyle: true, // Для MinIO
});

// Загрузка файла в S3
export const uploadToS3 = async (
  buffer: Buffer,
  originalName: string,
  mimeType: string
): Promise<{ key: string; id: string }> => {
  const id = uuid();
  const ext = originalName.split('.').pop() || '';
  const key = `uploads/${id}.${ext}`;

  await s3Client.send(new PutObjectCommand({
    Bucket: config.s3.bucket,
    Key: key,
    Body: buffer,
    ContentType: mimeType,
    Metadata: { originalName },
  }));

  return { key, id };
};

// Загрузка результата конвертации
export const uploadResult = async (
  buffer: Buffer,
  jobId: string,
  format: string,
  mimeType: string
): Promise<string> => {
  const key = `results/${jobId}.${format}`;

  await s3Client.send(new PutObjectCommand({
    Bucket: config.s3.bucket,
    Key: key,
    Body: buffer,
    ContentType: mimeType,
  }));

  return key;
};

// Получение файла из S3
export const getFromS3 = async (key: string): Promise<Buffer> => {
  const response = await s3Client.send(new GetObjectCommand({
    Bucket: config.s3.bucket,
    Key: key,
  }));

  const stream = response.Body as Readable;
  const chunks: Buffer[] = [];
  
  for await (const chunk of stream) {
    chunks.push(chunk as Buffer);
  }
  
  return Buffer.concat(chunks);
};

// Получение presigned URL для скачивания
export const getDownloadUrl = async (key: string, expiresIn = 3600): Promise<string> => {
  const command = new GetObjectCommand({
    Bucket: config.s3.bucket,
    Key: key,
  });
  
  return getSignedUrl(s3Client, command, { expiresIn });
};

// Удаление файла
export const deleteFromS3 = async (key: string): Promise<void> => {
  await s3Client.send(new DeleteObjectCommand({
    Bucket: config.s3.bucket,
    Key: key,
  }));
};
