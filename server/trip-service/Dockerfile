# Docker build for the trip-service Bun service.
FROM oven/bun:1.3.14-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/trip-service/package.json server/trip-service/bun.lock ./
RUN bun install --frozen-lockfile

# Copy source
COPY server/trip-service/src ./src
COPY server/trip-service/drizzle ./drizzle
COPY server/trip-service/drizzle.config.ts ./

# Expose service port
EXPOSE 8083

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
