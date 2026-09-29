package app

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"

	adminapplication "github.com/Easy-Bao/DrivingApp/server/internal/admin/application"
	adminports "github.com/Easy-Bao/DrivingApp/server/internal/admin/ports"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/email"
	authredis "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/redis"
	authauthentication "github.com/Easy-Bao/DrivingApp/server/internal/auth/authentication"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/http"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
	authregistration "github.com/Easy-Bao/DrivingApp/server/internal/auth/registration"
	authverification "github.com/Easy-Bao/DrivingApp/server/internal/auth/verification"
	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/chat/adapter"
	chatapplication "github.com/Easy-Bao/DrivingApp/server/internal/chat/application"
	chathttp "github.com/Easy-Bao/DrivingApp/server/internal/chat/transport/http"
	chatws "github.com/Easy-Bao/DrivingApp/server/internal/chat/transport/ws"
	assignment "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment"
	documents "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/mapbox"
	locationredis "github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/redis"
	locationapplication "github.com/Easy-Bao/DrivingApp/server/internal/location/application"
	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	tracking "github.com/Easy-Bao/DrivingApp/server/internal/location/tracking"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	passengerridecontext "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/platform/events/adapter"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
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

type httpRouterDependencies struct {
	config             Config
	postgresPool       *pgxpool.Pool
	redisClient        *redisclient.Client
	applicationLogger  *slog.Logger
	authStore          authports.VerifiedUserStore
	sessionStore       authports.SessionStore
	rideStore          rideRuntimeStore
	profileStore       userports.ProfileStore
	statsReader        adminports.StatsReader
	documentStore      documents.DocumentStore
	privateObjectStore platformstorage.ObjectStore
	otpAttemptStore    middleware.CounterStore
}

