package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
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

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Post(api.V1Prefix+"/auth/register", router.handler.GenericRegister)
	mux.Post(api.V1Prefix+"/auth/login", router.handler.Login)
	mux.Post(api.V1Prefix+"/auth/passenger/register", router.handler.PassengerRegister)
	mux.Post(api.V1Prefix+"/auth/driver/register", router.handler.DriverRegister)
	mux.Post(api.V1Prefix+"/auth/passenger/login", router.handler.PassengerLogin)
	mux.Post(api.V1Prefix+"/auth/driver/login", router.handler.DriverLogin)
	mux.Post(api.V1Prefix+"/auth/refresh", router.handler.RefreshToken)
	mux.Post(api.V1Prefix+"/auth/logout", router.handler.Logout)
	mux.Post(api.V1Prefix+"/auth/passenger/otp", router.handler.RequestOTP)
	mux.Post(api.V1Prefix+"/auth/passenger/verify-otp", router.handler.VerifyOTP)
	mux.Post(api.V1Prefix+"/auth/passenger/forgot-password", router.handler.ForgotPassword)
	mux.Post(api.V1Prefix+"/auth/passenger/reset-password", router.handler.ResetPassword)
	mux.Post(api.V1Prefix+"/auth/driver/forgot-password", router.handler.DriverForgotPassword)
	mux.Post(api.V1Prefix+"/auth/driver/reset-password", router.handler.DriverResetPassword)
}
