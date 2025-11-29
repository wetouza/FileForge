# 🔄 FileForge - Universal File Converter

Полноценное Android-приложение + backend для конвертации файлов любых популярных форматов.

## 📁 Структура проекта

```
/mobile-app          # Flutter Android приложение
/backend
  /api               # Node.js + TypeScript REST API
  /worker            # Worker для обработки конвертаций
  /ffmpeg-layer      # Docker образ с инструментами конвертации
/infra               # Docker-compose, переменные окружения
/tests               # Тесты
```

## 🚀 Быстрый старт

### Требования
- Docker & Docker Compose
- Flutter SDK 3.x
- Node.js 20+
- Android Studio / VS Code

### 1. Запуск Backend (Docker)

```bash
cd infra
docker-compose up -d
```

Сервисы:
- API: http://localhost:3000
- Redis: localhost:6379
- MinIO (S3): http://localhost:9000

### 2. Запуск Flutter приложения

```bash
cd mobile-app
flutter pub get
flutter run
```

## 🎯 Поддерживаемые форматы

### Аудио
- MP3, WAV, FLAC, AAC, OGG, M4A, WMA

### Видео
- MP4, AVI, MKV, MOV, WebM, FLV, WMV, GIF

### Изображения
- JPG, PNG, WebP, GIF, BMP, TIFF, SVG, ICO, HEIC

### Документы
- PDF, DOCX, DOC, TXT, RTF, ODT, HTML, MD, EPUB

### Архивы
- ZIP, RAR, 7Z, TAR, GZ

### Субтитры
- SRT, VTT, ASS, SSA

## 🏗️ Архитектура

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│   API Server    │────▶│     Redis       │
│   (Android)     │     │  (Node.js/TS)   │     │   (BullMQ)      │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                        ┌─────────────────┐              │
                        │     Worker      │◀─────────────┘
                        │  (Converters)   │
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │  FFmpeg Layer   │
                        │ (Docker Image)  │
                        └─────────────────┘
```

## 📱 API Endpoints

| Method | Endpoint | Описание |
|--------|----------|----------|
| POST | /api/upload | Загрузка файла |
| POST | /api/convert | Запуск конвертации |
| GET | /api/status/:jobId | Статус задачи |
| GET | /api/download/:fileId | Скачивание результата |
| GET | /api/formats | Список форматов |
| WS | /ws | WebSocket для прогресса |

## ☁️ Деплой на бесплатный хостинг

### Render.com
1. Создайте Web Service из репозитория
2. Укажите `backend/api` как root directory
3. Build command: `npm install && npm run build`
4. Start command: `npm start`

### Cloudflare R2 (хранилище)
1. Создайте R2 bucket
2. Настройте переменные окружения S3_*

### Redis (Upstash)
1. Создайте бесплатную Redis базу на upstash.com
2. Скопируйте REDIS_URL в переменные окружения

## 🔧 Переменные окружения

```env
# API
PORT=3000
NODE_ENV=production

# Redis
REDIS_URL=redis://localhost:6379

# S3/MinIO
S3_ENDPOINT=http://localhost:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET=fileforge

# JWT
JWT_SECRET=your-secret-key
```

## 🧪 Тесты

```bash
# Backend тесты
cd backend/api
npm test

# Flutter тесты
cd mobile-app
flutter test
```

## 📄 Лицензия

MIT License
