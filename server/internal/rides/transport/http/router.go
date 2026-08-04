package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service, verifier *token.Verifier) *Router {
	return &Router{handler: handler.NewHandler(service, verifier)}
}

func (router *Router) RegisterRoutes(mux chi.Router) { router.handler.RegisterRoutes(mux) }
