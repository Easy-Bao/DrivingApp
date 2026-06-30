# Docker build for the trip-service Bun service.
FROM oven/bun:1.1-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/trip-service/package.json ./
RUN bun install

# Copy source
COPY server/trip-service/src ./src

# Expose service port
EXPOSE 8083

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
