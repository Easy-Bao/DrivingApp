# Docker build for the auth-service Bun service.
FROM oven/bun:1.3.14-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/auth-service/package.json server/auth-service/bun.lock ./
RUN bun install --frozen-lockfile

# Copy source
COPY server/auth-service/src ./src
COPY server/auth-service/migrations ./migrations

# Expose server port
EXPOSE 8088

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
