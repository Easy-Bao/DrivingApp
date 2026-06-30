# Docker build for the telemetry-service Bun service.
FROM oven/bun:1.1-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/telemetry-service/package.json ./
RUN bun install

# Copy source
COPY server/telemetry-service/src ./src

# Expose service port
EXPOSE 8085

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
