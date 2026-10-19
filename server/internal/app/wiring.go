package app

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	adminapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/app"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/adapter/email"
	authredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/adapter/redis"
	authapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/transport/http"
	chatredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/adapter/redis"
	chatapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	chathttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/transport/http"
	chatwebsocket "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/transport/ws"
	assignment "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	dispatchhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/transport/http"
	documentapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/driver/app"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/driver/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/location/adapter/mapbox"
	locationredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/adapter/redis"
	locationapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/app"
	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/transport/http"
	reviewapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/review/app"
	reviewhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/review/transport/http"
	ridepostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/adapter/postgres"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	ridehttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/transport/http"
	ridewebsocket "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/transport/ws"
	userapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/user/app"
	userhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/user/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/ws"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	redisclient "github.com/redis/go-redis/v9"
)

type rideRuntimeStore interface {
	rideapplication.RideStore
	ActiveRidesForDriver(context.Context, int) ([]ridedomain.Ride, error)
}

type dispatchRuntimeStore interface {
	dispatchapplication.BiddingStore
	dispatchapplication.DriverAvailabilityReader
}

type authRuntimeStore interface {
	authapp.VerifiedUserStore
	authapp.EmailChangeStore
}

type httpRouterDependencies struct {
	config             Config
	postgresPool       *pgxpool.Pool
	redisClient        *redisclient.Client
	applicationLogger  *slog.Logger
	authStore          authRuntimeStore
	sessionStore       authapp.SessionStore
	rideStore          rideRuntimeStore
	dispatchStore      dispatchRuntimeStore
	reviewStore        reviewapplication.ReviewRepository
	profileStore       userapplication.ProfileStore
	statsReader        adminapp.StatsReader
	documentStore      documentapplication.DocumentStore
	privateObjectStore platformstorage.ObjectStore
	otpAttemptStore    middleware.CounterStore
	routeSecurity      *middleware.RouteSecurity
}

