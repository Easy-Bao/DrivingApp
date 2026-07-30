package main

import (
	"fmt"
	"location-service/internal/adapter/postgres"
	"location-service/internal/adapter/queue"
	"location-service/internal/adapter/redis"
	httptransport "location-service/internal/transport/http"
	wstransport "location-service/internal/transport/ws"
	"location-service/internal/usecase"
	"log"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8089"
	}

	dbURL := os.Getenv("DATABASE_URL")
	redisURL := os.Getenv("REDIS_URL")
	amqpURL := os.Getenv("RABBITMQ_URL")

	postgresAdapter := postgres.NewPostgresAdapter(dbURL)
	redisAdapter := redis.NewRedisAdapter(redisURL)
	queueAdapter := queue.NewRabbitMQAdapter(amqpURL)

	locationUseCase := usecase.NewLocationUseCase(
		postgresAdapter,
		redisAdapter,
		queueAdapter,
	)

	router := gin.Default()

	httpHandler := httptransport.NewHTTPHandler(locationUseCase)
	httpHandler.RegisterRoutes(router)

	wsHandler := wstransport.NewWSHandler(locationUseCase)
	wsHandler.RegisterRoutes(router)

	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "Location Service OK"})
	})

	log.Printf("Starting Location Service on port %s...", port)
	if err := router.Run(fmt.Sprintf(":%s", port)); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
