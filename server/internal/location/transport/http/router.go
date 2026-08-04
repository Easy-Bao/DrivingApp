package http

import (
	"net/http"

	locationhandler "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
)

type Router struct{ handler *locationhandler.Handler }

func NewHandler(service *usecase.Service) *Router {
	return &Router{handler: locationhandler.NewHandler(service)}
}

func (router *Router) RegisterRoutes(mux *http.ServeMux) { router.handler.RegisterRoutes(mux) }
