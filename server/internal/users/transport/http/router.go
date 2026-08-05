package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service, verifier *token.Verifier) *Router {
	return &Router{handler: handler.NewHandler(service, verifier)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Route(api.V1Prefix, func(routes chi.Router) {
		routes.Get("/users/me", router.handler.Me)
		routes.Patch("/users/me", router.handler.Update)
		routes.Get("/passengers/{id}", router.handler.Profile)
		routes.Put("/passengers/{id}", router.handler.ProfileUpdate)
		routes.Get("/drivers/{id}", router.handler.Profile)
		routes.Post("/drivers/{id}/online", router.handler.Online)
		routes.Get("/passengers/{id}/notifications", router.handler.Notifications)
	})
}
