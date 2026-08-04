package main

import (
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/shared-core/middleware"
)

func main() {
	core := mustURL(requiredEnv("CORE_API_URL"))
	realtime := mustURL(requiredEnv("REALTIME_SERVICE_URL"))
	coreProxy := httputil.NewSingleHostReverseProxy(core)
	realtimeProxy := httputil.NewSingleHostReverseProxy(realtime)
	router := http.NewServeMux()
	router.Handle("/ws", realtimeProxy)
	router.Handle("/api/v1/telemetry/", realtimeProxy)
	router.Handle("/telemetry/", realtimeProxy)
	router.Handle("/chat/", realtimeProxy)
	router.Handle("/api/v1/chat/", realtimeProxy)
	// The gateway is the sole public HTTP endpoint. Domain routing happens
	// behind it, so clients never need a URL for an individual module.
	router.Handle("/", coreProxy)
	router.HandleFunc("/health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"api-gateway"}`))
	})
	port := requiredEnv("GATEWAY_PORT")
	log.Println("api-gateway listening on :" + port)
	securedRouter := middleware.SecureHTTP(router, middleware.SecurityConfigFromEnv(), nil)
	log.Fatal(http.ListenAndServe(":"+port, withForwardedHeaders(securedRouter)))
}

func withForwardedHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		request.Header.Set("X-Forwarded-Proto", "http")
		clientHost, _, err := net.SplitHostPort(request.RemoteAddr)
		if err != nil {
			clientHost = request.RemoteAddr
		}
		request.Header.Set("X-Forwarded-For", clientHost)
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
