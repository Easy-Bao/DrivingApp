FROM golang:1.25 AS build
WORKDIR /src
COPY server/go.mod server/go.sum ./
RUN go mod download
COPY server ./
RUN CGO_ENABLED=0 go build -o /out/api-gateway ./api-gateway

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/api-gateway /app/api-gateway
EXPOSE 8000
ENTRYPOINT ["/app/api-gateway"]
