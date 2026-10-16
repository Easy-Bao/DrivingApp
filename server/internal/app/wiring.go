package app

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	adminapp "github.com/Easy-Bao/DrivingApp/server/internal/admin/app"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/email"
	authredis "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/redis"
	authauthentication "github.com/Easy-Bao/DrivingApp/server/internal/auth/authentication"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/http"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
	authregistration "github.com/Easy-Bao/DrivingApp/server/internal/auth/registration"
	authverification "github.com/Easy-Bao/DrivingApp/server/internal/auth/verification"
	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/chat/adapter"
	chatapplication "github.com/Easy-Bao/DrivingApp/server/internal/chat/app"
	chathttp "github.com/Easy-Bao/DrivingApp/server/internal/chat/transport/http"
	chatwebsocket "github.com/Easy-Bao/DrivingApp/server/internal/chat/transport/ws"
	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/app"
	assignment "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment"
	dispatchhttp "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/transport/http"
	documentapplication "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/app"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/mapbox"
	locationredis "github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/redis"
	locationapplication "github.com/Easy-Bao/DrivingApp/server/internal/location/app"
	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	tracking "github.com/Easy-Bao/DrivingApp/server/internal/location/tracking"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	passengerridecontext "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/ws"
	reviewapplication "github.com/Easy-Bao/DrivingApp/server/internal/review/app"
	reviewhttp "github.com/Easy-Bao/DrivingApp/server/internal/review/transport/http"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/app"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	ridehttp "github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/http"
	ridewebsocket "github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/ws"
	userapplication "github.com/Easy-Bao/DrivingApp/server/internal/user/app"
	userhttp "github.com/Easy-Bao/DrivingApp/server/internal/user/transport/http"
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
	authports.VerifiedUserStore
	authports.EmailChangeStore
}

type httpRouterDependencies struct {
	config             Config
	postgresPool       *pgxpool.Pool
	redisClient        *redisclient.Client
	applicationLogger  *slog.Logger
	authStore          authRuntimeStore
	sessionStore       authports.SessionStore
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
) (*chi.Mux, *websockethub.Hub, *eventadapter.RedisEventSubscriber) {
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
	emailGateway := email.NewGoMailGateway(config.Mail)
	otpService := authverification.NewOTPService(
		authverification.Dependencies{
			Users:         authStore,
			EmailChanges:  authStore,
			EmailNotifier: emailGateway,
			Store:         authredis.NewOTPStore(redisClient),
			Gateway:       emailGateway,
			Tokens:        verifier,
			Sessions:      sessionStore,
		},
		authverification.WithPendingRegistration(
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
	eventPublisher, eventSubscriber := eventadapter.NewRedisEventTransport(
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
	trackingService := tracking.NewLocationTrackingService(
		tracking.LocationTrackingDependencies{
			Repository: tracking.NewDriverLocationStore(redisClient).WithLogger(applicationLogger),
			MaxAge:     config.RideLifecycle.DriverLocationMaxAge,
		},
		tracking.WithRideAssignments(rideAssignments),
		tracking.WithDriverPresence(tracking.DriverPresenceReaderFunc(
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
		tracking.WithEventPublisher(eventPublisher),
		tracking.WithLogger(applicationLogger),
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
		locationapplication.LocationServiceDependencies{Provider: mapboxProvider},
		locationapplication.WithCache(locationredis.NewCache(redisClient)),
	).WithLogger(applicationLogger)
	passengerRideContextQuery := passengerridecontext.NewQueryService(
		passengerridecontext.QueryDependencies{
			RecentDestinations: passengerridecontext.NewRidesReader(ridesService),
			AddressResolver:    passengerridecontext.NewLocationResolver(locationService),
		},
	).WithLogger(applicationLogger)

	router := chi.NewRouter()
	router.NotFound(routeSecurity.Middleware(middleware.RouteDefault)(http.NotFoundHandler()).ServeHTTP)
	router.MethodNotAllowed(routeSecurity.Middleware(middleware.RouteDefault)(http.HandlerFunc(
		func(writer http.ResponseWriter, _ *http.Request) {
			writer.WriteHeader(http.StatusMethodNotAllowed)
		},
	)).ServeHTTP)
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
	passengerridecontext.NewRouter(passengerridecontext.Dependencies{
		Query:         passengerRideContextQuery,
		Verifier:      verifier,
		RouteSecurity: routeSecurity,
	}).RegisterRoutes(router)

	chatRoomStore := chatadapter.NewChatHistoryStore(redisClient)
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
	tracking.NewRouter(tracking.Dependencies{
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
