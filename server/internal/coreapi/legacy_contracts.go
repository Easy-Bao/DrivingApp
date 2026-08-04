package coreapi

import (
	"net/http"
	"strings"
)

func (h *handler) verifyOTP(w http.ResponseWriter, r *http.Request) {
	var input map[string]any
	if !decode(w, r, &input) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"verified": true})
}
func (h *handler) forgotPassword(w http.ResponseWriter, r *http.Request) {
	var input map[string]any
	if !decode(w, r, &input) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"sent": true})
}
func (h *handler) resetPassword(w http.ResponseWriter, r *http.Request) {
	var input struct{ Email, Password string }
	if !decode(w, r, &input) {
		return
	}
	h.store.mu.Lock()
	defer h.store.mu.Unlock()
	for id, account := range h.store.users {
		if account.Email == input.Email {
			account.Password = hash(input.Password)
			h.store.users[id] = account
			writeJSON(w, http.StatusOK, map[string]any{"reset": true})
			return
		}
	}
	writeError(w, http.StatusNotFound, "account not found")
}
func (h *handler) verifyToken(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Token string `json:"token"`
	}
	if !decode(w, r, &input) {
		return
	}
	id, ok := h.verify(input.Token)
	if !ok {
		writeError(w, http.StatusUnauthorized, "invalid token")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"valid": true, "user_id": id})
}

func (h *handler) passengerProfile(w http.ResponseWriter, r *http.Request) {
	h.profile(w, r, "passenger")
}
func (h *handler) driverProfile(w http.ResponseWriter, r *http.Request) { h.profile(w, r, "driver") }
func (h *handler) profile(w http.ResponseWriter, r *http.Request, role string) {
	h.store.mu.RLock()
	account, found := h.store.users[r.PathValue("id")]
	h.store.mu.RUnlock()
	if !found || account.Role != role {
		writeError(w, http.StatusNotFound, "profile not found")
		return
	}
	writeJSON(w, http.StatusOK, account)
}
func (h *handler) updatePassenger(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok || id != r.PathValue("id") {
		writeError(w, http.StatusForbidden, "forbidden")
		return
	}
	var input struct{ Name, Phone, PreferredRideType string }
	if !decode(w, r, &input) {
		return
	}
	h.store.mu.Lock()
	account, found := h.store.users[id]
	if found {
		account.Name, account.Phone = input.Name, input.Phone
		h.store.users[id] = account
	}
	h.store.mu.Unlock()
	if !found {
		writeError(w, http.StatusNotFound, "profile not found")
		return
	}
	writeJSON(w, http.StatusOK, account)
}
func (h *handler) passengerRides(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok || id != r.PathValue("id") {
		writeError(w, http.StatusForbidden, "forbidden")
		return
	}
	h.store.mu.RLock()
	defer h.store.mu.RUnlock()
	result := []ride{}
	for _, item := range h.store.rides {
		if item.PassengerID == id {
			result = append(result, item)
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{"rides": result})
}
func (h *handler) notifications(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.identity(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"notifications": []any{}})
}

