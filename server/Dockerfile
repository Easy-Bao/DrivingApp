FROM golang:1.25 AS build
WORKDIR /src
COPY server/go.mod server/go.sum ./
RUN go mod download
COPY server ./
RUN CGO_ENABLED=0 go build -o /out/api ./cmd/api
RUN CGO_ENABLED=0 go build -o /out/migrate ./cmd/migrate

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/api /app/api
COPY --from=build /out/migrate /app/migrate
EXPOSE 8000
ENTRYPOINT ["/app/api"]
