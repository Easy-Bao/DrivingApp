package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service, auth ...*security.TokenManager) *Router {
	return &Router{handler: handler.NewHandler(service, auth...)}
}

func (router *Router) RegisterRoutes(mux *http.ServeMux) { router.handler.RegisterRoutes(mux) }
