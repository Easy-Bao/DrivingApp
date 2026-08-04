package main

import (
	"log"
	"net/http"
	"os"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
)

func main() {
	router := http.NewServeMux()
	router.Handle("/ws", ws.NewHandler(ws.NewHub(), token.NewVerifier(os.Getenv("JWT_SECRET"))))
	router.HandleFunc("GET /health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"realtime-service"}`))
	})

	log.Println("realtime-service listening on :8081")
	if err := http.ListenAndServe(":8081", router); err != nil {
		log.Fatal(err)
	}
}
