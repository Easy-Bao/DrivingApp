package main

import (
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
)

func main() {
	core := mustURL(env("CORE_API_URL", "http://127.0.0.1:8080"))
	realtime := mustURL(env("REALTIME_SERVICE_URL", "http://127.0.0.1:8081"))
	coreProxy := httputil.NewSingleHostReverseProxy(core)
	realtimeProxy := httputil.NewSingleHostReverseProxy(realtime)
	router := http.NewServeMux()
	router.Handle("/ws", realtimeProxy)
	router.Handle("/api/", coreProxy)
	router.HandleFunc("/health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"api-gateway"}`))
	})
	log.Println("api-gateway listening on :8000")
	log.Fatal(http.ListenAndServe(":"+env("GATEWAY_PORT", "8000"), withForwardedHeaders(router)))
}

func withForwardedHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		request.Header.Set("X-Forwarded-Proto", "http")
		next.ServeHTTP(writer, request)
	})
}
func env(key, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" {
		return value
	}
	return fallback
}
func mustURL(value string) *url.URL {
	parsed, err := url.Parse(value)
	if err != nil {
		log.Fatal(err)
	}
	return parsed
}
