package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service, verifier *token.Verifier) *Router {
	return &Router{handler: handler.NewHandler(service, verifier)}
}

func (router *Router) RegisterRoutes(mux *http.ServeMux) { router.handler.RegisterRoutes(mux) }
