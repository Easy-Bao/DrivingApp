# Docker build for the fare-service Bun service.
FROM oven/bun:1.1-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/fare-service/package.json ./
RUN bun install

# Copy source
COPY server/fare-service/src ./src

# Expose server port
EXPOSE 8087

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
