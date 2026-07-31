# Docker build for the driver-service Bun service.
FROM oven/bun:1.3.14-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/driver-service/package.json server/driver-service/bun.lock ./
RUN bun install --frozen-lockfile

# Copy source
COPY server/driver-service/src ./src
COPY server/driver-service/drizzle ./drizzle
COPY server/driver-service/drizzle.config.ts ./

# Expose service port
EXPOSE 8082

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
