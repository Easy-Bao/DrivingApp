package bootstrap

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
	"github.com/go-chi/chi/v5"
	redisclient "github.com/redis/go-redis/v9"
)

func registerHealthRoutes(router chi.Router, databaseClient *ent.Client, redisClient *redisclient.Client) {
	router.Get("/health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"api"}`))
	})
	router.Get("/readyz", func(writer http.ResponseWriter, request *http.Request) {
		checkContext, cancel := context.WithTimeout(request.Context(), 2*time.Second)
		defer cancel()
		if err := platformmigration.ValidateEntSchema(checkContext, databaseClient); err != nil {
			writeReadinessResponse(writer, http.StatusServiceUnavailable, false)
			return
		}
		if err := redisClient.Ping(checkContext).Err(); err != nil {
			writeReadinessResponse(writer, http.StatusServiceUnavailable, false)
			return
		}
		writeReadinessResponse(writer, http.StatusOK, true)
	})
}

func writeReadinessResponse(writer http.ResponseWriter, status int, ready bool) {
	readiness := "not_ready"
	if ready {
		readiness = "ready"
	}
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(map[string]string{
		"status":  readiness,
		"service": serviceName,
	})
}
