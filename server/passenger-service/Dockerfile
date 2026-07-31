# Docker build for the passenger-service Bun service.
FROM oven/bun:1.3.14-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/passenger-service/package.json server/passenger-service/bun.lock ./
RUN bun install --frozen-lockfile

# Copy source and reviewed Drizzle migrations
COPY server/passenger-service/src ./src
COPY server/passenger-service/drizzle ./drizzle
COPY server/passenger-service/drizzle.config.ts ./

# Expose server port
EXPOSE 8081

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