func (h *handler) onlineDrivers(w http.ResponseWriter, _ *http.Request) {
	h.store.mu.RLock()
	defer h.store.mu.RUnlock()
	result := []user{}
	for _, account := range h.store.users {
		if account.Role == "driver" && account.Online {
			result = append(result, account)
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{"drivers": result})
}
func (h *handler) updateOnline(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok || id != r.PathValue("id") {
		writeError(w, http.StatusForbidden, "forbidden")
		return
	}
	var input struct {
		Online bool `json:"is_online"`
	}
	if !decode(w, r, &input) {
		return
	}
	h.store.mu.Lock()
	account, found := h.store.users[id]
	if found {
		account.Online = input.Online
		h.store.users[id] = account
	}
	h.store.mu.Unlock()
	if !found {
		writeError(w, http.StatusNotFound, "driver not found")
		return
	}
	writeJSON(w, http.StatusOK, account)
}
func (h *handler) driverStats(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.identity(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"completed_rides": 0, "rating": 5.0})
}
func (h *handler) driverTrips(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.identity(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"trips": []any{}})
}
func (h *handler) driverReviews(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.identity(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"reviews": []any{}})
}
func (h *handler) addReview(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.identity(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input map[string]any
	if !decode(w, r, &input) {
		return
	}
	writeJSON(w, http.StatusCreated, input)
}

func (h *handler) getRide(w http.ResponseWriter, r *http.Request) {
	h.store.mu.RLock()
	item, found := h.store.rides[r.PathValue("id")]
	h.store.mu.RUnlock()
	if !found {
		writeError(w, http.StatusNotFound, "ride not found")
		return
	}
	writeJSON(w, http.StatusOK, item)
}
func (h *handler) updateRide(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.identity(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input struct {
		Status string `json:"status"`
	}
	if !decode(w, r, &input) || input.Status == "" {
		writeError(w, http.StatusBadRequest, "status is required")
		return
	}
	h.store.mu.Lock()
	item, found := h.store.rides[r.PathValue("id")]
	if found {
		item.Status = input.Status
		h.store.rides[item.ID] = item
	}
	h.store.mu.Unlock()
	if !found {
		writeError(w, http.StatusNotFound, "ride not found")
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (h *handler) fareConfigs(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"configs": []any{map[string]any{"service_type": "bao_bao", "base_fare_centavos": 2500, "per_km_centavos": 100}}})
}
func (h *handler) ratingConfig(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"minimum_rating_threshold": 4.5})
}
func (h *handler) estimateFare(w http.ResponseWriter, r *http.Request) {
	var input struct{ DistanceKm, DurationMinutes float64 }
	if !decode(w, r, &input) {
		return
	}
	total := int64(2500 + input.DistanceKm*100 + input.DurationMinutes*50)
	writeJSON(w, http.StatusOK, map[string]any{"fare_centavos": total})
}
func (h *handler) finalFare(w http.ResponseWriter, r *http.Request)        { h.estimateFare(w, r) }
func (h *handler) createBidSession(w http.ResponseWriter, r *http.Request) { h.createRide(w, r) }
func (h *handler) activeBids(w http.ResponseWriter, _ *http.Request) {
	h.store.mu.RLock()
	defer h.store.mu.RUnlock()
	result := []bid{}
	for _, item := range h.store.bids {
		if item.Status == "pending" {
			result = append(result, item)
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{"bids": result})
}

func (h *handler) updateLocation(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input map[string]any
	if !decode(w, r, &input) {
		return
	}
	h.store.mu.Lock()
	h.store.locations[id] = input
	h.store.mu.Unlock()
	writeJSON(w, http.StatusOK, input)
}
func (h *handler) getLocation(w http.ResponseWriter, r *http.Request) {
	h.store.mu.RLock()
	point, found := h.store.locations[r.PathValue("id")]
	h.store.mu.RUnlock()
	if !found {
		writeError(w, http.StatusNotFound, "location not found")
		return
	}
	writeJSON(w, http.StatusOK, point)
}
func (h *handler) createRoom(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	h.store.mu.Lock()
	room := h.store.id("room") + "_" + id
	h.store.rooms[room] = []map[string]any{}
	h.store.mu.Unlock()
	writeJSON(w, http.StatusCreated, map[string]any{"id": room})
}
func (h *handler) messages(w http.ResponseWriter, r *http.Request) {
	h.store.mu.RLock()
	messages := h.store.rooms[r.PathValue("id")]
	h.store.mu.RUnlock()
	writeJSON(w, http.StatusOK, map[string]any{"messages": messages})
}
func (h *handler) sendMessage(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input struct {
		Message string `json:"message"`
	}
	if !decode(w, r, &input) || strings.TrimSpace(input.Message) == "" {
		writeError(w, http.StatusBadRequest, "message is required")
		return
	}
	item := map[string]any{"sender_id": id, "message": input.Message}
	h.store.mu.Lock()
	h.store.rooms[r.PathValue("id")] = append(h.store.rooms[r.PathValue("id")], item)
	h.store.mu.Unlock()
	writeJSON(w, http.StatusCreated, item)
}

func (h *handler) adminLogin(w http.ResponseWriter, r *http.Request) {
	var input struct{ Email, Password string }
	if !decode(w, r, &input) {
		return
	}
	if input.Email == "" || input.Password == "" {
		writeError(w, http.StatusUnauthorized, "invalid credentials")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"token": h.issue("admin:" + input.Email), "role": "admin"})
}
func (h *handler) adminSession(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok || !strings.HasPrefix(id, "admin:") {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"admin_id": id, "role": "admin"})
}
func (h *handler) adminOverview(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.identity(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	h.store.mu.RLock()
	defer h.store.mu.RUnlock()
	writeJSON(w, http.StatusOK, map[string]any{"users": len(h.store.users), "rides": len(h.store.rides), "documents": len(h.store.documents)})
}
