# FileForge API Dockerfile for Render.com
FROM node:20-slim

# Install ffmpeg and curl for healthcheck
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm ci

# Copy source
COPY . .

# Build TypeScript
RUN npm run build

# Remove devDependencies after build
RUN npm prune --production

# Create temp directories
RUN mkdir -p temp/uploads temp/results

# Expose port
EXPOSE 10000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:10000/health || exit 1

# Start server
CMD ["npm", "start"]
