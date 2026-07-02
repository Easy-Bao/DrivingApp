FROM oven/bun:alpine
WORKDIR /app
COPY package.json ./
RUN bun install --production
COPY src/ ./src/
EXPOSE 8086
CMD ["bun", "run", "src/index.ts"]
