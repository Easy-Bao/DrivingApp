# Docker build for the fare-service Bun service.
FROM oven/bun:1.3.14-alpine AS base
WORKDIR /usr/src/app

COPY server/fare-service/package.json server/fare-service/bun.lock ./
RUN bun install --frozen-lockfile

COPY server/fare-service/src ./src
COPY server/fare-service/drizzle ./drizzle
COPY server/fare-service/drizzle.config.ts ./

EXPOSE 8087
CMD ["bun", "run", "src/index.ts"]
