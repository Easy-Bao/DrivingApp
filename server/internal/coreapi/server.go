package coreapi

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	entdocument "github.com/Easy-Bao/DrivingApp/server/ent/driverdocument"
	entuser "github.com/Easy-Bao/DrivingApp/server/ent/user"
)

type user struct {
	ID       string `json:"id"`
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Role     string `json:"role"`
	Password string `json:"-"`
	Name     string `json:"name,omitempty"`
	Online   bool   `json:"is_online,omitempty"`
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
	locations map[string]map[string]any
	rooms     map[string][]map[string]any
}

func newStore() *store {
	return &store{users: map[string]user{}, rides: map[string]ride{}, bids: map[string]bid{}, documents: map[string]document{}, locations: map[string]map[string]any{}, rooms: map[string][]map[string]any{}}
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
	return server.routes()
}

func NewPersistentHandler(client *ent.Client, jwtSecret string) http.Handler {
	server := &handler{store: newStore(), secret: jwtSecret, client: client}
	return server.routes()
}

func (server *handler) routes() http.Handler {
	router := http.NewServeMux()
	router.HandleFunc("POST /api/v1/auth/register", server.register)
	router.HandleFunc("POST /api/v1/auth/login", server.login)
	router.HandleFunc("POST /api/v1/auth/passenger/register", server.registerPassenger)
	router.HandleFunc("POST /api/v1/auth/passenger/login", server.login)
	router.HandleFunc("POST /api/v1/auth/driver/register", server.registerDriver)
	router.HandleFunc("POST /api/v1/auth/driver/login", server.login)
	router.HandleFunc("POST /auth/passenger/register", server.registerPassenger)
	router.HandleFunc("POST /auth/passenger/login", server.login)
	router.HandleFunc("POST /auth/driver/register", server.registerDriver)
	router.HandleFunc("POST /auth/driver/login", server.login)
	router.HandleFunc("POST /auth/verify-otp", server.verifyOTP)
	router.HandleFunc("POST /auth/forgot-password", server.forgotPassword)
	router.HandleFunc("POST /auth/reset-password", server.resetPassword)
	router.HandleFunc("POST /auth/verify-token", server.verifyToken)
	router.HandleFunc("POST /api/v1/auth/verify-otp", server.verifyOTP)
	router.HandleFunc("POST /api/v1/auth/forgot-password", server.forgotPassword)
	router.HandleFunc("POST /api/v1/auth/reset-password", server.resetPassword)
	router.HandleFunc("POST /api/v1/auth/verify-token", server.verifyToken)
	router.HandleFunc("GET /api/v1/users/me", server.me)
	router.HandleFunc("GET /api/v1/passengers/{id}", server.passengerProfile)
	router.HandleFunc("PUT /api/v1/passengers/{id}", server.updatePassenger)
	router.HandleFunc("GET /api/v1/passengers/{id}/rides", server.passengerRides)
	router.HandleFunc("GET /api/v1/passengers/{id}/notifications", server.notifications)
	router.HandleFunc("POST /api/v1/rides", server.createRide)
	router.HandleFunc("GET /api/v1/rides/{id}", server.getRide)
	router.HandleFunc("POST /api/v1/rides/{id}/status", server.updateRide)
	router.HandleFunc("POST /api/v1/rides/{id}/bids", server.createBid)
	router.HandleFunc("POST /api/v1/bids/{id}/accept", server.acceptBid)
	router.HandleFunc("POST /api/v1/driver/documents", server.submitDocument)
	router.HandleFunc("GET /api/v1/driver/documents/status", server.documentStatus)
	router.HandleFunc("PATCH /api/v1/admin/documents/{id}/review", server.reviewDocument)
	router.HandleFunc("GET /api/v1/drivers/online", server.onlineDrivers)
	router.HandleFunc("GET /api/v1/drivers/{id}", server.driverProfile)
	router.HandleFunc("POST /api/v1/drivers/{id}/online", server.updateOnline)
	router.HandleFunc("GET /api/v1/drivers/{id}/stats", server.driverStats)
	router.HandleFunc("GET /api/v1/drivers/{id}/trips", server.driverTrips)
	router.HandleFunc("GET /api/v1/drivers/{id}/reviews", server.driverReviews)
	router.HandleFunc("POST /api/v1/drivers/{id}/reviews", server.addReview)
	router.HandleFunc("GET /api/v1/fares/configs", server.fareConfigs)
	router.HandleFunc("GET /api/v1/fares/rating-config", server.ratingConfig)
	router.HandleFunc("POST /api/v1/fares/estimate", server.estimateFare)
	router.HandleFunc("POST /api/v1/fares/calculate-final", server.finalFare)
	router.HandleFunc("POST /api/v1/bids", server.createBidSession)
	router.HandleFunc("GET /api/v1/bids/active", server.activeBids)
	router.HandleFunc("POST /api/v1/telemetry/location", server.updateLocation)
	router.HandleFunc("GET /api/v1/telemetry/location/{id}", server.getLocation)
	router.HandleFunc("POST /api/v1/chat/rooms", server.createRoom)
	router.HandleFunc("GET /api/v1/chat/rooms/{id}/messages", server.messages)
	router.HandleFunc("POST /api/v1/chat/rooms/{id}/messages", server.sendMessage)
	router.HandleFunc("POST /api/v1/admin/auth/login", server.adminLogin)
	router.HandleFunc("GET /api/v1/admin/auth/session", server.adminSession)
	router.HandleFunc("GET /api/v1/admin/overview", server.adminOverview)
	return router
}

