package request

import (
	"math"
	"net/http"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
	"github.com/go-chi/chi/v5"
)

// ParsePositiveInt32Param parses a named chi URL parameter and reports whether it is a valid positive int32 ID.
func ParsePositiveInt32Param(r *http.Request, name string) (int, bool) {
	if r == nil {
		return 0, false
	}
	id, err := strconv.Atoi(chi.URLParam(r, name))
	if err != nil || id <= 0 || int64(id) > math.MaxInt32 {
		return 0, false
	}
	return id, true
}

// PositiveIntParam parses a positive int32 path parameter, writing a 400 error response with errMessage when invalid.
func PositiveIntParam(w http.ResponseWriter, r *http.Request, name, errMessage string) (int, bool) {
	id, ok := ParsePositiveInt32Param(r, name)
	if !ok {
		response.Error(w, http.StatusBadRequest, errMessage)
		return 0, false
	}
	return id, true
}
