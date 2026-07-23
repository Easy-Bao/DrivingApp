# Docker build for the auth-service Bun service.
FROM oven/bun:1.1-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/auth-service/package.json ./
RUN bun install

# Copy source
COPY server/auth-service/src ./src

# Expose server port
EXPOSE 8088

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
