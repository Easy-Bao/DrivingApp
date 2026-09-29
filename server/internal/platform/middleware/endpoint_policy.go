package middleware

import (
	"net/http"
	"strings"
)

type endpointKind uint8

const (
	_endpointRead endpointKind = iota
	_endpointHealth
	_endpointAuthentication
	_endpointRefresh
	_endpointRealtimeConnection
	_endpointTelemetry
	_endpointLocationQuery
	_endpointFareQuery
	_endpointDocumentUpload
	_endpointOnlinePresence
	_endpointCommand
)

func classifyEndpoint(request *http.Request) endpointKind {
	if request == nil {
		return _endpointRead
	}
	path := request.URL.Path
	if path == "/health" || path == "/healthz" || path == "/readyz" {
		return _endpointHealth
	}
	if path == "/api/v1/chat/ws" || path == "/api/v1/realtime/ws" {
		return _endpointRealtimeConnection
	}
	if path == "/api/v1/auth/refresh" {
		return _endpointRefresh
	}
	if hasPathPrefix(path, "/api/v1/auth") {
		return _endpointAuthentication
	}
	if hasPathPrefix(path, "/api/v1/telemetry") {
		return _endpointTelemetry
	}
	if hasPathPrefix(path, "/api/v1/location") {
		return _endpointLocationQuery
	}
	if isFareQuery(path) {
		return _endpointFareQuery
	}
	if request.Method == http.MethodPost && path == "/api/v1/driver/documents" {
		return _endpointDocumentUpload
	}
	if request.Method == http.MethodPost &&
		hasPathPrefix(path, "/api/v1/drivers") &&
		strings.HasSuffix(path, "/online") {
		return _endpointOnlinePresence
	}
	if isStateChangingMethod(request.Method) {
		return _endpointCommand
	}
	return _endpointRead
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
