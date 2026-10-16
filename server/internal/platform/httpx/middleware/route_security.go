package middleware

import (
	"net/http"
)

type RouteSecurity struct {
	config      SecurityConfig
	limiter     *RateLimiter
	idempotency *Idempotency
}

type RouteSecurityDependencies struct {
	Config      SecurityConfig
	RateLimiter *RateLimiter
	Idempotency *Idempotency
}

func NewRouteSecurity(dependencies RouteSecurityDependencies) *RouteSecurity {
	return &RouteSecurity{
		config:      normalizedSecurityConfig(dependencies.Config),
		limiter:     dependencies.RateLimiter,
		idempotency: dependencies.Idempotency,
	}
}

func (security *RouteSecurity) Middleware(policy RoutePolicy) func(http.Handler) http.Handler {
	if security == nil {
		return func(next http.Handler) http.Handler { return next }
	}
	if policy == RouteDefault {
		return func(next http.Handler) http.Handler {
			readHandler := security.middlewareFor(RouteRead, next)
			commandHandler := security.middlewareFor(RouteCommand, next)
			return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
				if isStateChangingMethod(request.Method) {
					commandHandler.ServeHTTP(writer, request)
					return
				}
				readHandler.ServeHTTP(writer, request)
			})
		}
	}
	return func(next http.Handler) http.Handler {
		return security.middlewareFor(policy, next)
	}
}

func (security *RouteSecurity) middlewareFor(policy RoutePolicy, next http.Handler) http.Handler {
	handler := next
	if security.limiter != nil {
		handler = security.limiter.MiddlewareFor(policy)(handler)
	}
	if policy == RouteCommand && security.idempotency != nil {
		handler = security.idempotency.Middleware(handler)
	}
	if policy == RouteDocumentUpload {
		handler = DocumentUploadBodyLimit(security.config.JSONBodyLimit, security.config.UploadBodyLimit)(handler)
	} else {
		handler = RequestBodyLimit(security.config.JSONBodyLimit, security.config.UploadBodyLimit)(handler)
	}
	return handler
}
