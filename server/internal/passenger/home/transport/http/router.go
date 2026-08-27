package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/passenger/home"
	"github.com/Easy-Bao/DrivingApp/server/internal/passenger/home/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(query home.Query, verifier *security.TokenManager) *Router {
	return &Router{handler: handler.NewHandler(query, verifier)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Get(api.V1Prefix+"/passenger/home", router.handler.Get)
}
