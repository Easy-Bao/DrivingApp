package http

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	application "github.com/Easy-Bao/DrivingApp/server/internal/review/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/review/domain"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service  *application.Service
	verifier *security.TokenManager
}

type Dependencies struct {
	Service       *application.Service
	Verifier      *security.TokenManager
	RouteSecurity *middleware.RouteSecurity
}

func NewHandler(dependencies Dependencies) *Handler {
	return &Handler{service: dependencies.Service, verifier: dependencies.Verifier}
}

func (handler *Handler) DriverReviews(writer http.ResponseWriter, request *http.Request) {
	if _, ok := middleware.AuthenticatedUserID(request, handler.verifier); !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(request, "id"))
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid driver id")
		return
	}
	page, err := sharedrequest.ParseOffsetPagination(request.URL.Query(), 20, 100)
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid pagination")
		return
	}
	items, err := handler.service.DriverReviews(request.Context(), driverID, page.Limit, page.Offset)
	if err != nil {
		response.Error(writer, http.StatusInternalServerError, "Driver reviews are temporarily unavailable.")
		return
	}
	response.JSON(writer, http.StatusOK, NewReviewResponses(items))
}

func (handler *Handler) CreateReview(writer http.ResponseWriter, request *http.Request) {
	passengerID, ok := middleware.AuthenticatedUserID(request, handler.verifier)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	driverID, err := strconv.Atoi(chi.URLParam(request, "id"))
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid driver id")
		return
	}
	var input ReviewRequest
	if sharedrequest.DecodeJSONV2(writer, request, &input, 16<<10) != nil || input.RideID <= 0 {
		response.Error(writer, http.StatusBadRequest, "invalid review")
		return
	}
	item, err := handler.service.CreateReview(request.Context(), domain.Review{
		RideID:      input.RideID,
		DriverID:    driverID,
		PassengerID: passengerID,
		Rating:      input.Rating,
		Comment:     input.Comment,
	})
	if err != nil {
		response.Error(writer, http.StatusBadRequest, safeReviewError(err))
		return
	}
	response.JSON(writer, http.StatusCreated, NewReviewResponse(item))
}

func (handler *Handler) CreatePassengerReview(writer http.ResponseWriter, request *http.Request) {
	driverID, ok := middleware.AuthenticatedUserID(request, handler.verifier)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	passengerID, err := strconv.Atoi(chi.URLParam(request, "id"))
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid passenger id")
		return
	}
	var input ReviewRequest
	if sharedrequest.DecodeJSONV2(writer, request, &input, 16<<10) != nil || input.RideID <= 0 {
		response.Error(writer, http.StatusBadRequest, "invalid review")
		return
	}
	item, err := handler.service.CreatePassengerReview(request.Context(), domain.PassengerReview{
		RideID:      input.RideID,
		DriverID:    driverID,
		PassengerID: passengerID,
		Rating:      input.Rating,
		Comment:     input.Comment,
	})
	if err != nil {
		response.Error(writer, http.StatusBadRequest, safeReviewError(err))
		return
	}
	response.JSON(writer, http.StatusCreated, NewPassengerReviewResponse(item))
}

func safeReviewError(err error) string {
	switch {
	case errors.Is(err, domain.ErrReviewNotAllowed):
		return "Reviews are available after a completed ride."
	default:
		return "The ride request could not be completed."
	}
}
