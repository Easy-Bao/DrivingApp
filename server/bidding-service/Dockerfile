# Docker build for the bidding-service Bun service.
FROM oven/bun:1.3.14-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/bidding-service/package.json server/bidding-service/bun.lock ./
RUN bun install --frozen-lockfile

# Copy source
COPY server/bidding-service/src ./src
COPY server/bidding-service/drizzle ./drizzle
COPY server/bidding-service/drizzle.config.ts ./

# Expose service port
EXPOSE 8084

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
