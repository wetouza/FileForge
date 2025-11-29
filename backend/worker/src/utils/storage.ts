import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { Readable } from 'stream';

const s3Client = new S3Client({
  endpoint: process.env.S3_ENDPOINT || 'http://localhost:9000',
  region: process.env.S3_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.S3_ACCESS_KEY || 'minioadmin',
    secretAccessKey: process.env.S3_SECRET_KEY || 'minioadmin',
  },
  forcePathStyle: true,
});

const bucket = process.env.S3_BUCKET || 'fileforge';

// Скачать файл из S3
export const downloadFile = async (key: string): Promise<Buffer> => {
  const response = await s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
  const stream = response.Body as Readable;
  const chunks: Buffer[] = [];
  
  for await (const chunk of stream) {
    chunks.push(chunk as Buffer);
  }
  
  return Buffer.concat(chunks);
};

// Загрузить файл в S3
export const uploadFile = async (key: string, buffer: Buffer, contentType: string): Promise<void> => {
  await s3Client.send(new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: buffer,
    ContentType: contentType,
  }));
};
