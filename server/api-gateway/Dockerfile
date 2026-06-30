# Docker build for the api-gateway Bun service.
FROM oven/bun:1.1-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/api-gateway/package.json ./
RUN bun install

# Copy source
COPY server/api-gateway/src ./src

# Expose service port
EXPOSE 8080

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
