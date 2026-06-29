# Docker build for the passenger-service Bun service.
FROM oven/bun:1.1-alpine AS base
WORKDIR /usr/src/app

# Copy configuration and install dependencies
COPY server/passenger-service/package.json server/passenger-service/tsconfig.json ./
RUN bun install

# Copy source and migrations
COPY server/passenger-service/src ./src
COPY server/passenger-service/prisma ./prisma
COPY server/passenger-service/migrations ./migrations

# Generate Prisma Client
RUN bunx prisma generate

# Expose server port
EXPOSE 8081

# Run Bun application
CMD ["bun", "run", "src/index.ts"]
