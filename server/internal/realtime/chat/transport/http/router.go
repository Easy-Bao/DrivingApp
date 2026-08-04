package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service) *Router {
	return &Router{handler: handler.NewHandler(service)}
}

func (router *Router) RegisterRoutes(mux chi.Router) { router.handler.RegisterRoutes(mux) }
