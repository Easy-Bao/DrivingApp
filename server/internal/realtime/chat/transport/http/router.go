package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler  *handler.Handler
	verifier *security.TokenManager
}

func NewRouter(service *usecase.ChatService, verifier *security.TokenManager) *Router {
	return &Router{handler: handler.NewHandler(service, verifier), verifier: verifier}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Group(func(protected chi.Router) {
		protected.Use(middleware.RequireAuth(router.verifier))
		protected.Post(api.V1Prefix+"/chat/rooms", router.handler.CreateRoom)
		protected.Get(api.V1Prefix+"/chat/rooms/{roomID}/messages", router.handler.Messages)
		protected.Post(api.V1Prefix+"/chat/rooms/{roomID}/resolve", router.handler.Resolve)
	})
}
