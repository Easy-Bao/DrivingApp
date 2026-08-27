package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type Router struct{ handler *Handler }

func NewRouter(query ridecontext.RideContextQuery, verifier *security.TokenManager) *Router {
	return &Router{handler: NewHandler(query, verifier)}
}

func (router *Router) RegisterRoutes(mux chi.Router) {
	mux.Get(api.V1Prefix+"/passenger/home", router.handler.GetRideContext)
}
