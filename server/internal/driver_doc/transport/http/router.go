package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service, verifier *token.Verifier, authorizer *security.AdminAuthorizer) *Router {
	return &Router{handler: handler.NewHandler(service, verifier, authorizer)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Post(api.V1Prefix+"/driver/documents", router.handler.Upload)
	mux.Get(api.V1Prefix+"/driver/documents/status", router.handler.Status)
	mux.Patch(api.V1Prefix+"/admin/documents/{id}/review", router.handler.Review)
}
