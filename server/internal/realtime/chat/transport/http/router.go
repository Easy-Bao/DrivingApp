package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service) *Router {
	return &Router{handler: handler.NewHandler(service)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Route(api.V1Prefix, func(routes chi.Router) {
		routes.Route("/chat", func(chatRoutes chi.Router) {
			chatRoutes.Post("/rooms", router.handler.CreateRoom)
			chatRoutes.Get("/rooms/{roomID}/messages", router.handler.Messages)
			chatRoutes.Post("/rooms/{roomID}/resolve", router.handler.Resolve)
		})
	})
}
