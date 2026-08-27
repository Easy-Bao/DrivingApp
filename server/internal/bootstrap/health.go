package bootstrap

import (
	"context"
	"net/http"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/go-chi/chi/v5"
	redisclient "github.com/redis/go-redis/v9"
)

func registerHealthRoutes(router chi.Router, databaseClient *ent.Client, redisClient *redisclient.Client) {
	router.Get("/health", func(writer http.ResponseWriter, _ *http.Request) {
		response.JSON(writer, http.StatusOK, map[string]string{
			"status":  "ok",
			"service": serviceName,
		})
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
	response.JSON(writer, status, map[string]string{
		"status":  readiness,
		"service": serviceName,
	})
}
