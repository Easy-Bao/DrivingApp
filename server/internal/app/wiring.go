package app

import (
	"context"
	"log/slog"

	adminapplication "github.com/Easy-Bao/DrivingApp/server/internal/admin/application"
	adminports "github.com/Easy-Bao/DrivingApp/server/internal/admin/ports"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/email"
	authredis "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/redis"
	authapplication "github.com/Easy-Bao/DrivingApp/server/internal/auth/application"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http"
	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/chat/adapter"
	chatapplication "github.com/Easy-Bao/DrivingApp/server/internal/chat/application"
	chath "github.com/Easy-Bao/DrivingApp/server/internal/chat/transport/http"
	chatws "github.com/Easy-Bao/DrivingApp/server/internal/chat/transport/ws"
	assignmentadapter "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/adapter"
	assignmentapplication "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/application"
	documentapplication "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/application"
	documentports "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/ports"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/mapbox"
	locationredis "github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/redis"
	locationapplication "github.com/Easy-Bao/DrivingApp/server/internal/location/application"
	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	trackingadapter "github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/adapter"
	trackingapplication "github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/application"
	trackinghttp "github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/transport/http"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	passengerridecontextapplication "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext/application"
	passengerridecontextadapter "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext/adapter"
	passengerridecontexthttp "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/platform/events/adapter"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/websocket"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	rideports "github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
	ridehttp "github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/http"
	userapplication "github.com/Easy-Bao/DrivingApp/server/internal/user/application"
	userports "github.com/Easy-Bao/DrivingApp/server/internal/user/ports"
	userhttp "github.com/Easy-Bao/DrivingApp/server/internal/user/transport/http"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	redisclient "github.com/redis/go-redis/v9"
)

type rideRuntimeStore interface {
	rideports.RideStore
	ActiveRidesForDriver(context.Context, int) ([]ridedomain.Ride, error)
}

func newHTTPRouter(
	config Config,
	postgresPool *pgxpool.Pool,
	redisClient *redisclient.Client,
	applicationLogger *slog.Logger,
	authStore authports.VerifiedUserStore,
	sessionStore authports.SessionStore,
	rideStore rideRuntimeStore,
	profileStore userports.ProfileStore,
	statsReader adminports.StatsReader,
	documentStore documentports.DocumentStore,
	privateObjectStore platformstorage.ObjectStore,
) (*chi.Mux, *websockethub.Hub) {
	verifier := security.NewTokenManager(config.JWTSecret)
	adminAuthorizer := security.NewAdminAuthorizer(config.AdminUserIDs)

	registerService := authapplication.NewRegisterService(authStore, verifier, sessionStore)
	authenticateService := authapplication.NewAuthenticateService(authStore, verifier, sessionStore).WithLogger(applicationLogger)
	otpService := authapplication.NewOTPServiceWithPending(
		authStore,
		authredis.NewOTPStore(redisClient),
		email.NewGoMailGatewayFromEnv(),
		verifier,
		authredis.NewPendingRegistrationStore(redisClient),
		registerService,
		sessionStore,
	).WithLogger(applicationLogger)
	authRouter := authhttp.NewRouter(registerService, authenticateService, otpService)

	usersRouter := userhttp.NewRouter(userapplication.NewProfileService(profileStore), verifier)
	documentRouter := documenthttp.NewRouter(
		documentapplication.NewDocumentService(
			documentStore,
			privateObjectStore,
			config.Security.UploadBodyLimit,
		),
		verifier,
		adminAuthorizer,
	)

	mapboxProvider := mapbox.NewMapboxProvider(config.MapboxAccessToken)
	routeCalculator := rideapplication.RouteCalculatorFunc(func(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (rideapplication.RouteMetrics, error) {
		route, err := mapboxProvider.Route(ctx, locationdomain.Coordinates{Latitude: originLat, Longitude: originLng}, locationdomain.Coordinates{Latitude: destinationLat, Longitude: destinationLng}, locationdomain.RouteOptions{})
		if err != nil {
			return rideapplication.RouteMetrics{}, err
		}
		return rideapplication.RouteMetrics{DistanceKm: route.DistanceKm, DurationMinutes: route.DurationMin}, nil
	})
	eventHub := websockethub.NewHub()
	assignmentProjection := assignmentadapter.NewMemoryProjection()
	eventPublisher := eventadapter.NewMemoryPublisher(assignmentProjection, eventHub)
	ridesService := rideapplication.NewRideServiceWithRouteCalculator(
		rideStore,
		routeCalculator,
		config.Pricing,
		eventPublisher,
	).WithReportingLocation(config.ReportingLocation).WithLogger(applicationLogger)
	rideAssignments := assignmentapplication.NewResolver(
		assignmentProjection,
		assignmentadapter.NewRideLookup(rideStore),
	)

	ridesRouter := ridehttp.NewRouter(ridesService, verifier)
	adminRouter := adminhttp.NewRouter(adminapplication.NewStatsService(statsReader), verifier, adminAuthorizer)
	trackingService := trackingapplication.NewLocationTrackingService(
		trackingadapter.NewDriverLocationStore(redisClient).WithLogger(applicationLogger),
		trackingapplication.WithRideAssignments(rideAssignments),
		trackingapplication.WithEventPublisher(eventPublisher),
		trackingapplication.WithLogger(applicationLogger),
	)
	locationService := locationapplication.NewLocationServiceWithCache(
		mapboxProvider,
		locationredis.NewCache(redisClient),
	).WithLogger(applicationLogger)
	passengerRideContextQuery := passengerridecontextapplication.NewQueryService(
		passengerridecontextadapter.NewRidesReader(ridesService),
		passengerridecontextadapter.NewLocationResolver(locationService),
	)

	router := chi.NewRouter()
	authRouter.RegisterRoutes(router)
	usersRouter.RegisterRoutes(router)
	documentRouter.RegisterRoutes(router)
	ridesRouter.RegisterRoutes(router)
	adminRouter.RegisterRoutes(router)
	locationhttp.NewRouter(locationService).RegisterRoutes(router)
	passengerridecontexthttp.NewRouter(passengerRideContextQuery, verifier).RegisterRoutes(router)

	chatRoomStore := chatadapter.NewChatHistoryStore(redisClient)
	chatService := chatapplication.NewChatService(chatRoomStore).
		WithEventPublisher(eventPublisher).
		WithRideAssignmentLookup(rideAssignments).
		WithLogger(applicationLogger)
	chatEventRouter := chatws.NewEventRouter()
	chatEventHandler := chatws.NewEventHandler(chatService)
	chatEventRouter.Register("CHAT_MESSAGE", chatEventHandler)
	chatEventRouter.Register("message", chatEventHandler)
	chatEventRouter.Register("typing", chatEventHandler)
	router.Handle(
		api.V1Prefix+"/chat/ws",
		chatws.NewHandlerWithSink(chatws.NewRoomHub(), verifier, chatEventRouter, chatService).
			WithAllowedOrigins(config.Security.AllowedOrigins),
	)
	router.Handle(api.V1Prefix+"/realtime/ws", websockethub.NewHandler(eventHub, verifier, config.Security.AllowedOrigins))
	trackinghttp.NewRouter(trackingService, verifier).RegisterRoutes(router)
	chath.NewRouter(chatService, verifier).RegisterRoutes(router)
	registerHealthRoutes(router, redisClient, postgresPool)

	return router, eventHub
}
