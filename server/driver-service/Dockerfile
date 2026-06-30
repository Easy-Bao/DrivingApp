# Docker build for the driver-service Bun service.
FROM oven/bun:1.1-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/driver-service/package.json ./
RUN bun install

# Copy source
COPY server/driver-service/src ./src

# Expose service port
EXPOSE 8082

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
