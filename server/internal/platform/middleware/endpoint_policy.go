package middleware

import "net/http"

type RoutePolicy uint8

const (
	RouteDefault RoutePolicy = iota + 1
	RouteHealth
	RouteAuthentication
	RouteRefresh
	RouteRealtimeConnection
	RouteTelemetry
	RouteLocationQuery
	RouteFareQuery
	RouteDocumentUpload
	RouteOnlinePresence
	RouteCommand
	RouteRead
)

func isStateChangingMethod(method string) bool {
	switch method {
	case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
		return true
	default:
		return false
	}
}