type handler struct {
	store  *store
	secret string
	client *ent.Client
}

func (h *handler) register(w http.ResponseWriter, r *http.Request) {
	var input struct{ Email, Phone, Password, Role, Name string }
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
	account := user{ID: h.store.id("usr"), Email: input.Email, Phone: input.Phone, Role: input.Role, Name: input.Name, Password: hash(input.Password)}
	if h.client != nil {
		created, err := h.client.User.Create().SetPhone(input.Phone).SetEmail(input.Email).SetPasswordHash(account.Password).SetRole(input.Role).Save(r.Context())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not create account")
			return
		}
		account.ID = fmt.Sprintf("%d", created.ID)
	}
	h.store.users[account.ID] = account
	writeJSON(w, http.StatusCreated, map[string]any{"user": account, "token": h.issue(account.ID)})
}

func (h *handler) registerPassenger(w http.ResponseWriter, r *http.Request) {
	h.registerAs(w, r, "passenger")
}
func (h *handler) registerDriver(w http.ResponseWriter, r *http.Request) {
	h.registerAs(w, r, "driver")
}
func (h *handler) registerAs(w http.ResponseWriter, r *http.Request, role string) {
	var input map[string]any
	if !decode(w, r, &input) {
		return
	}
	input["role"] = role
	body, _ := json.Marshal(input)
	r.Body = io.NopCloser(bytes.NewReader(body))
	h.register(w, r)
}

func (h *handler) login(w http.ResponseWriter, r *http.Request) {
	var input struct{ Email, Password string }
	if !decode(w, r, &input) {
		return
	}
	h.store.mu.RLock()
	defer h.store.mu.RUnlock()
	if h.client != nil {
		account, err := h.client.User.Query().Where(entuser.EmailEQ(input.Email), entuser.PasswordHashEQ(hash(input.Password))).Only(r.Context())
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid credentials")
			return
		}
		id := fmt.Sprintf("%d", account.ID)
		writeJSON(w, http.StatusOK, map[string]any{"user": map[string]any{"id": id, "email": account.Email, "phone": account.Phone, "role": account.Role}, "token": h.issue(id)})
		return
	}
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
	if h.client != nil {
		passengerID, err := strconv.Atoi(id)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid identity")
			return
		}
		created, err := h.client.Ride.Create().SetPassengerID(passengerID).SetStatus("requested").SetFareCentavos(input.FareCentavos).Save(r.Context())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not create ride")
			return
		}
		writeJSON(w, http.StatusCreated, ride{ID: strconv.Itoa(created.ID), PassengerID: id, Status: created.Status, FareCentavos: created.FareCentavos})
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
	if h.client != nil {
		driverID, err := strconv.Atoi(driverID)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid identity")
			return
		}
		rideID, err := strconv.Atoi(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusNotFound, "ride not found")
			return
		}
		created, err := h.client.Bid.Create().SetRideID(rideID).SetDriverID(driverID).SetOfferedFareCentavos(input.FareCentavos).SetStatus("pending").Save(r.Context())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not create bid")
			return
		}
		writeJSON(w, http.StatusCreated, bid{ID: strconv.Itoa(created.ID), RideID: strconv.Itoa(created.RideID), DriverID: strconv.Itoa(created.DriverID), FareCentavos: created.OfferedFareCentavos, Status: created.Status})
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
	if h.client != nil {
		driverID, err := strconv.Atoi(id)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid identity")
			return
		}
		created, err := h.client.DriverDocument.Create().SetDriverID(driverID).SetDocumentType(input.Document).SetStorageKey(input.Document).SetStatus("pending").Save(r.Context())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not submit document")
			return
		}
		writeJSON(w, http.StatusCreated, document{ID: strconv.Itoa(created.ID), DriverID: id, Document: created.DocumentType, Status: created.Status})
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
	if h.client != nil {
		driverID, err := strconv.Atoi(id)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid identity")
			return
		}
		items, err := h.client.DriverDocument.Query().Where(entdocument.DriverIDEQ(driverID)).All(r.Context())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not load documents")
			return
		}
		result := make([]document, 0, len(items))
		for _, item := range items {
			result = append(result, document{ID: strconv.Itoa(item.ID), DriverID: id, Document: item.DocumentType, Status: item.Status})
		}
		writeJSON(w, http.StatusOK, map[string]any{"documents": result})
		return
	}
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
