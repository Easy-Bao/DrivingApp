package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http/handler"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *handler.Handler }

func NewRouter(service *usecase.Service, verifier *token.Verifier) *Router {
	return &Router{handler: handler.NewHandler(service, verifier)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Route(api.V1Prefix, func(routes chi.Router) {
		routes.Post("/rides", router.handler.CreateRide)
		routes.Post("/bids", router.handler.CreateSession)
		routes.Route("/rides", func(rideRoutes chi.Router) {
			rideRoutes.Post("/{id}/accept", router.handler.AcceptRide)
			rideRoutes.Post("/{id}/status", router.handler.UpdateStatus)
			rideRoutes.Post("/{id}/cash-settle", router.handler.SettleCash)
			rideRoutes.Post("/{id}/bids", router.handler.SubmitBid)
			rideRoutes.Get("/{id}", router.handler.GetRide)
		})
		routes.Route("/bids", func(bidRoutes chi.Router) {
			bidRoutes.Post("/fare", router.handler.Estimate)
			bidRoutes.Get("/active", router.handler.ActiveSessions)
			bidRoutes.Get("/{id}", router.handler.Session)
			bidRoutes.Get("/{id}/offers", router.handler.Offers)
			bidRoutes.Post("/{id}/offer", router.handler.PlaceOffer)
			bidRoutes.Post("/{id}/offers/{offerID}/accept", router.handler.AcceptOffer)
			bidRoutes.Post("/{id}/cancel", router.handler.CancelSession)
			bidRoutes.Post("/{id}/cancel-offer", router.handler.CancelOffer)
			bidRoutes.Post("/{id}/accept", router.handler.AcceptBid)
		})
		routes.Route("/passengers", func(passengerRoutes chi.Router) {
			passengerRoutes.Get("/{id}/rides", router.handler.PassengerRides)
			passengerRoutes.Post("/{id}/reviews", router.handler.CreatePassengerReview)
		})
		routes.Route("/drivers", func(driverRoutes chi.Router) {
			driverRoutes.Get("/online", router.handler.OnlineDrivers)
			driverRoutes.Get("/{id}/stats", router.handler.DriverStats)
			driverRoutes.Get("/{id}/trips", router.handler.DriverTrips)
			driverRoutes.Get("/{id}/reviews", router.handler.DriverReviews)
			driverRoutes.Post("/{id}/reviews", router.handler.CreateReview)
		})
		routes.Route("/fares", func(fareRoutes chi.Router) {
			fareRoutes.Post("/estimate", router.handler.Estimate)
			fareRoutes.Get("/configs", router.handler.FareConfigs)
			fareRoutes.Get("/rating-config", router.handler.RatingConfig)
			fareRoutes.Post("/calculate-final", router.handler.CalculateFinal)
		})
	})
}
