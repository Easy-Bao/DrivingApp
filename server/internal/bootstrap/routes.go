package bootstrap

import (
	"context"
	"log/slog"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	adminpostgres "github.com/Easy-Bao/DrivingApp/server/internal/admin/adapter/postgres"
	adminapplication "github.com/Easy-Bao/DrivingApp/server/internal/admin/application"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/email"
	authpostgres "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/postgres"
	authredis "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/redis"
	authapplication "github.com/Easy-Bao/DrivingApp/server/internal/auth/application"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http"
	documentpostgres "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/adapter/postgres"
	documentapplication "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/application"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/mapbox"
	locationredis "github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/redis"
	locationapplication "github.com/Easy-Bao/DrivingApp/server/internal/location/application"
	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	passengerridecontext "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context"
	passengerridecontextadapter "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context/adapter"
	passengerridecontexthttp "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	storagepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	assignmentadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment/adapter"
	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	chatapplication "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/application"
	chath "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http"
	chatws "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/ws"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/event/adapter"
	geo "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/adapter"
	geoapplication "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/application"
	geoh "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/stream"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
	ridepostgres "github.com/Easy-Bao/DrivingApp/server/internal/ride/adapter/postgres"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
	ridehttp "github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/http"
	userpostgres "github.com/Easy-Bao/DrivingApp/server/internal/user/adapter/postgres"
	userapplication "github.com/Easy-Bao/DrivingApp/server/internal/user/application"
	userhttp "github.com/Easy-Bao/DrivingApp/server/internal/user/transport/http"
	"github.com/go-chi/chi/v5"
	redisclient "github.com/redis/go-redis/v9"
)

func newRouter(config Config, databaseClient *ent.Client, redisClient *redisclient.Client, applicationLogger *slog.Logger) (*chi.Mux, *stream.Hub) {
	verifier := security.NewTokenManager(config.JWTSecret)
	adminAuthorizer := security.NewAdminAuthorizer(config.AdminUserIDs)
	privateObjectStore := storagepostgres.NewObjectStore(databaseClient)

	authRepository := authpostgres.NewUserRepository(databaseClient)
	refreshSessionRepository := authpostgres.NewRefreshSessionRepository(databaseClient)
	registerService := authapplication.NewRegisterService(authRepository, verifier, refreshSessionRepository)
	authenticateService := authapplication.NewAuthenticateService(authRepository, verifier, refreshSessionRepository).WithLogger(applicationLogger)
	otpService := authapplication.NewOTPServiceWithPending(
		authRepository,
		authredis.NewOTPStore(redisClient),
		email.NewGoMailGatewayFromEnv(),
		verifier,
		authredis.NewPendingRegistrationStore(redisClient),
		registerService,
		refreshSessionRepository,
	).WithLogger(applicationLogger)
	authRouter := authhttp.NewRouter(registerService, authenticateService, otpService)

	profileRepository := userpostgres.NewProfileRepository(databaseClient, privateObjectStore).WithLogger(applicationLogger)
	usersRouter := userhttp.NewRouter(userapplication.NewProfileService(profileRepository), verifier)
	documentRouter := documenthttp.NewRouter(
		documentapplication.NewDocumentService(
			documentpostgres.NewDocumentRepository(databaseClient),
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
	ridesRepository := ridepostgres.NewRideRepository(databaseClient, config.Pricing.PlatformCommissionBPS)
	eventHub := stream.NewHub()
	assignmentProjection := assignmentadapter.NewMemoryProjection()
	realtimePublisher := eventadapter.NewMemoryPublisher(assignmentProjection, eventHub)
	ridesService := rideapplication.NewRideServiceWithRouteCalculator(
		ridesRepository,
		routeCalculator,
		config.Pricing,
		realtimePublisher,
	).WithReportingLocation(config.ReportingLocation).WithLogger(applicationLogger)
	rideAssignments := assignment.NewResolver(
		assignmentProjection,
		assignmentadapter.NewRideRepositoryLookup(ridesRepository),
	)

	ridesRouter := ridehttp.NewRouter(ridesService, verifier)
	adminRouter := adminhttp.NewRouter(adminapplication.NewDashboardStatsService(adminpostgres.NewDashboardStatsRepository(databaseClient)), verifier, adminAuthorizer)
	geoService := geoapplication.NewLocationTrackingService(
		geo.NewDriverLocationStore(redisClient).WithLogger(applicationLogger),
		geoapplication.WithRideAssignments(rideAssignments),
		geoapplication.WithEventPublisher(realtimePublisher),
		geoapplication.WithLogger(applicationLogger),
	)
	locationService := locationapplication.NewLocationServiceWithCache(
		mapboxProvider,
		locationredis.NewCache(redisClient),
	).WithLogger(applicationLogger)
	passengerRideContextQuery := passengerridecontext.NewRideContextQueryService(
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

	chatHistory := chatadapter.NewChatHistoryStore(redisClient)
	chatService := chatapplication.NewChatService(chatHistory).
		WithEventPublisher(realtimePublisher).
		WithRideAssignmentLookup(rideAssignments).
		WithLogger(applicationLogger)
	events := ws.NewEventRouter()
	chatEventHandler := chatws.NewEventHandler(chatService)
	events.Register("CHAT_MESSAGE", chatEventHandler)
	events.Register("message", chatEventHandler)
	events.Register("typing", chatEventHandler)
	router.Handle(
		api.V1Prefix+"/chat/ws",
		ws.NewHandlerWithSink(ws.NewHub(), verifier, events, chatService).
			WithAllowedOrigins(config.Security.AllowedOrigins),
	)
	router.Handle(api.V1Prefix+"/realtime/ws", stream.NewHandler(eventHub, verifier, config.Security.AllowedOrigins))
	geoh.NewRouter(geoService, verifier).RegisterRoutes(router)
	chath.NewRouter(chatService, verifier).RegisterRoutes(router)
	registerHealthRoutes(router, databaseClient, redisClient)

	return router, eventHub
}
