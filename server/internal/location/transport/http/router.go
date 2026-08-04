package http

import (
	locationhandler "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *locationhandler.Handler }

func NewHandler(service *usecase.Service) *Router {
	return &Router{handler: locationhandler.NewHandler(service)}
}

func (router *Router) RegisterRoutes(mux chi.Router) { router.handler.RegisterRoutes(mux) }
