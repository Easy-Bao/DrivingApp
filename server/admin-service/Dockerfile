FROM oven/bun:1.3.14-alpine AS install
WORKDIR /app
COPY server/admin-service/package.json server/admin-service/bun.lock* ./
RUN bun install --frozen-lockfile

FROM oven/bun:1.3.14-alpine
WORKDIR /app
COPY --from=install /app/node_modules ./node_modules
COPY server/admin-service/package.json ./
COPY server/admin-service/src ./src
COPY server/admin-service/drizzle ./drizzle
COPY server/admin-service/drizzle.config.ts ./
EXPOSE 8090
CMD ["bun", "run", "src/index.ts"]
