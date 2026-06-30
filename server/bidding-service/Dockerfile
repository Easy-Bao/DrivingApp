# Docker build for the bidding-service Bun service.
FROM oven/bun:1.1-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/bidding-service/package.json ./
RUN bun install

# Copy source
COPY server/bidding-service/src ./src

# Expose service port
EXPOSE 8084

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
