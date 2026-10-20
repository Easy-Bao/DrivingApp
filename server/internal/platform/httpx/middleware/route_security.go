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

// Authenticated returns a middleware chain that enforces pre-authentication limits
// (request body size and rate limits), authenticates the principal, and then applies
// command protections (such as idempotency) scoped to the authenticated principal.
func (security *RouteSecurity) Authenticated(
	policy RoutePolicy,
	authenticate func(http.Handler) http.Handler,
	guards ...func(http.Handler) http.Handler,
) []func(http.Handler) http.Handler {
	chain := make([]func(http.Handler) http.Handler, 0, len(guards)+3)
	chain = append(chain, security.preAuthMiddleware(policy))
	if authenticate != nil {
		chain = append(chain, authenticate)
	}
	if policy == RouteCommand && security != nil && security.idempotency != nil {
		chain = append(chain, security.idempotency.Middleware)
	}
	chain = append(chain, guards...)
	return chain
}

func (security *RouteSecurity) preAuthMiddleware(policy RoutePolicy) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		handler := next
		if security != nil && security.limiter != nil {
			handler = security.limiter.MiddlewareFor(policy)(handler)
		}
		jsonLimit := _defaultJSONBodyLimit
		uploadLimit := _defaultUploadBodyLimit
		if security != nil {
			jsonLimit = security.config.JSONBodyLimit
			uploadLimit = security.config.UploadBodyLimit
		}
		if policy == RouteDocumentUpload {
			handler = DocumentUploadBodyLimit(jsonLimit, uploadLimit)(handler)
		} else {
			handler = RequestBodyLimit(jsonLimit, uploadLimit)(handler)
		}
		return handler
	}
}
