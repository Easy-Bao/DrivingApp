package coreapi

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

type user struct {
	ID       string `json:"id"`
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Role     string `json:"role"`
	Password string `json:"-"`
}

type ride struct {
	ID           string `json:"id"`
	PassengerID  string `json:"passenger_id"`
	Status       string `json:"status"`
	FareCentavos int64  `json:"fare_centavos"`
}

type bid struct {
	ID           string `json:"id"`
	RideID       string `json:"ride_id"`
	DriverID     string `json:"driver_id"`
	FareCentavos int64  `json:"fare_centavos"`
	Status       string `json:"status"`
}

type document struct {
	ID       string `json:"id"`
	DriverID string `json:"driver_id"`
	Document string `json:"document_type"`
	Status   string `json:"status"`
}

type store struct {
	mu        sync.RWMutex
	users     map[string]user
	rides     map[string]ride
	bids      map[string]bid
	documents map[string]document
	next      int
}

func newStore() *store {
	return &store{users: map[string]user{}, rides: map[string]ride{}, bids: map[string]bid{}, documents: map[string]document{}}
}

func (s *store) id(prefix string) string {
	s.next++
	return fmt.Sprintf("%s_%d", prefix, s.next)
}

// NewHandler exposes the consolidated REST contract. The store is deliberately
// behind this handler so an Ent repository can replace it without changing
// transport contracts or tests.
func NewHandler(jwtSecret string) http.Handler {
	server := &handler{store: newStore(), secret: jwtSecret}
	router := http.NewServeMux()
	router.HandleFunc("POST /api/v1/auth/register", server.register)
	router.HandleFunc("POST /api/v1/auth/login", server.login)
	router.HandleFunc("GET /api/v1/users/me", server.me)
	router.HandleFunc("POST /api/v1/rides", server.createRide)
	router.HandleFunc("POST /api/v1/rides/{id}/bids", server.createBid)
	router.HandleFunc("POST /api/v1/bids/{id}/accept", server.acceptBid)
	router.HandleFunc("POST /api/v1/driver/documents", server.submitDocument)
	router.HandleFunc("GET /api/v1/driver/documents/status", server.documentStatus)
	router.HandleFunc("PATCH /api/v1/admin/documents/{id}/review", server.reviewDocument)
	return router
}

type handler struct {
	store  *store
	secret string
}

func (h *handler) register(w http.ResponseWriter, r *http.Request) {
	var input struct{ Email, Phone, Password, Role string }
	if !decode(w, r, &input) || input.Email == "" || input.Password == "" || (input.Role != "passenger" && input.Role != "driver") {
		writeError(w, http.StatusBadRequest, "invalid registration")
		return
	}
	h.store.mu.Lock()
	defer h.store.mu.Unlock()
	for _, existing := range h.store.users {
		if existing.Email == input.Email {
			writeError(w, http.StatusConflict, "account already exists")
			return
		}
	}
	account := user{ID: h.store.id("usr"), Email: input.Email, Phone: input.Phone, Role: input.Role, Password: hash(input.Password)}
	h.store.users[account.ID] = account
	writeJSON(w, http.StatusCreated, map[string]any{"user": account, "token": h.issue(account.ID)})
}

func (h *handler) login(w http.ResponseWriter, r *http.Request) {
	var input struct{ Email, Password string }
	if !decode(w, r, &input) {
		return
	}
	h.store.mu.RLock()
	defer h.store.mu.RUnlock()
	for _, account := range h.store.users {
		if account.Email == input.Email && account.Password == hash(input.Password) {
			writeJSON(w, http.StatusOK, map[string]any{"user": account, "token": h.issue(account.ID)})
			return
		}
	}
	writeError(w, http.StatusUnauthorized, "invalid credentials")
}

func (h *handler) me(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	h.store.mu.RLock()
	account, found := h.store.users[id]
	h.store.mu.RUnlock()
	if !found {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}
	writeJSON(w, http.StatusOK, account)
}

func (h *handler) createRide(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input struct {
		FareCentavos int64 `json:"fare_centavos"`
	}
	if !decode(w, r, &input) || input.FareCentavos < 0 {
		writeError(w, http.StatusBadRequest, "invalid fare")
		return
	}
	h.store.mu.Lock()
	ride := ride{ID: h.store.id("ride"), PassengerID: id, Status: "requested", FareCentavos: input.FareCentavos}
	h.store.rides[ride.ID] = ride
	h.store.mu.Unlock()
	writeJSON(w, http.StatusCreated, ride)
}

