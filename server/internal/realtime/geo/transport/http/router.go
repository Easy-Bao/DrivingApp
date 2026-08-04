package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service, auth ...*security.TokenManager) *Router {
	return &Router{handler: handler.NewHandler(service, auth...)}
}

func (router *Router) RegisterRoutes(mux chi.Router) { router.handler.RegisterRoutes(mux) }
