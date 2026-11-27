package app

import (
	"context"
	"fmt"
	"net/http"
	"strconv"

	adminapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/app"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/adapter/email"
	authredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/adapter/redis"
	authapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/transport/http"
	chatredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/adapter/redis"
	chatapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	dispatchhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/transport/http"
	dispatchwebsocket "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/transport/ws"
	documentapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/driver/app"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/driver/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/places/adapter/mapbox"
	placesredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/adapter/redis"
	placesapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/app"
	placesdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/domain"
	reviewapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/review/app"
	reviewhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/review/transport/http"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	ridehttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/transport/http"
	ridewebsocket "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/transport/ws"
	trackingredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/adapter/redis"
	trackingapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/app"
	userapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/user/app"
	userhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/user/transport/http"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/ws"
)

type applicationModules struct {
	verifier                  *security.TokenManager
	authRouter                *authhttp.Router
	usersRouter               *userhttp.Router
	documentRouter            *documenthttp.Router
	ridesRouter               *ridehttp.Router
	dispatchRouter            *dispatchhttp.Router
	reviewRouter              *reviewhttp.Router
	adminRouter               *adminhttp.Router
	locationService           *placesapplication.Service
	passengerRideContextQuery *rideapplication.QueryService
	trackingService           *trackingapplication.TrackingService
	chatService               *chatapplication.Service
	eventHub                  *websockethub.Hub
	eventSubscriber           *eventadapter.DistributedSubscriber
}

