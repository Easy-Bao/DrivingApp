package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler       *Handler
	verifier      *security.TokenManager
	routeSecurity *middleware.RouteSecurity
}

func NewRouter(dependencies Dependencies) *Router {
	return &Router{
		handler:       NewHandler(dependencies),
		verifier:      dependencies.Verifier,
		routeSecurity: dependencies.RouteSecurity,
	}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	authenticate := middleware.RequireAuth(router.verifier)
	mux.With(router.routeSecurity.Middleware(middleware.RouteCommand), authenticate).Post(
		api.V1Prefix+"/chat/rooms",
		router.handler.CreateRoom,
	)
	mux.With(router.routeSecurity.Middleware(middleware.RouteRead), authenticate).Get(
		api.V1Prefix+"/chat/rooms/{roomID}/messages",
		router.handler.Messages,
	)
	mux.With(router.routeSecurity.Middleware(middleware.RouteCommand), authenticate).Post(
		api.V1Prefix+"/chat/rooms/{roomID}/resolve",
		router.handler.Resolve,
	)
}
