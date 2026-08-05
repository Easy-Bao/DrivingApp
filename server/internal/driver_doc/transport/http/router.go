package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service, verifier *token.Verifier) *Router {
	return &Router{handler: handler.NewHandler(service, verifier)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Route(api.V1Prefix, func(routes chi.Router) {
		routes.Post("/driver/documents", router.handler.Upload)
		routes.Get("/driver/documents/status", router.handler.Status)
		routes.Patch("/admin/documents/{id}/review", router.handler.Review)
	})
}
