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
	mux.Post(api.V1Prefix+"/chat/rooms", router.handler.CreateRoom)
	mux.Get(api.V1Prefix+"/chat/rooms/{roomID}/messages", router.handler.Messages)
	mux.Post(api.V1Prefix+"/chat/rooms/{roomID}/resolve", router.handler.Resolve)
}
