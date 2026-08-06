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
	apiPrefix := api.V1Prefix
	mux.Post(apiPrefix+"/rides", router.handler.CreateRide)
	mux.Post(apiPrefix+"/bids", router.handler.CreateSession)
	mux.Post(apiPrefix+"/rides/{id}/accept", router.handler.AcceptRide)
	mux.Post(apiPrefix+"/rides/{id}/status", router.handler.UpdateStatus)
	mux.Post(apiPrefix+"/rides/{id}/cash-settle", router.handler.SettleCash)
	mux.Post(apiPrefix+"/rides/{id}/bids", router.handler.SubmitBid)
	mux.Get(apiPrefix+"/rides/{id}", router.handler.GetRide)
	mux.Post(apiPrefix+"/bids/fare", router.handler.Estimate)
	mux.Get(apiPrefix+"/bids/active", router.handler.ActiveSessions)
	mux.Get(apiPrefix+"/bids/{id}", router.handler.Session)
	mux.Get(apiPrefix+"/bids/{id}/offers", router.handler.Offers)
	mux.Post(apiPrefix+"/bids/{id}/offer", router.handler.PlaceOffer)
	mux.Post(apiPrefix+"/bids/{id}/offers/{offerID}/accept", router.handler.AcceptOffer)
	mux.Post(apiPrefix+"/bids/{id}/cancel", router.handler.CancelSession)
	mux.Post(apiPrefix+"/bids/{id}/cancel-offer", router.handler.CancelOffer)
	mux.Post(apiPrefix+"/bids/{id}/accept", router.handler.AcceptBid)
	mux.Get(apiPrefix+"/passengers/{id}/rides", router.handler.PassengerRides)
	mux.Post(apiPrefix+"/passengers/{id}/reviews", router.handler.CreatePassengerReview)
	mux.Get(apiPrefix+"/drivers/public/summaries", router.handler.PublicDriverSummaries)
	mux.Get(apiPrefix+"/drivers/online", router.handler.OnlineDrivers)
	mux.Get(apiPrefix+"/drivers/{id}/stats", router.handler.DriverStats)
	mux.Get(apiPrefix+"/drivers/{id}/trips", router.handler.DriverTrips)
	mux.Get(apiPrefix+"/drivers/{id}/reviews", router.handler.DriverReviews)
	mux.Post(apiPrefix+"/drivers/{id}/reviews", router.handler.CreateReview)
	mux.Post(apiPrefix+"/fares/estimate", router.handler.Estimate)
	mux.Get(apiPrefix+"/fares/configs", router.handler.FareConfigs)
	mux.Get(apiPrefix+"/fares/rating-config", router.handler.RatingConfig)
	mux.Post(apiPrefix+"/fares/calculate-final", router.handler.CalculateFinal)
}
