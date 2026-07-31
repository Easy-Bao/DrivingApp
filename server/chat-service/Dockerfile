FROM oven/bun:1.3.14-alpine
WORKDIR /usr/src/app
COPY server/chat-service/package.json server/chat-service/bun.lock ./
RUN bun install --frozen-lockfile --production
COPY server/chat-service/src ./src
EXPOSE 8086
CMD ["bun", "run", "src/index.ts"]
