package bootstrap

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	adminpostgres "github.com/Easy-Bao/DrivingApp/server/internal/admin/adapter/postgres"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http"
	adminusecase "github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/email"
	authpostgres "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/postgres"
	authredis "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/redis"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http"
	authusecase "github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	documentpostgres "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/adapter/postgres"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http"
	documentusecase "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/mapbox"
	locationredis "github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/redis"
	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	locationusecase "github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	passengerridecontext "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context"
	passengerridecontextadapter "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context/adapter"
	passengerridecontexthttp "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	storagepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	assignmentadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment/adapter"
	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	chath "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http"
	chatws "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/ws"
	chatusecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/event/adapter"
	geo "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/adapter"
	geoh "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http"
	geousecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/stream"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
	ridespostgres "github.com/Easy-Bao/DrivingApp/server/internal/rides/adapter/postgres"
	rideshttp "github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http"
	ridesusecase "github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	userspostgres "github.com/Easy-Bao/DrivingApp/server/internal/users/adapter/postgres"
	usershttp "github.com/Easy-Bao/DrivingApp/server/internal/users/transport/http"
	usersusecase "github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"github.com/go-chi/chi/v5"
	redisclient "github.com/redis/go-redis/v9"
)

func newRouter(config Config, databaseClient *ent.Client, redisClient *redisclient.Client) (*chi.Mux, *stream.Hub) {
	verifier := security.NewTokenManager(config.JWTSecret)
	adminAuthorizer := security.NewAdminAuthorizer(config.AdminUserIDs)
	privateObjectStore := storagepostgres.NewObjectStore(databaseClient)

	authRepository := authpostgres.NewUserRepository(databaseClient)
	refreshSessionRepository := authpostgres.NewRefreshSessionRepository(databaseClient)
	registerService := authusecase.NewRegisterService(authRepository, verifier, refreshSessionRepository)
	authenticateService := authusecase.NewAuthenticateService(authRepository, verifier, refreshSessionRepository)
	authRouter := authhttp.NewRouter(registerService, authenticateService, authusecase.NewOTPServiceWithPending(
		authRepository,
		authredis.NewOTPStore(redisClient),
		email.NewGoMailGatewayFromEnv(),
		verifier,
		authredis.NewPendingRegistrationStore(redisClient),
		registerService,
		refreshSessionRepository,
	))

	usersRouter := usershttp.NewRouter(
		usersusecase.NewProfileService(userspostgres.NewProfileRepository(databaseClient, privateObjectStore)),
		verifier,
	)
	documentRouter := documenthttp.NewRouter(
		documentusecase.NewDocumentService(
			documentpostgres.NewRepository(databaseClient),
			privateObjectStore,
			config.Security.UploadBodyLimit,
		),
		verifier,
		adminAuthorizer,
	)

	mapboxProvider := mapbox.NewProvider(config.MapboxAccessToken)
	routeCalculator := ridesusecase.RouteCalculatorFunc(func(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (ridesusecase.RouteMetrics, error) {
		route, err := mapboxProvider.Route(ctx, locationdomain.Coordinates{Latitude: originLat, Longitude: originLng}, locationdomain.Coordinates{Latitude: destinationLat, Longitude: destinationLng}, locationdomain.RouteOptions{})
		if err != nil {
			return ridesusecase.RouteMetrics{}, err
		}
		return ridesusecase.RouteMetrics{DistanceKm: route.DistanceKm, DurationMinutes: route.DurationMin}, nil
	})
	ridesRepository := ridespostgres.NewRepository(databaseClient, config.Pricing.PlatformCommissionBPS)
	eventHub := stream.NewHub()
	assignmentProjection := assignmentadapter.NewMemoryProjection()
	realtimePublisher := eventadapter.NewMemoryPublisher(assignmentProjection, eventHub)
	ridesService := ridesusecase.NewRideServiceWithRouteCalculator(
		ridesRepository,
		routeCalculator,
		config.Pricing,
		realtimePublisher,
	).WithReportingLocation(config.ReportingLocation)
	rideAssignments := assignment.NewResolver(
		assignmentProjection,
		assignmentadapter.NewRideRepositoryLookup(ridesRepository),
	)

	ridesRouter := rideshttp.NewRouter(ridesService, verifier)
	adminRouter := adminhttp.NewRouter(adminusecase.NewDashboardStatsService(adminpostgres.NewRepository(databaseClient)), verifier, adminAuthorizer)
	geoService := geousecase.NewLocationTrackingService(
		geo.NewRedisRepository(redisClient),
		geousecase.WithRideAssignments(rideAssignments),
		geousecase.WithEventPublisher(realtimePublisher),
	)
	locationService := locationusecase.NewLocationServiceWithCache(
		mapboxProvider,
		locationredis.NewCache(redisClient),
	)
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

	chatHistory := chatadapter.NewRedisRepository(redisClient)
	chatService := chatusecase.NewChatService(chatadapter.NewHub(), chatHistory).
		WithEventPublisher(realtimePublisher).
		WithRideAssignmentLookup(rideAssignments)
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
