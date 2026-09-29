package app

import (
	"context"
	"net/http"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	redisclient "github.com/redis/go-redis/v9"
)

type readinessState uint8

const (
	_readinessNotReady readinessState = iota + 1
	_readinessReady
)

func registerHealthRoutes(router chi.Router, redisClient *redisclient.Client, postgresPool *pgxpool.Pool) {
	router.Get("/health", func(writer http.ResponseWriter, _ *http.Request) {
		response.JSON(writer, http.StatusOK, map[string]string{
			"status":  "ok",
			"service": _serviceName,
		})
	})
	readinessHandler := func(writer http.ResponseWriter, request *http.Request) {
		checkContext, cancel := context.WithTimeout(request.Context(), 2*time.Second)
		defer cancel()
		if postgresPool == nil || postgresPool.Ping(checkContext) != nil {
			writeReadinessResponse(writer, http.StatusServiceUnavailable, _readinessNotReady)
			return
		}
		if err := redisClient.Ping(checkContext).Err(); err != nil {
			writeReadinessResponse(writer, http.StatusServiceUnavailable, _readinessNotReady)
			return
		}
		writeReadinessResponse(writer, http.StatusOK, _readinessReady)
	}
	router.Get("/healthz", readinessHandler)
	router.Get("/readyz", readinessHandler)
}

func writeReadinessResponse(writer http.ResponseWriter, status int, state readinessState) {
	readiness := "not_ready"
	if state == _readinessReady {
		readiness = "ready"
	}
	response.JSON(writer, status, map[string]string{
		"status":  readiness,
		"service": _serviceName,
	})
}
