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
	core := mustURL(requiredEnv("CORE_API_URL"))
	realtime := mustURL(requiredEnv("REALTIME_SERVICE_URL"))
	coreProxy := httputil.NewSingleHostReverseProxy(core)
	realtimeProxy := httputil.NewSingleHostReverseProxy(realtime)
	router := http.NewServeMux()
	router.Handle("/ws", realtimeProxy)
	router.Handle("/api/v1/telemetry/", realtimeProxy)
	router.Handle("/api/", coreProxy)
	router.HandleFunc("/health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"api-gateway"}`))
	})
	port := requiredEnv("GATEWAY_PORT")
	log.Println("api-gateway listening on :" + port)
	log.Fatal(http.ListenAndServe(":"+port, withForwardedHeaders(router)))
}

func withForwardedHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		request.Header.Set("X-Forwarded-Proto", "http")
		next.ServeHTTP(writer, request)
	})
}
func requiredEnv(key string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" {
		return value
	}
	log.Fatal(key + " is required")
	return ""
}
func mustURL(value string) *url.URL {
	parsed, err := url.Parse(value)
	if err != nil || parsed.Scheme == "" || parsed.Host == "" {
		if err == nil {
			err = os.ErrInvalid
		}
		log.Fatal(err)
	}
	return parsed
}