func (h *handler) createBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := h.identity(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input struct {
		FareCentavos int64 `json:"fare_centavos"`
	}
	if !decode(w, r, &input) || input.FareCentavos < 0 {
		writeError(w, http.StatusBadRequest, "invalid fare")
		return
	}
	h.store.mu.Lock()
	defer h.store.mu.Unlock()
	if _, found := h.store.rides[r.PathValue("id")]; !found {
		writeError(w, http.StatusNotFound, "ride not found")
		return
	}
	created := bid{ID: h.store.id("bid"), RideID: r.PathValue("id"), DriverID: driverID, FareCentavos: input.FareCentavos, Status: "pending"}
	h.store.bids[created.ID] = created
	writeJSON(w, http.StatusCreated, created)
}

func (h *handler) acceptBid(w http.ResponseWriter, r *http.Request) {
	driverID, ok := h.identity(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	h.store.mu.Lock()
	defer h.store.mu.Unlock()
	offer, found := h.store.bids[r.PathValue("id")]
	if !found || offer.DriverID != driverID {
		writeError(w, http.StatusNotFound, "bid not found")
		return
	}
	if offer.Status != "pending" {
		writeError(w, http.StatusConflict, "bid is not pending")
		return
	}
	offer.Status = "accepted"
	h.store.bids[offer.ID] = offer
	ride := h.store.rides[offer.RideID]
	ride.Status = "assigned"
	h.store.rides[ride.ID] = ride
	writeJSON(w, http.StatusOK, map[string]any{"bid": offer, "ride": ride})
}

func (h *handler) submitDocument(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input struct {
		Document string `json:"document_type"`
	}
	if !decode(w, r, &input) || input.Document == "" {
		writeError(w, http.StatusBadRequest, "document_type is required")
		return
	}
	h.store.mu.Lock()
	created := document{ID: h.store.id("doc"), DriverID: id, Document: input.Document, Status: "pending"}
	h.store.documents[created.ID] = created
	h.store.mu.Unlock()
	writeJSON(w, http.StatusCreated, created)
}

func (h *handler) documentStatus(w http.ResponseWriter, r *http.Request) {
	id, ok := h.identity(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	h.store.mu.RLock()
	defer h.store.mu.RUnlock()
	result := []document{}
	for _, item := range h.store.documents {
		if item.DriverID == id {
			result = append(result, item)
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{"documents": result})
}

func (h *handler) reviewDocument(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.identity(r); !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	var input struct {
		Status string `json:"status"`
	}
	if !decode(w, r, &input) || (input.Status != "approved" && input.Status != "rejected") {
		writeError(w, http.StatusBadRequest, "invalid review status")
		return
	}
	h.store.mu.Lock()
	defer h.store.mu.Unlock()
	item, found := h.store.documents[r.PathValue("id")]
	if !found {
		writeError(w, http.StatusNotFound, "document not found")
		return
	}
	item.Status = input.Status
	h.store.documents[item.ID] = item
	writeJSON(w, http.StatusOK, item)
}

func (h *handler) identity(r *http.Request) (string, bool) {
	raw := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	return h.verify(raw)
}
func (h *handler) issue(id string) string {
	header := b64(`{"alg":"HS256","typ":"JWT"}`)
	payload := b64(fmt.Sprintf(`{"sub":%q,"exp":%d}`, id, time.Now().Add(24*time.Hour).Unix()))
	mac := hmac.New(sha256.New, []byte(h.secret))
	_, _ = mac.Write([]byte(header + "." + payload))
	return header + "." + payload + "." + base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}
func (h *handler) verify(raw string) (string, bool) {
	return (&secretVerifier{secret: h.secret}).verify(raw)
}

type secretVerifier struct{ secret string }

func (v *secretVerifier) verify(raw string) (string, bool) {
	if v.secret == "" {
		return "", false
	}
	parts := strings.Split(raw, ".")
	if len(parts) != 3 {
		return "", false
	}
	mac := hmac.New(sha256.New, []byte(v.secret))
	_, _ = mac.Write([]byte(parts[0] + "." + parts[1]))
	sig, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil || !hmac.Equal(sig, mac.Sum(nil)) {
		return "", false
	}
	body, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return "", false
	}
	var claims struct {
		Subject string `json:"sub"`
		Expires int64  `json:"exp"`
	}
	if json.Unmarshal(body, &claims) != nil || claims.Subject == "" || claims.Expires < time.Now().Unix() {
		return "", false
	}
	return claims.Subject, true
}
func hash(value string) string { return fmt.Sprintf("%x", sha256.Sum256([]byte(value))) }
func b64(value string) string  { return base64.RawURLEncoding.EncodeToString([]byte(value)) }
func decode(w http.ResponseWriter, r *http.Request, value any) bool {
	if json.NewDecoder(http.MaxBytesReader(w, r.Body, 16<<10)).Decode(value) != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON")
		return false
	}
	return true
}
func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
