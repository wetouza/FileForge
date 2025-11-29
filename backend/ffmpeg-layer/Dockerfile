# FFmpeg Layer - Docker образ с инструментами конвертации
FROM node:20-slim

# Установка системных зависимостей
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    imagemagick \
    libvips-tools \
    libreoffice \
    pandoc \
    poppler-utils \
    ghostscript \
    p7zip-full \
    unrar-free \
    fontforge \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Настройка ImageMagick policy для PDF
RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml || true

WORKDIR /app

# Копирование worker
COPY backend/worker/package*.json ./
RUN npm ci --only=production

COPY backend/worker/dist ./dist

# Создание директории для временных файлов
RUN mkdir -p /tmp/fileforge && chmod 777 /tmp/fileforge

ENV NODE_ENV=production
ENV TEMP_DIR=/tmp/fileforge

CMD ["node", "dist/index.js"]
