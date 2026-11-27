package app

import (
	"net/http"

	chathttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/transport/http"
	chatwebsocket "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/transport/ws"
	placeshttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/transport/http"
	ridehttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/transport/http"
	trackinghttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/ws"
	"github.com/go-chi/chi/v5"
)

func registerApplicationRoutes(
	dependencies httpRouterDependencies,
	modules applicationModules,
) *chi.Mux {
	routeSecurity := dependencies.routeSecurity
	router := chi.NewRouter()
	router.NotFound(notFoundHandler(routeSecurity).ServeHTTP)
	router.MethodNotAllowed(methodNotAllowedHandler(routeSecurity).ServeHTTP)

	modules.authRouter.RegisterRoutes(router)
	modules.usersRouter.RegisterRoutes(router)
	modules.documentRouter.RegisterRoutes(router)
	modules.ridesRouter.RegisterRoutes(router)
	modules.dispatchRouter.RegisterRoutes(router)
	modules.reviewRouter.RegisterRoutes(router)
	router.With(routeSecurity.Middleware(middleware.RouteRead)).Group(func(admin chi.Router) {
		modules.adminRouter.RegisterRoutes(admin)
	})
	placeshttp.NewRouter(modules.locationService, modules.verifier, routeSecurity).RegisterRoutes(router)
	ridehttp.NewPassengerContextRouter(ridehttp.PassengerContextDependencies{
		Query:         modules.passengerRideContextQuery,
		Verifier:      modules.verifier,
		RouteSecurity: routeSecurity,
	}).RegisterRoutes(router)

	chatEventHandler := chatwebsocket.NewEventHandler(modules.chatService)
	chatProtocol := chatwebsocket.NewConnectionProtocol(chatEventHandler, modules.chatService)
	router.Get(
		api.V1Prefix+"/chat/ws",
		routeSecurity.Middleware(middleware.RouteRealtimeConnection)(websockethub.NewHandler(
			websockethub.HandlerDependencies{
				Hub:           modules.eventHub,
				Authenticator: modules.verifier,
				Protocol:      chatProtocol,
			},
			websockethub.WithAllowedOrigins(dependencies.config.Security.AllowedOrigins),
			websockethub.WithLogger(dependencies.applicationLogger),
		)).ServeHTTP,
	)
	router.Get(
		api.V1Prefix+"/realtime/ws",
		routeSecurity.Middleware(middleware.RouteRealtimeConnection)(websockethub.NewHandler(
			websockethub.HandlerDependencies{
				Hub:           modules.eventHub,
				Authenticator: modules.verifier,
			},
			websockethub.WithAllowedOrigins(dependencies.config.Security.AllowedOrigins),
			websockethub.WithLogger(dependencies.applicationLogger),
		)).ServeHTTP,
	)
	trackinghttp.NewTrackingRouter(trackinghttp.TrackingDependencies{
		Service:       modules.trackingService,
		Auth:          modules.verifier,
		RouteSecurity: routeSecurity,
	}).RegisterRoutes(router)
	chathttp.NewRouter(chathttp.Dependencies{
		Service:       modules.chatService,
		Verifier:      modules.verifier,
		RouteSecurity: routeSecurity,
	}).RegisterRoutes(router)
	registerHealthRoutesWithSubscriber(
		router,
		dependencies.redisClient,
		dependencies.postgresPool,
		modules.eventSubscriber,
		routeSecurity,
	)

	return router
}

func notFoundHandler(routeSecurity *middleware.RouteSecurity) http.Handler {
	handler := http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		response.Error(writer, http.StatusNotFound, "Resource not found.")
	})
	if routeSecurity == nil {
		return handler
	}
	return routeSecurity.Middleware(middleware.RouteRead)(handler)
}

func methodNotAllowedHandler(routeSecurity *middleware.RouteSecurity) http.Handler {
	handler := http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		response.Error(writer, http.StatusMethodNotAllowed, "Method not allowed.")
	})
	if routeSecurity == nil {
		return handler
	}
	return routeSecurity.Middleware(middleware.RouteRead)(handler)
}