func newHTTPRouter(
	dependencies httpRouterDependencies,
) (*chi.Mux, *websockethub.Hub, *eventadapter.DistributedEventSubscriber) {
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
	routeSecurity := dependencies.routeSecurity

	verifier := security.NewTokenManager(config.JWTSecret)
	adminAuthorizer := security.NewAdminAuthorizer(config.AdminUserIDs)

	registerService := authapp.NewRegisterService(authapp.RegisterDependencies{
		Repository: authStore,
		Tokens:     verifier,
		Sessions:   sessionStore,
	})
	authenticateService := authapp.NewAuthenticateService(
		authapp.AuthenticateDependencies{
			Repository: authStore,
			Tokens:     verifier,
			Sessions:   sessionStore,
		},
	).WithLogger(applicationLogger)
	emailGateway := email.NewMailGateway(config.Mail)
	otpService := authapp.NewOTPService(
		authapp.OTPDependencies{
			Users:         authStore,
			EmailChanges:  authStore,
			EmailNotifier: emailGateway,
			Store:         authredis.NewOTPStore(redisClient),
			Gateway:       emailGateway,
			Tokens:        verifier,
			Sessions:      sessionStore,
		},
		authapp.WithPendingRegistration(
			authredis.NewPendingRegistrationStore(redisClient),
			registerService,
		),
	).WithLogger(applicationLogger)
	authRouter := authhttp.NewRouter(
		authhttp.RouterDependencies{
			Register:      registerService,
			Authenticate:  authenticateService,
			OTP:           otpService,
			Verifier:      verifier,
			RouteSecurity: routeSecurity,
		},
		authhttp.WithOTPAttemptStore(dependencies.otpAttemptStore),
	)

	usersRouter := userhttp.NewRouter(
		userhttp.Dependencies{
			Service: userapplication.NewProfileService(
				userapplication.ProfileServiceDependencies{Repository: profileStore},
				userapplication.WithContentTypeDetector(http.DetectContentType),
			),
			Verifier:      verifier,
			RouteSecurity: routeSecurity,
		},
	)
	documentRouter := documenthttp.NewRouter(documenthttp.RouterDependencies{
		Service: documentapplication.NewDocumentService(
			documentapplication.DocumentServiceDependencies{
				Repository: documentStore,
				Storage:    privateObjectStore,
			},
			documentapplication.WithContentTypeDetector(http.DetectContentType),
			documentapplication.WithMaxDocumentBytes(config.Security.UploadBodyLimit),
		),
		Verifier:      verifier,
		Authorizer:    adminAuthorizer,
		RouteSecurity: routeSecurity,
	})

	routingProvider := mapbox.NewRoutingProvider(config.MapboxAccessToken)
	routeCalculator := rideapplication.RouteCalculatorFunc(
		func(
			ctx context.Context,
			originLat float64,
			originLng float64,
			destinationLat float64,
			destinationLng float64,
		) (rideapplication.RouteMetrics, error) {
			route, err := routingProvider.Route(
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
	eventPublisher, eventSubscriber := eventadapter.NewDistributedEventTransport(
		redisClient,
		assignmentProjection,
		eventHub,
	)
	eventSubscriber.WithLogger(applicationLogger)
	rideEventPublisher := ridewebsocket.NewEventPublisher(eventPublisher)
	rideAssignments := assignment.NewResolver(
		assignment.ResolverDependencies{
			Routing:   assignmentProjection,
			Authority: assignment.NewRideLookup(rideStore),
		},
	)
	trackingService := locationapplication.NewLocationTrackingService(
		locationapplication.LocationTrackingDependencies{
			Repository: locationredis.NewDriverLocationStore(redisClient).WithLogger(applicationLogger),
			MaxAge:     config.RideLifecycle.DriverLocationMaxAge,
		},
		locationapplication.WithRideAssignments(rideAssignments),
		locationapplication.WithDriverPresence(locationapplication.DriverPresenceReaderFunc(
			func(ctx context.Context, driverID string) (bool, error) {
				parsedDriverID, err := strconv.Atoi(driverID)
				if err != nil {
					return false, fmt.Errorf("parse driver id: %w", err)
				}
				profile, err := profileStore.Get(ctx, parsedDriverID)
				if err != nil {
					return false, err
				}
				if profile.Role != "driver" || !profile.IsOnline || profile.OnlineLastSeenAt == nil {
					return false, nil
				}
				maxAge := config.RideLifecycle.DriverLocationMaxAge
				if maxAge <= 0 {
					maxAge = 45 * time.Second
				}
				return time.Since(*profile.OnlineLastSeenAt) <= maxAge, nil
			},
		)),
		locationapplication.WithEventPublisher(eventPublisher),
		locationapplication.WithLogger(applicationLogger),
	)
	ridesService := rideapplication.NewRideService(
		rideapplication.RideServiceDependencies{
			Repository:      rideStore,
			PricingConfig:   config.Pricing,
			EventPublisher:  rideEventPublisher,
			LifecycleConfig: config.RideLifecycle,
			DriverLocation: rideapplication.DriverLocationReaderFunc(
				func(ctx context.Context, driverID int) (rideapplication.DriverLocation, error) {
					point, err := trackingService.Get(ctx, strconv.Itoa(driverID))
					if err != nil {
						return rideapplication.DriverLocation{}, err
					}
					if point.DriverID != strconv.Itoa(driverID) {
						return rideapplication.DriverLocation{}, fmt.Errorf("driver location identity mismatch")
					}
					return rideapplication.DriverLocation{
						Latitude:   point.Latitude,
						Longitude:  point.Longitude,
						ObservedAt: point.ObservedAt,
					}, nil
				},
			),
		},
		rideapplication.WithRouteCalculator(routeCalculator),
	).WithReportingLocation(config.ReportingLocation).WithLogger(applicationLogger)
	dispatchService := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store: dependencies.dispatchStore,
		ResolveRoute: func(
			ctx context.Context,
			pickupLatitude float64,
			pickupLongitude float64,
			dropoffLatitude float64,
			dropoffLongitude float64,
			distanceKm float64,
			durationMinutes float64,
		) (dispatchapplication.RouteMetrics, error) {
			metrics, _, err := ridesService.Fare(
				ctx,
				&pickupLatitude,
				&pickupLongitude,
				&dropoffLatitude,
				&dropoffLongitude,
				distanceKm,
				durationMinutes,
			)
			if err != nil {
				return dispatchapplication.RouteMetrics{}, err
			}
			return dispatchapplication.RouteMetrics{
				DistanceKm:      metrics.DistanceKm,
				DurationMinutes: metrics.DurationMinutes,
			}, nil
		},
		CalculateFare:  config.Pricing.FareAmount,
		EventPublisher: rideEventPublisher,
		Config:         config.Bidding,
	}).WithLogger(applicationLogger)
	dispatchAvailability := dispatchapplication.NewAvailabilityService(dependencies.dispatchStore)

	ridesRouter := ridehttp.NewRouter(ridehttp.Dependencies{
		Service:       ridesService,
		Verifier:      verifier,
		RouteSecurity: routeSecurity,
	})
	dispatchRouter := dispatchhttp.NewRouter(dispatchhttp.Dependencies{
		Service:       dispatchService,
		Availability:  dispatchAvailability,
		Verifier:      verifier,
		RouteSecurity: routeSecurity,
	})
	reviewRouter := reviewhttp.NewRouter(reviewhttp.Dependencies{
		Service:       reviewapplication.NewService(dependencies.reviewStore),
		Verifier:      verifier,
		RouteSecurity: routeSecurity,
	})
	adminRouter := adminhttp.NewRouter(adminhttp.RouterDependencies{
		Service:    adminapp.NewStatsService(statsReader),
		Verifier:   verifier,
		Authorizer: adminAuthorizer,
	})
	locationService := locationapplication.NewLocationService(
		locationapplication.LocationServiceDependencies{Provider: routingProvider},
		locationapplication.WithCache(locationredis.NewCache(redisClient)),
	).WithLogger(applicationLogger)
	passengerRideContextQuery := rideapplication.NewQueryService(
		rideapplication.QueryDependencies{
			RecentDestinations: ridepostgres.NewRidesReader(ridesService),
			AddressResolver:    rideapplication.NewLocationResolver(locationService),
		},
	).WithLogger(applicationLogger)

	router := chi.NewRouter()
	router.NotFound(notFoundHandler(routeSecurity).ServeHTTP)
	router.MethodNotAllowed(methodNotAllowedHandler(routeSecurity).ServeHTTP)
	authRouter.RegisterRoutes(router)
	usersRouter.RegisterRoutes(router)
	documentRouter.RegisterRoutes(router)
	ridesRouter.RegisterRoutes(router)
	dispatchRouter.RegisterRoutes(router)
	reviewRouter.RegisterRoutes(router)
	router.With(routeSecurity.Middleware(middleware.RouteRead)).Group(func(admin chi.Router) {
		adminRouter.RegisterRoutes(admin)
	})
	locationhttp.NewRouter(locationService, verifier, routeSecurity).RegisterRoutes(router)
	ridehttp.NewPassengerContextRouter(ridehttp.PassengerContextDependencies{
		Query:         passengerRideContextQuery,
		Verifier:      verifier,
		RouteSecurity: routeSecurity,
	}).RegisterRoutes(router)

	chatRoomStore := chatredis.NewChatHistoryStore(redisClient)
	chatService := chatapplication.NewChatService(chatapplication.ChatServiceDependencies{History: chatRoomStore}).
		WithEventPublisher(eventPublisher).
		WithRideAssignmentLookup(rideAssignments).
		WithLogger(applicationLogger)
	chatEventHandler := chatwebsocket.NewEventHandler(chatService)
	chatProtocol := chatwebsocket.NewConnectionProtocol(chatEventHandler, chatService)
	router.Handle(
		api.V1Prefix+"/chat/ws",
		routeSecurity.Middleware(middleware.RouteRealtimeConnection)(websockethub.NewHandler(
			websockethub.HandlerDependencies{
				Hub:           eventHub,
				Authenticator: verifier,
				Protocol:      chatProtocol,
			},
			websockethub.WithAllowedOrigins(config.Security.AllowedOrigins),
			websockethub.WithLogger(applicationLogger),
		)),
	)
	router.Handle(
		api.V1Prefix+"/realtime/ws",
		routeSecurity.Middleware(middleware.RouteRealtimeConnection)(websockethub.NewHandler(
			websockethub.HandlerDependencies{
				Hub:           eventHub,
				Authenticator: verifier,
			},
			websockethub.WithAllowedOrigins(config.Security.AllowedOrigins),
			websockethub.WithLogger(applicationLogger),
		)),
	)
	locationhttp.NewTrackingRouter(locationhttp.TrackingDependencies{
		Service:       trackingService,
		Auth:          verifier,
		RouteSecurity: routeSecurity,
	}).RegisterRoutes(router)
	chathttp.NewRouter(chathttp.Dependencies{
		Service:       chatService,
		Verifier:      verifier,
		RouteSecurity: routeSecurity,
	}).RegisterRoutes(router)
	registerHealthRoutes(router, redisClient, postgresPool, routeSecurity)

	return router, eventHub, eventSubscriber
}

func notFoundHandler(routeSecurity *middleware.RouteSecurity) http.Handler {
	handler := http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		response.Error(writer, http.StatusNotFound, "Resource not found.")
	})
	if routeSecurity == nil {
		return handler
	}
	return routeSecurity.Middleware(middleware.RouteDefault)(handler)
}

func methodNotAllowedHandler(routeSecurity *middleware.RouteSecurity) http.Handler {
	handler := http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		response.Error(writer, http.StatusMethodNotAllowed, "Method not allowed.")
	})
	if routeSecurity == nil {
		return handler
	}
	return routeSecurity.Middleware(middleware.RouteDefault)(handler)
}
