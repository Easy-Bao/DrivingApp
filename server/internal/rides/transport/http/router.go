package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	"github.com/go-chi/chi/v5"
)

type Router struct {
	handler  *handler.Handler
	verifier *token.Verifier
}

func NewRouter(service *usecase.Service, verifier *token.Verifier) *Router {
	return &Router{handler: handler.NewHandler(service, verifier), verifier: verifier}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	apiPrefix := api.V1Prefix
	mux.Post(apiPrefix+"/bids/fare", router.handler.Estimate)
	mux.Get(apiPrefix+"/drivers/public/summaries", router.handler.PublicDriverSummaries)
	mux.Post(apiPrefix+"/fares/estimate", router.handler.Estimate)
	mux.Get(apiPrefix+"/fares/configs", router.handler.FareConfigs)
	mux.Get(apiPrefix+"/fares/rating-config", router.handler.RatingConfig)
	mux.Post(apiPrefix+"/fares/calculate-final", router.handler.CalculateFinal)

	mux.Group(func(protected chi.Router) {
		protected.Use(middleware.RequireAuth(router.verifier))
		protected.Post(apiPrefix+"/rides/{id}/status", router.handler.UpdateStatus)
		protected.Get(apiPrefix+"/rides/{id}", router.handler.GetRide)
		protected.Get(apiPrefix+"/rides/{id}/counterparty", router.handler.Counterparty)
		protected.Get(apiPrefix+"/bids/{sessionID}", router.handler.Session)
		protected.Get(apiPrefix+"/drivers/{id}/reviews", router.handler.DriverReviews)

		protected.With(middleware.RequireRole(security.RolePassenger)).Post(apiPrefix+"/rides", router.handler.CreateRide)
		protected.With(middleware.RequireRole(security.RolePassenger)).Post(apiPrefix+"/bids", router.handler.CreateSession)
		protected.With(middleware.RequireRole(security.RolePassenger)).Get(apiPrefix+"/bids/{sessionID}/offers", router.handler.Offers)
		protected.With(middleware.RequireRole(security.RolePassenger)).Post(apiPrefix+"/bids/{sessionID}/offers/{offerID}/accept", router.handler.AcceptOffer)
		protected.With(middleware.RequireRole(security.RolePassenger)).Post(apiPrefix+"/bids/{sessionID}/cancel", router.handler.CancelSession)
		protected.With(middleware.RequireRole(security.RolePassenger)).Get(apiPrefix+"/passengers/{id}/rides", router.handler.PassengerRides)
		protected.With(middleware.RequireRole(security.RolePassenger)).Get(apiPrefix+"/passengers/{id}/activity-summary", router.handler.PassengerActivitySummary)
		protected.With(middleware.RequireRole(security.RolePassenger)).Get(apiPrefix+"/drivers/online", router.handler.OnlineDrivers)
		protected.With(middleware.RequireRole(security.RolePassenger)).Post(apiPrefix+"/drivers/{id}/reviews", router.handler.CreateReview)

		protected.With(middleware.RequireRole(security.RoleDriver)).Post(apiPrefix+"/rides/{id}/accept", router.handler.AcceptRide)
		protected.With(middleware.RequireRole(security.RoleDriver)).Post(apiPrefix+"/rides/{id}/cash-settle", router.handler.SettleCash)
		protected.With(middleware.RequireRole(security.RoleDriver)).Post(apiPrefix+"/rides/{id}/bids", router.handler.SubmitBid)
		protected.With(middleware.RequireRole(security.RoleDriver)).Get(apiPrefix+"/bids/active", router.handler.ActiveSessions)
		protected.With(middleware.RequireRole(security.RoleDriver)).Post(apiPrefix+"/bids/{sessionID}/offer", router.handler.PlaceOffer)
		protected.With(middleware.RequireRole(security.RoleDriver)).Post(apiPrefix+"/bids/{sessionID}/cancel-offer", router.handler.CancelOffer)
		protected.With(middleware.RequireRole(security.RoleDriver)).Post(apiPrefix+"/bids/{id}/accept", router.handler.AcceptBid)
		protected.With(middleware.RequireRole(security.RoleDriver)).Post(apiPrefix+"/passengers/{id}/reviews", router.handler.CreatePassengerReview)
		protected.With(middleware.RequireRole(security.RoleDriver)).Get(apiPrefix+"/drivers/{id}/stats", router.handler.DriverStats)
		protected.With(middleware.RequireRole(security.RoleDriver)).Get(apiPrefix+"/drivers/{id}/earnings", router.handler.DriverEarnings)
		protected.With(middleware.RequireRole(security.RoleDriver)).Get(apiPrefix+"/drivers/{id}/trips", router.handler.DriverTrips)
	})
}