func newHTTPRouter(dependencies httpRouterDependencies) (*chi.Mux, *websockethub.Hub) {
	config := dependencies.config
	postgresPool := dependencies.postgresPool
	redisClient := dependencies.redisClient
	applicationLogger := dependencies.applicationLogger
	authStore := dependencies.authStore
	sessionStore := dependencies.sessionStore
	rideStore := dependencies.rideStore
	profileStore := dependencies.profileStore
	statsReader := dependencies.statsReader
	documentStore := dependencies.documentStore
	privateObjectStore := dependencies.privateObjectStore

	verifier := security.NewTokenManager(config.JWTSecret)
	adminAuthorizer := security.NewAdminAuthorizer(config.AdminUserIDs)

	registerService := authregistration.NewRegisterService(authregistration.Dependencies{
		Repository: authStore,
		Tokens:     verifier,
		Sessions:   sessionStore,
	})
	authenticateService := authauthentication.NewAuthenticateService(
		authauthentication.Dependencies{
			Repository: authStore,
			Tokens:     verifier,
			Sessions:   sessionStore,
		},
	).WithLogger(applicationLogger)
	otpService := authverification.NewOTPService(
		authverification.Dependencies{
			Users:    authStore,
			Store:    authredis.NewOTPStore(redisClient),
			Gateway:  email.NewGoMailGatewayFromEnv(),
			Tokens:   verifier,
			Sessions: sessionStore,
		},
		authverification.WithPendingRegistration(
			authredis.NewPendingRegistrationStore(redisClient),
			registerService,
		),
	).WithLogger(applicationLogger)
	authRouter := authhttp.NewRouter(
		registerService,
		authenticateService,
		otpService,
		authhttp.WithOTPAttemptStore(dependencies.otpAttemptStore),
	)

	usersRouter := userhttp.NewRouter(
		userapplication.NewProfileService(
			profileStore,
			userapplication.WithContentTypeDetector(http.DetectContentType),
		),
		verifier,
	)
	documentRouter := documents.NewRouter(
		documents.NewDocumentService(
			documentStore,
			privateObjectStore,
			documents.WithContentTypeDetector(http.DetectContentType),
			documents.WithMaxDocumentBytes(config.Security.UploadBodyLimit),
		),
		verifier,
		adminAuthorizer,
	)

	mapboxProvider := mapbox.NewMapboxProvider(config.MapboxAccessToken)
	routeCalculator := rideapplication.RouteCalculatorFunc(
		func(
			ctx context.Context,
			originLat float64,
			originLng float64,
			destinationLat float64,
			destinationLng float64,
		) (rideapplication.RouteMetrics, error) {
			route, err := mapboxProvider.Route(
				ctx,
				locationdomain.Coordinates{Latitude: originLat, Longitude: originLng},
				locationdomain.Coordinates{Latitude: destinationLat, Longitude: destinationLng},
				locationdomain.RouteOptions{
					Profile: locationdomain.RouteProfileDrivingTraffic,
				},
			)
			if err != nil {
				return rideapplication.RouteMetrics{}, fmt.Errorf("calculate route metrics: %w", err)
			}
			return rideapplication.RouteMetrics{DistanceKm: route.DistanceKm, DurationMinutes: route.DurationMin}, nil
		},
	)
	eventHub := websockethub.NewHub()
	assignmentProjection := assignment.NewMemoryProjection()
	eventPublisher := eventadapter.NewMemoryPublisher(assignmentProjection, eventHub)
	ridesService := rideapplication.NewRideService(
		rideapplication.RideServiceDependencies{
			Repository:     rideStore,
			PricingConfig:  config.Pricing,
			EventPublisher: eventPublisher,
		},
		rideapplication.WithRouteCalculator(routeCalculator),
	).WithReportingLocation(config.ReportingLocation).WithLogger(applicationLogger)
	rideAssignments := assignment.NewResolver(
		assignment.ResolverDependencies{
			Routing:   assignmentProjection,
			Authority: assignment.NewRideLookup(rideStore),
		},
	)

	ridesRouter := ridehttp.NewRouter(ridesService, verifier)
	adminRouter := adminhttp.NewRouter(adminapplication.NewStatsService(statsReader), verifier, adminAuthorizer)
	trackingService := tracking.NewLocationTrackingService(
		tracking.NewDriverLocationStore(redisClient).WithLogger(applicationLogger),
		tracking.WithRideAssignments(rideAssignments),
		tracking.WithEventPublisher(eventPublisher),
		tracking.WithLogger(applicationLogger),
	)
	locationService := locationapplication.NewLocationService(
		mapboxProvider,
		locationapplication.WithCache(locationredis.NewCache(redisClient)),
	).WithLogger(applicationLogger)
	passengerRideContextQuery := passengerridecontext.NewQueryService(
		passengerridecontext.QueryDependencies{
			RecentDestinations: passengerridecontext.NewRidesReader(ridesService),
			AddressResolver:    passengerridecontext.NewLocationResolver(locationService),
		},
	).WithLogger(applicationLogger)

	router := chi.NewRouter()
	authRouter.RegisterRoutes(router)
	usersRouter.RegisterRoutes(router)
	documentRouter.RegisterRoutes(router)
	ridesRouter.RegisterRoutes(router)
	adminRouter.RegisterRoutes(router)
	locationhttp.NewRouter(locationService).RegisterRoutes(router)
	passengerridecontext.NewRouter(passengerRideContextQuery, verifier).RegisterRoutes(router)

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
		chatws.NewHandler(
			chatws.NewRoomHub(),
			verifier,
			chatws.WithEventSink(chatEventRouter),
			chatws.WithRoomAuthorizer(chatService),
		).
			WithAllowedOrigins(config.Security.AllowedOrigins),
	)
	router.Handle(
		api.V1Prefix+"/realtime/ws",
		websockethub.NewHandler(
			eventHub,
			verifier,
			websockethub.WithAllowedOrigins(config.Security.AllowedOrigins),
		),
	)
	tracking.NewRouter(trackingService, verifier).RegisterRoutes(router)
	chathttp.NewRouter(chatService, verifier).RegisterRoutes(router)
	registerHealthRoutes(router, redisClient, postgresPool)

	return router, eventHub
}
