package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(register *usecase.RegisterService, authenticate *usecase.AuthenticateService, otp ...*usecase.OTPService) *Router {
	var service *usecase.OTPService
	if len(otp) > 0 {
		service = otp[0]
	}
	return &Router{handler: handler.NewHandler(register, authenticate, service)}
}

func (router *Router) RegisterRoutes(mux chi.Router) { router.handler.RegisterRoutes(mux) }
