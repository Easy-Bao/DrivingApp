FROM golang:1.25 AS build
WORKDIR /src
COPY server/go.mod server/go.sum ./
RUN go mod download
COPY server ./
RUN CGO_ENABLED=0 go build -o /out/core-api ./cmd/core-api && \
    CGO_ENABLED=0 go build -o /out/realtime-service ./cmd/realtime-service

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/core-api /app/core-api
COPY --from=build /out/realtime-service /app/realtime-service
ENTRYPOINT ["/app/core-api"]
