package http

import (
	"errors"
	"net/http"
	"strconv"

	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/review/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/review/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
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
	scope := "driver-reviews:" + strconv.Itoa(driverID)
	page, err := sharedrequest.ParseCursorPagination(request.URL.Query(), 20, 100, scope)
	if err != nil {
		response.Error(writer, http.StatusBadRequest, "invalid pagination")
		return
	}
	limit := page.Limit
	if page.Enabled {
		limit++
	}
	items, err := handler.service.DriverReviews(request.Context(), driverID, domain.ReviewQuery{Limit: limit, Offset: page.Offset, BeforeCreatedAt: page.BeforeCreatedAt, BeforeID: page.BeforeID})
	if err != nil {
		response.Error(writer, http.StatusInternalServerError, "Driver reviews are temporarily unavailable.")
		return
	}
	if page.Enabled {
		next := ""
		if len(items) > page.Limit {
			last := items[page.Limit-1]
			next, err = sharedrequest.EncodeListCursor(scope, last.CreatedAt, last.ID)
			if err != nil {
				response.Error(writer, 500, "Driver reviews are temporarily unavailable.")
				return
			}
		}
		response.JSON(writer, http.StatusOK, response.NewCursorPage(NewReviewResponses(items), page.Limit, next))
		return
	}
	response.JSON(writer, http.StatusOK, NewReviewResponses(items))
}

func (handler *Handler) PassengerDriverReviewForRide(writer http.ResponseWriter, request *http.Request) {
	passengerID, ok := middleware.AuthenticatedUserID(request, handler.verifier)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "unauthorized")
		return
	}
	rideID, err := strconv.Atoi(chi.URLParam(request, "id"))
	if err != nil || rideID <= 0 {
		response.Error(writer, http.StatusBadRequest, "invalid ride id")
		return
	}
	item, err := handler.service.PassengerDriverReviewForRide(request.Context(), rideID, passengerID)
	if err != nil {
		switch {
		case errors.Is(err, domain.ErrReviewNotAllowed):
			response.Error(writer, http.StatusNotFound, "review not found")
		case errors.Is(err, domain.ErrReviewNotFound):
			writer.WriteHeader(http.StatusNoContent)
		case errors.Is(err, application.ErrPersistenceUnavailable):
			response.Error(writer, http.StatusServiceUnavailable, "Review service is temporarily unavailable.")
		default:
			response.Error(writer, http.StatusInternalServerError, "Review status is temporarily unavailable.")
		}
		return
	}
	response.JSON(writer, http.StatusOK, NewReviewResponse(item))
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
		response.Error(writer, reviewErrorStatus(err), safeReviewError(err))
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
		response.Error(writer, reviewErrorStatus(err), safeReviewError(err))
		return
	}
	response.JSON(writer, http.StatusCreated, NewPassengerReviewResponse(item))
}

func reviewErrorStatus(err error) int {
	switch {
	case errors.Is(err, domain.ErrReviewNotAllowed), errors.Is(err, domain.ErrInvalidRating):
		return http.StatusBadRequest
	case errors.Is(err, application.ErrPersistenceUnavailable):
		return http.StatusServiceUnavailable
	default:
		return http.StatusInternalServerError
	}
}

func safeReviewError(err error) string {
	switch {
	case errors.Is(err, domain.ErrReviewNotAllowed):
		return "Reviews are available after a completed ride."
	case errors.Is(err, domain.ErrInvalidRating):
		return "Rating must be between 1 and 5."
	case errors.Is(err, application.ErrPersistenceUnavailable):
		return "Review service is temporarily unavailable."
	default:
		return "The ride request could not be completed."
	}
}
