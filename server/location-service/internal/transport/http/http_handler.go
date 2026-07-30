package http

import (
	"location-service/internal/usecase"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type HTTPHandler struct {
	useCase usecase.LocationUseCase
}

func NewHTTPHandler(uc usecase.LocationUseCase) *HTTPHandler {
	return &HTTPHandler{useCase: uc}
}

func (h *HTTPHandler) RegisterRoutes(router *gin.Engine) {
	places := router.Group("/places")
	{
		places.GET("/search", h.SearchPlaces)
		places.GET("/reverse", h.ReverseGeocode)
		places.GET("/nearby", h.GetNearbyPois)
		places.POST("/route", h.GetRoute)
	}
}

func (h *HTTPHandler) SearchPlaces(c *gin.Context) {
	query := c.Query("query")
	userLat, _ := strconv.ParseFloat(c.Query("userLat"), 64)
	userLng, _ := strconv.ParseFloat(c.Query("userLng"), 64)

	places, err := h.useCase.SearchPlaces(c.Request.Context(), query, userLat, userLng)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"places": places,
	})
}

func (h *HTTPHandler) ReverseGeocode(c *gin.Context) {
	lat, err1 := strconv.ParseFloat(c.Query("lat"), 64)
	lng, err2 := strconv.ParseFloat(c.Query("lng"), 64)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid lat or lng parameters"})
		return
	}

	place, err := h.useCase.ReverseGeocode(c.Request.Context(), lat, lng)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, place)
}

func (h *HTTPHandler) GetNearbyPois(c *gin.Context) {
	lat, err1 := strconv.ParseFloat(c.Query("lat"), 64)
	lng, err2 := strconv.ParseFloat(c.Query("lng"), 64)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid lat or lng parameters"})
		return
	}
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))

	places, err := h.useCase.GetNearbyPois(c.Request.Context(), lat, lng, page)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"places": places,
	})
}

type RouteRequest struct {
	OriginLat float64 `json:"originLat"`
	OriginLng float64 `json:"originLng"`
	DestLat   float64 `json:"destLat"`
	DestLng   float64 `json:"destLng"`
}

func (h *HTTPHandler) GetRoute(c *gin.Context) {
	var req RouteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid route payload"})
		return
	}

	route, err := h.useCase.GetRoute(c.Request.Context(), req.OriginLat, req.OriginLng, req.DestLat, req.DestLng)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, route)
}
