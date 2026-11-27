package app

import (
	"context"
	"log/slog"
	"time"

	adminapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/app"
	authapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	chatapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	documentapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/driver/app"
	reviewapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/review/app"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	userapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/user/app"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/ws"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	redisclient "github.com/redis/go-redis/v9"
)

type rideRuntimeStore interface {
	rideapplication.RideStore
	rideapplication.PassengerActiveRideChecker
	rideapplication.RideLifecycleStore
	rideapplication.CashSettlementStore
	rideapplication.CounterpartyReader
	rideapplication.RideHistoryReader
	rideapplication.RecentPassengerRidesReader
	rideapplication.PassengerActivityReader
	rideapplication.DriverEarningsReader
	rideapplication.DriverStatisticsReader
	rideapplication.SafetyReportStore
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

type profileRuntimeStore interface {
	userapplication.ProfileStore
	userapplication.AvatarStore
	userapplication.NotificationStore
	IsDriverOnline(ctx context.Context, userID int, maxAge time.Duration) (bool, error)
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
	profileStore       profileRuntimeStore
	statsReader        adminapp.StatsReader
	documentStore      documentapplication.DocumentStore
	chatStore          chatapplication.RoomStore
	privateObjectStore platformstorage.ObjectStore
	otpAttemptStore    middleware.CounterStore
	routeSecurity      *middleware.RouteSecurity
}

func newHTTPRouter(
	dependencies httpRouterDependencies,
) (*chi.Mux, *websockethub.Hub, *eventadapter.DistributedSubscriber) {
	modules := buildApplicationModules(dependencies)
	router := registerApplicationRoutes(dependencies, modules)
	return router, modules.eventHub, modules.eventSubscriber
}
