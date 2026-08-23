package middleware

import (
	"net/http"
	"strings"
)

type endpointKind uint8

const (
	endpointRead endpointKind = iota
	endpointHealth
	endpointAuthentication
	endpointRealtimeConnection
	endpointTelemetry
	endpointLocationQuery
	endpointFareQuery
	endpointDocumentUpload
	endpointOnlinePresence
	endpointCommand
)

func classifyEndpoint(request *http.Request) endpointKind {
	if request == nil {
		return endpointRead
	}
	path := request.URL.Path
	if path == "/health" {
		return endpointHealth
	}
	if path == "/api/v1/chat/ws" || path == "/api/v1/realtime/ws" {
		return endpointRealtimeConnection
	}
	if hasPathPrefix(path, "/api/v1/auth") {
		return endpointAuthentication
	}
	if hasPathPrefix(path, "/api/v1/telemetry") {
		return endpointTelemetry
	}
	if hasPathPrefix(path, "/api/v1/location") {
		return endpointLocationQuery
	}
	if isFareQuery(path) {
		return endpointFareQuery
	}
	if request.Method == http.MethodPost && path == "/api/v1/driver/documents" {
		return endpointDocumentUpload
	}
	if request.Method == http.MethodPost &&
		hasPathPrefix(path, "/api/v1/drivers") &&
		strings.HasSuffix(path, "/online") {
		return endpointOnlinePresence
	}
	if isStateChangingMethod(request.Method) {
		return endpointCommand
	}
	return endpointRead
}

func hasPathPrefix(path, prefix string) bool {
	return path == prefix || strings.HasPrefix(path, prefix+"/")
}

func isFareQuery(path string) bool {
	switch path {
	case "/api/v1/bids/fare", "/api/v1/fares/estimate", "/api/v1/fares/calculate-final":
		return true
	default:
		return false
	}
}

func isStateChangingMethod(method string) bool {
	switch method {
	case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
		return true
	default:
		return false
	}
}