func buildApplicationModules(dependencies httpRouterDependencies) applicationModules {
	config := dependencies.config
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
			Store:         authredis.NewOTPStore(redisClient).WithHashSecret(config.JWTSecret),
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

	driverPresenceCache := trackingredis.NewDriverPresenceCache(
		redisClient,
		profileStore.IsDriverOnline,
		config.RideLifecycle.DriverLocationMaxAge,
		applicationLogger,
	)

	usersRouter := userhttp.NewRouter(
		userhttp.Dependencies{
			Service: userapplication.NewProfileService(
				userapplication.ProfileServiceDependencies{
					Repository:    profileStore,
					Avatars:       profileStore,
					Notifications: profileStore,
					PresenceCache: driverPresenceCache,
				},
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
	routeCalculator := rideapplication.RouteProviderFunc(
		func(
			ctx context.Context,
			originLatitude float64,
			originLongitude float64,
			destinationLatitude float64,
			destinationLongitude float64,
		) (rideapplication.RouteMetrics, error) {
			route, err := routingProvider.Route(
				ctx,
				placesdomain.Coordinates{Latitude: originLatitude, Longitude: originLongitude},
				placesdomain.Coordinates{Latitude: destinationLatitude, Longitude: destinationLongitude},
				placesdomain.RouteOptions{
					Profile: placesdomain.RouteProfileDrivingTraffic,
				},
			)
			if err != nil {
				return rideapplication.RouteMetrics{}, fmt.Errorf("calculate route metrics: %w", err)
			}
			return rideapplication.RouteMetrics{DistanceKm: route.DistanceKm, DurationMinutes: route.DurationMin}, nil
		},
	)
	eventHub := websockethub.NewHub()
	assignmentProjection := dispatchapplication.NewMemoryProjection()
	eventPublisher, eventSubscriber := eventadapter.NewDistributedTransport(
		redisClient,
		assignmentProjection,
		eventHub,
	)
	eventSubscriber.WithLogger(applicationLogger)
	rideEventPublisher := ridewebsocket.NewEventPublisher(eventPublisher)
	dispatchEventPublisher := dispatchwebsocket.NewEventPublisher(eventPublisher)
	rideAssignments := dispatchapplication.NewResolver(
		dispatchapplication.ResolverDependencies{
			Routing:       assignmentProjection,
			CachedRouting: assignmentProjection,
			Projection:    assignmentProjection,
			Authority:     dispatchapplication.NewRideLookup(rideStore),
		},
	)
	trackingService := trackingapplication.NewTrackingService(
		trackingapplication.TrackingDependencies{
			Repository: trackingredis.NewDriverLocationStore(redisClient).
				WithTTL(config.RideLifecycle.DriverLocationMaxAge).
				WithLogger(applicationLogger),
			MaxAge: config.RideLifecycle.DriverLocationMaxAge,
		},
		trackingapplication.WithRideAssignments(&trackingAssignmentAdapter{resolver: rideAssignments}),
		trackingapplication.WithDriverPresence(driverPresenceCache),
		trackingapplication.WithEventPublisher(eventPublisher),
		trackingapplication.WithLogger(applicationLogger),
	)
	ridesService := rideapplication.NewService(
		rideapplication.Dependencies{
			Repository:        rideStore,
			ActiveRideChecker: rideStore,
			Lifecycle:         rideStore,
			Settlement:        rideStore,
			Counterparties:    rideStore,
			History:           rideStore,
			RecentRides:       rideStore,
			PassengerActivity: rideStore,
			DriverEarnings:    rideStore,
			DriverStats:       rideStore,
			SafetyReports:     rideStore,
			PricingConfig:     config.Pricing,
			EventPublisher:    rideEventPublisher,
			LifecycleConfig:   config.RideLifecycle,
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
		EventPublisher: dispatchEventPublisher,
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
	locationService := placesapplication.NewService(
		placesapplication.Dependencies{Provider: routingProvider},
		placesapplication.WithCache(placesredis.NewCache(redisClient)),
	).WithLogger(applicationLogger)
	passengerRideContextQuery := rideapplication.NewQueryService(
		rideapplication.QueryDependencies{
			RecentDestinations: rideapplication.NewRidesReader(ridesService),
			AddressResolver:    newLocationResolver(locationService),
		},
	).WithLogger(applicationLogger)

	chatRoomStore := dependencies.chatStore
	if chatRoomStore == nil {
		chatRoomStore = chatredis.NewHistoryStore(redisClient)
	}
	chatService := chatapplication.NewService(chatapplication.Dependencies{History: chatRoomStore, Images: privateObjectStore}).
		WithEventPublisher(eventPublisher).
		WithRideAssignmentLookup(chatapplication.RideAssignmentLookupFunc(
			func(ctx context.Context, rideID string) (chatapplication.RideAssignment, bool, error) {
				a, found, err := rideAssignments.ForRide(ctx, rideID)
				if err != nil || !found {
					return chatapplication.RideAssignment{}, found, err
				}
				return chatapplication.RideAssignment{
					RideID:      a.RideID,
					DriverID:    a.DriverID,
					PassengerID: a.PassengerID,
					Status:      a.Status,
					ContactOpen: a.ContactOpen,
					CompletedAt: a.CompletedAt,
				}, true, nil
			},
		)).
		WithLogger(applicationLogger)

	return applicationModules{
		verifier:                  verifier,
		authRouter:                authRouter,
		usersRouter:               usersRouter,
		documentRouter:            documentRouter,
		ridesRouter:               ridesRouter,
		dispatchRouter:            dispatchRouter,
		reviewRouter:              reviewRouter,
		adminRouter:               adminRouter,
		locationService:           locationService,
		passengerRideContextQuery: passengerRideContextQuery,
		trackingService:           trackingService,
		chatService:               chatService,
		eventHub:                  eventHub,
		eventSubscriber:           eventSubscriber,
	}
}

type trackingAssignmentAdapter struct {
	resolver *dispatchapplication.Resolver
}

func (adapter *trackingAssignmentAdapter) ForDriver(
	ctx context.Context,
	driverID string,
) ([]trackingapplication.RideAssignment, error) {
	items, err := adapter.resolver.ForDriver(ctx, driverID)
	if err != nil {
		return nil, err
	}
	result := make([]trackingapplication.RideAssignment, 0, len(items))
	for _, item := range items {
		result = append(result, trackingapplication.RideAssignment{
			RideID:      item.RideID,
			DriverID:    item.DriverID,
			PassengerID: item.PassengerID,
			Status:      item.Status,
		})
	}
	return result, nil
}

func (adapter *trackingAssignmentAdapter) ForRide(
	ctx context.Context,
	rideID string,
) (trackingapplication.RideAssignment, bool, error) {
	item, found, err := adapter.resolver.ForRide(ctx, rideID)
	if err != nil || !found {
		return trackingapplication.RideAssignment{}, found, err
	}
	return trackingapplication.RideAssignment{
		RideID:      item.RideID,
		DriverID:    item.DriverID,
		PassengerID: item.PassengerID,
		Status:      item.Status,
	}, true, nil
}
