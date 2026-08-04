package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service) *Router {
	return &Router{handler: handler.NewHandler(service)}
}

func (router *Router) RegisterRoutes(mux *http.ServeMux) { router.handler.RegisterRoutes(mux) }
