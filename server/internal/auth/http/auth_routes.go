package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/authentication"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/registration"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/verification"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler              *Handler
	otpVerificationLimit *OTPVerificationRateLimiter
}

type RouterDependencies struct {
	Register     *registration.RegisterService
	Authenticate *authentication.AuthenticateService
	OTP          *verification.OTPService
}

type RouterOption func(*Router)

func WithOTPAttemptStore(store middleware.CounterStore) RouterOption {
	return func(router *Router) {
		if store != nil {
			router.otpVerificationLimit = NewOTPVerificationRateLimiter(store)
		}
	}
}

func NewRouter(
	dependencies RouterDependencies,
	options ...RouterOption,
) *Router {
	router := &Router{
		handler: NewHandler(Dependencies{
			Register:     dependencies.Register,
			Authenticate: dependencies.Authenticate,
			OTP:          dependencies.OTP,
		}),
	}
	for _, option := range options {
		if option != nil {
			option(router)
		}
	}
	return router
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
	mux.Method(
		http.MethodPost,
		api.V1Prefix+"/auth/passenger/verify-otp",
		router.limitOTPAttempts(router.handler.VerifyOTP),
	)
	mux.Post(api.V1Prefix+"/auth/passenger/forgot-password", router.handler.ForgotPassword)
	mux.Method(
		http.MethodPost,
		api.V1Prefix+"/auth/passenger/reset-password",
		router.limitOTPAttempts(router.handler.ResetPassword),
	)
	mux.Post(api.V1Prefix+"/auth/driver/forgot-password", router.handler.DriverForgotPassword)
	mux.Method(
		http.MethodPost,
		api.V1Prefix+"/auth/driver/reset-password",
		router.limitOTPAttempts(router.handler.DriverResetPassword),
	)
}

func (router *Router) limitOTPAttempts(next http.HandlerFunc) http.Handler {
	if router.otpVerificationLimit == nil {
		return next
	}
	return router.otpVerificationLimit.Middleware(next)
}
