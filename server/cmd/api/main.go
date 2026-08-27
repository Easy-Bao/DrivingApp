package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/Easy-Bao/DrivingApp/server/internal/bootstrap"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	config, err := bootstrap.LoadConfig()
	if err != nil {
		log.Fatal(err)
	}
	application, err := bootstrap.NewApplication(ctx, config)
	if err != nil {
		log.Fatal(err)
	}
	if err := application.Run(ctx); err != nil {
		log.Fatal(err)
	}
}
