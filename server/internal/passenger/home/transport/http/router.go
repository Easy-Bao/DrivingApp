package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/passenger/home"
	"github.com/Easy-Bao/DrivingApp/server/internal/passenger/home/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(query home.Query, verifier *token.Verifier) *Router {
	return &Router{handler: handler.NewHandler(query, verifier)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Get(api.V1Prefix+"/passenger/home", router.handler.Get)
}
