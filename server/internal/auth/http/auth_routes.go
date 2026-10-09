package http

import (
	"net/http"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/authentication"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/registration"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/verification"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler              *Handler
	otpVerificationLimit *OTPVerificationRateLimiter
	routeSecurity        *middleware.RouteSecurity
}

type RouterDependencies struct {
	Register      *registration.RegisterService
	Authenticate  *authentication.AuthenticateService
	OTP           *verification.OTPService
	Verifier      *security.TokenManager
	RouteSecurity *middleware.RouteSecurity
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
			Verifier:     dependencies.Verifier,
		}),
		routeSecurity: dependencies.RouteSecurity,
	}
	for _, option := range options {
		if option != nil {
			option(router)
		}
	}
	return router
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	registerPath := api.V1Prefix + "/auth/register"
	loginPath := api.V1Prefix + "/auth/login"
	authentication := router.routeSecurity.Middleware(middleware.RouteAuthentication)
	refresh := router.routeSecurity.Middleware(middleware.RouteRefresh)
	command := router.routeSecurity.Middleware(middleware.RouteCommand)
	mux.With(authentication).Post(registerPath, router.handler.GenericRegister)
	mux.With(authentication).Post(loginPath, router.handler.Login)
	mux.With(authentication, middleware.Deprecation(registerPath)).Post(
		api.V1Prefix+"/auth/passenger/register",
		router.handler.PassengerRegister,
	)
	mux.With(authentication, middleware.Deprecation(registerPath)).Post(
		api.V1Prefix+"/auth/driver/register",
		router.handler.DriverRegister,
	)
	mux.With(authentication, middleware.Deprecation(loginPath)).Post(
		api.V1Prefix+"/auth/passenger/login",
		router.handler.PassengerLogin,
	)
	mux.With(authentication, middleware.Deprecation(loginPath)).Post(
		api.V1Prefix+"/auth/driver/login",
		router.handler.DriverLogin,
	)
	mux.With(refresh).Post(api.V1Prefix+"/auth/refresh", router.handler.RefreshToken)
	mux.With(authentication).Post(api.V1Prefix+"/auth/logout", router.handler.Logout)
	mux.With(authentication).Post(api.V1Prefix+"/auth/passenger/otp", router.handler.RequestOTP)
	mux.With(authentication).Method(
		http.MethodPost,
		api.V1Prefix+"/auth/passenger/verify-otp",
		router.limitOTPAttempts(router.handler.VerifyOTP),
	)
	mux.With(authentication).Post(api.V1Prefix+"/auth/passenger/forgot-password", router.handler.ForgotPassword)
	mux.With(authentication).Method(
		http.MethodPost,
		api.V1Prefix+"/auth/passenger/reset-password",
		router.limitOTPAttempts(router.handler.ResetPassword),
	)
	mux.With(authentication).Post(api.V1Prefix+"/auth/driver/forgot-password", router.handler.DriverForgotPassword)
	mux.With(authentication).Method(
		http.MethodPost,
		api.V1Prefix+"/auth/driver/reset-password",
		router.limitOTPAttempts(router.handler.DriverResetPassword),
	)
	protected := middleware.RequireAuth(router.handler.verifier)
	mux.With(command, protected).Method(
		http.MethodPost,
		api.V1Prefix+"/users/me/email/request",
		router.limitOTPAttempts(router.handler.RequestEmailChange),
	)
	mux.With(command, protected).Method(
		http.MethodPost,
		api.V1Prefix+"/users/me/email/confirm",
		router.limitOTPAttempts(router.handler.ConfirmEmailChange),
	)
}

func (router *Router) limitOTPAttempts(next http.HandlerFunc) http.Handler {
	if router.otpVerificationLimit == nil {
		return next
	}
	return router.otpVerificationLimit.Middleware(next)
}
