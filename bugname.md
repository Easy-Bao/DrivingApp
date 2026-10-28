# Go Backend Audit: Verified Bug and Vulnerability Inventory

## Issue 1: Goroutine & HTTP Server Lifecycle Leak on Subscriber Error
- **Severity**: High
- **Category**: Concurrency / Lifecycle / Goroutine Leak
- **File**: `server/internal/app/app.go:247-276`
- **Problematic Code Excerpt**:
```go
	serverErrors := make(chan error, 1)
	go func() {
		serverErrors <- application.server.ListenAndServe()
	}()
	applicationLogger.InfoContext(ctx, "api listening", "address", application.server.Addr)

	select {
	case serverErr := <-serverErrors:
...
	case subscriberErr := <-subscriberDone:
		subscriberStopped = true
		if ctx.Err() != nil {
			return nil
		}
		if subscriberErr != nil {
			return fmt.Errorf("realtime event subscriber stopped: %w", subscriberErr)
		}
		return errors.New("realtime event subscriber stopped unexpectedly")
	}
```
- **Explanation of Impact**: When `subscriberErr` arrives, `Run` exits and calls deferred `application.close()`, which closes the database pool and cache client. However, `application.server` is never shut down. The HTTP server remains running in its leaked goroutine, continuing to accept and process client requests against closed pools, leaving the process in a broken zombie state.
- **Proposed Solution**:
Add a deferred server shutdown function before waiting:
```go
	stopServer := func() {
		shutdownContext, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = application.server.Shutdown(shutdownContext)
	}
	defer stopServer()
```

## Issue 2: Infinite Loop & OOM Crash on Closed Channel & Send Panic in Hub
- **Severity**: Critical
- **Category**: Concurrency / Resource Leak
- **File**: `server/internal/platform/ws/hub.go:136-146, 44-47`
- **Problematic Code Excerpt**:
```go
	var drained []event.Envelope
drainLoop:
	for {
		select {
		case bufferedEvent := <-subscription.events:
			drained = append(drained, bufferedEvent)
		default:
			break drainLoop
		}
	}
```
- **Explanation of Impact**: `bufferedEvent := <-subscription.events` lacks the comma-ok check. On a closed channel, receive returns the zero value immediately without blocking. Because it never blocks, `select` always selects `case bufferedEvent := <-subscription.events:`, never reaching `default:`. `drainLoop` becomes an infinite allocation loop continuously executing `drained = append(drained, bufferedEvent)` until RAM is exhausted and the process is killed. In addition, closing `subscription.events` without setting `subscription.closed = true` causes subsequent sends to panic on closed channel.
- **Proposed Solution**:
```go
	var drained []event.Envelope
drainLoop:
	for {
		select {
		case bufferedEvent, ok := <-subscription.events:
			if !ok {
				return false
			}
			drained = append(drained, bufferedEvent)
		default:
			break drainLoop
		}
	}
```
And set `subscription.closed = true` under lock before closing `events`.

## Issue 3: Lock Contention & Head-of-Line Blocking in Central Hub Publish
- **Severity**: High
- **Category**: Concurrency / Synchronization Misuse
- **File**: `server/internal/platform/ws/hub.go:77-102`
- **Problematic Code Excerpt**:
```go
func (hub *Hub) Publish(envelope event.Envelope) {
	hub.mutex.RLock()
	delivered := make(map[*Subscription]struct{})
	var slowSubscriptions []*Subscription
	for _, topic := range envelope.Topics() {
		for subscription := range hub.topics[topic] {
			if _, duplicate := delivered[subscription]; duplicate {
				continue
			}
			delivered[subscription] = struct{}{}
			if !subscription.deliver(envelope) {
				slowSubscriptions = append(slowSubscriptions, subscription)
			}
		}
	}
	hub.mutex.RUnlock()
```
- **Explanation of Impact**: Holding `hub.mutex.RLock()` while synchronously calling `subscription.deliver` (which acquires per-subscription mutexes and drains/refills channels) blocks any writer waiting for `hub.mutex.Lock()` (such as client connect or disconnect). A waiting writer blocks all subsequent readers, freezing event distribution across all topics whenever a subscription connects or disconnects during broadcasts.
- **Proposed Solution**:
Snapshot subscriber targets under `RLock()`, release the lock immediately, then deliver messages outside the lock:
```go
func (hub *Hub) Publish(envelope event.Envelope) {
	hub.mutex.RLock()
	var targets []*Subscription
	delivered := make(map[*Subscription]struct{})
	for _, topic := range envelope.Topics() {
		for sub := range hub.topics[topic] {
			if _, dup := delivered[sub]; !dup {
				delivered[sub] = struct{}{}
				targets = append(targets, sub)
			}
		}
	}
	hub.mutex.RUnlock()

	var slow []*Subscription
	for _, sub := range targets {
		if !sub.deliver(envelope) {
			slow = append(slow, sub)
		}
	}
	for _, sub := range slow {
		sub.Close()
	}
}
```

## Issue 4: Orphaned Background Goroutine & Redis I/O Leak on Early Rejection in Ride Lifecycle
- **Severity**: Medium
- **Category**: Concurrency / Goroutine & Resource Leak
- **File**: `server/internal/modules/ride/app/lifecycle.go:251-279, 84-101, 188-205`
- **Problematic Code Excerpt**:
```go
	locationCtx, cancel := context.WithCancel(ctx)
	results := make(chan driverLocationResult, 1)
	go func() {
		defer cancel()
		latitude, longitude, err := service.authoritativeDriverLocation(locationCtx, driverID)
		results <- driverLocationResult{latitude: latitude, longitude: longitude, err: err}
	}()
```
- **Explanation of Impact**: In `StartTrip` and `MarkArrived`, if the ride check fails (e.g. unauthorized driver or invalid status), the function returns early without invoking the returned `location()` closure. `cancel()` is only called if `service.store.Get` failed. The background goroutine continues running `authoritativeDriverLocation`, executing wasted Redis network I/O and retaining memory until parent context expires.
- **Proposed Solution**:
Return a cancellation cleanup function and ensure callers `defer cleanup()`:
```go
func (service *LifecycleService) loadRideWithDriverLocation(
	ctx context.Context, rideID, driverID int,
) (domain.Ride, func() (float64, float64, error), func(), error) {
...
	return current, getLocation, cancel, nil
}
```

## Issue 5: Cancellation Poisoning and Deadlock Hang on Panic in Fare Route Singleflight
- **Severity**: High
- **Category**: Concurrency / Context Misuse / Deadlock Risk
- **File**: `server/internal/modules/ride/app/booking.go:247-279`
- **Problematic Code Excerpt**:
```go
	if flight, ok := service.fareRouteFlights[key]; ok {
		service.fareRouteCacheMu.Unlock()
		select {
		case <-flight.done:
			return flight.metrics, flight.err
		case <-ctx.Done():
			return RouteMetrics{}, ctx.Err()
		}
	}
	flight := &fareRouteFlight{done: make(chan struct{})}
	service.fareRouteFlights[key] = flight
	service.fareRouteCacheMu.Unlock()

	metrics, err := service.resolveRoute(ctx, pickupLat, pickupLng, dropoffLat, dropoffLng)
...
	service.fareRouteCacheMu.Lock()
	delete(service.fareRouteFlights, key)
...
	close(flight.done)
	service.fareRouteCacheMu.Unlock()
```
- **Explanation of Impact**: 
  1) Context poisoning: When the leader's context cancels, `flight.err` is set to `context.Canceled`, failing all waiting concurrent passenger requests.
  2) Deadlock on panic: If `resolveRoute` panics, `flight.done` is never closed and `fareRouteFlights[key]` is never deleted. Future requests for that route hang indefinitely waiting on `flight.done`.
- **Proposed Solution**:
Protect flight cleanup with `defer` and isolate the shared execution context:
```go
	flight := &fareRouteFlight{done: make(chan struct{})}
	service.fareRouteFlights[key] = flight
	service.fareRouteCacheMu.Unlock()

	defer func() {
		service.fareRouteCacheMu.Lock()
		delete(service.fareRouteFlights, key)
		close(flight.done)
		service.fareRouteCacheMu.Unlock()
	}()

	calcCtx, cancelCalc := context.WithTimeout(context.WithoutCancel(ctx), 10*time.Second)
	defer cancelCalc()
	metrics, err := service.resolveRoute(calcCtx, pickupLat, pickupLng, dropoffLat, dropoffLng)
```

## Issue 6: Permanent Memory Leak in In-Memory Idempotency Store
- **Severity**: High
- **Category**: Resource Leak (Memory)
- **File**: `server/internal/platform/httpx/middleware/idempotency.go:122-215`
- **Problematic Code Excerpt**:
```go
	entry, ok := store.entries[key]
	if !ok || !time.Now().Before(entry.expires) {
		delete(store.entries, key)
		return nil, nil
	}
...
	store.entries[key] = memoryIdempotencyEntry{value: append([]byte(nil), value...), expires: time.Now().Add(expiration)}
```
- **Explanation of Impact**: Expired entries are only deleted if `Get(ctx, key)` is called again for that exact key after expiration. In mutation requests, client idempotency keys are unique UUIDs generated once. Because `Get` is never called again for those keys, they reside in `store.entries` permanently, growing memory monotonically until process OOM.
- **Proposed Solution**:
Add periodic or capacity-bounded eviction in `MemoryIdempotencyStore`.

## Issue 7: Context Misuse in Database Transaction Rollbacks
- **Severity**: High
- **Category**: Context Misuse / Resource Leak
- **File**: `server/internal/platform/database/tx.go:13-20`
- **Problematic Code Excerpt**:
```go
func Rollback(ctx context.Context, transaction pgx.Tx) {
	if transaction == nil {
		return
	}
	if err := transaction.Rollback(ctx); err != nil && !errors.Is(err, pgx.ErrTxClosed) {
		slog.WarnContext(ctx, "rollback transaction failed", "error", err)
	}
}
```
- **Explanation of Impact**: When a query fails due to context cancellation or deadline timeout, `transaction.Rollback(ctx)` is called with an already-canceled `ctx`. `pgx` cannot send the wire `ROLLBACK` command and fails immediately, logging false warnings and forcing the connection pool to destroy and re-establish PostgreSQL connections instead of cleanly recycling them.
- **Proposed Solution**:
Use `context.WithoutCancel(ctx)` with a dedicated short timeout:
```go
func Rollback(ctx context.Context, transaction pgx.Tx) {
	if transaction == nil {
		return
	}
	rollbackCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
	defer cancel()
	if err := transaction.Rollback(rollbackCtx); err != nil && !errors.Is(err, pgx.ErrTxClosed) {
		slog.WarnContext(rollbackCtx, "rollback transaction failed", "error", err)
	}
}
```

## Issue 8: Circuit Breaker Permanent Half-Open Lockout on Operation Panic
- **Severity**: High
- **Category**: Concurrency / Synchronization Misuse / Lifecycle
- **File**: `server/internal/platform/resilience/circuit_breaker.go:63-78, 81-95, 115-120`
- **Problematic Code Excerpt**:
```go
	if !breaker.allow(time.Now()) {
		return ErrCircuitOpen
	}

	err := operation(ctx)
...
	breaker.recordSuccess()
```
- **Explanation of Impact**: When the breaker is open and `resetAfter` expires, `allow()` sets `breaker.halfOpen = true` for a probe. If `operation(ctx)` panics, `breaker.halfOpen` is never reset to `false`. Because `allow()` checks `if breaker.halfOpen { return false }`, all subsequent requests are rejected forever with `ErrCircuitOpen`.
- **Proposed Solution**:
Ensure probe release is deferred:
```go
	completed := false
	defer func() {
		if !completed {
			breaker.release()
		}
	}()
	err := operation(ctx)
	completed = true
```

## Issue 9: Dead Startup Code and Infinite Boot Hang When Redis Is Unavailable
- **Severity**: High
- **Category**: Concurrency / Goroutine Lifecycle
- **File**: `server/internal/platform/events/redis_subscriber.go:60-101` & `server/internal/app/app.go:208-234`
- **Problematic Code Excerpt**:
```go
	for ctx.Err() == nil {
...
		_, err := pubsub.Receive(ctx)
...
		if !waitForRedisRetry(ctx, retryDelay) {
			return nil
		}
```
- **Explanation of Impact**: If Redis is offline when the server starts, `pubsub.Receive(ctx)` fails and `Run` retries indefinitely in a loop without returning an error. `subscriber.ready` is never closed, and `subscriberDone` never receives an error. The startup sequence in `app.go` hangs forever without starting the server, and `case subscriberErr := <-subscriberDone` is unreachable dead code on initial failure.
- **Proposed Solution**:
Signal initial failure or check health before entering retry loops, allowing startup errors to propagate.

## Issue 10: Unbounded Response Body Memory Buffering in Idempotency Middleware
- **Severity**: Medium
- **Category**: Resource Leak (Memory)
- **File**: `server/internal/platform/httpx/middleware/idempotency.go:421-443, 350-380`
- **Problematic Code Excerpt**:
```go
func (writer *idempotentResponseWriter) Write(body []byte) (int, error) {
...
	if _, err := writer.body.Write(body); err != nil {
		slog.Error("capture idempotent response body failed", "error", err)
	}
	return writer.ResponseWriter.Write(body)
}
```
- **Explanation of Impact**: While the request body is capped at 10 MB, the response body buffer `writer.body` has no cap. Any large response or stream is buffered entirely into RAM, and then re-marshaled into JSON, risking process OOM.
- **Proposed Solution**:
Limit `writer.body` capacity to 10 MB; if exceeded, flag as uncacheable and skip caching.

## Issue 11: Timing Attack & User Enumeration in Password Authentication
- **Severity**: High
- **Category**: Security / Authentication
- **File**: `server/internal/modules/auth/app/authenticate.go:84-94`
- **Problematic Code Excerpt**:
```go
	account, err := service.repository.FindByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, domain.ErrUserNotFound) {
			return SessionTokens{}, domain.ErrInvalidCredentials
		}
		return SessionTokens{}, UnavailableError(err)
	}
```
- **Explanation of Impact**: On `ErrUserNotFound`, the function returns immediately (~1ms), whereas valid accounts undergo bcrypt hashing (~200ms). This measurable latency discrepancy allows attackers to enumerate registered email addresses.
- **Proposed Solution**:
Perform a dummy bcrypt verification on `ErrUserNotFound` using a precomputed hash to normalize execution time:
```go
	account, err := service.repository.FindByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, domain.ErrUserNotFound) {
			_ = security.VerifyPassword(dummyBcryptHash, password)
			return SessionTokens{}, domain.ErrInvalidCredentials
		}
		return SessionTokens{}, UnavailableError(err)
	}
```

## Issue 12: Role and Existence Disclosure via Asymmetric OTP Request Status Codes
- **Severity**: Medium
- **Category**: Security / Information Disclosure
- **File**: `server/internal/modules/auth/app/otp.go:144-154`
- **Problematic Code Excerpt**:
```go
	if account.Role != domain.Passenger {
		return domain.ErrInvalidCredentials
	}
```
- **Explanation of Impact**: Non-existent emails and valid passenger accounts return `nil` (HTTP 202 Accepted), while driver accounts return `domain.ErrInvalidCredentials` (mapped to HTTP 400 Bad Request). An attacker can differentiate drivers from passengers and non-existent users.
- **Proposed Solution**:
Return `nil` when `account.Role != domain.Passenger` to eliminate the enumeration vector.

## Issue 13: Pre-Authentication Denial of Service / Account Lockout via Global Email Rate Limiter
- **Severity**: High
- **Category**: Security / Denial of Service
- **File**: `server/internal/modules/auth/transport/http/otp_rate_limiter.go:62-90`
- **Problematic Code Excerpt**:
```go
	emailLimitKey := fmt.Sprintf("rl:otp:email:%s", email)
	if err := limiter.checkLimit(r.Context(), emailLimitKey, 5, 15*time.Minute); err != nil { ... }
```
- **Explanation of Impact**: Middleware increments the rate limit counter before OTP verification occurs. An unauthenticated attacker can send 5 requests with any dummy code for a victim's email, locking the victim out of OTP verification and password reset for 15 minutes.
- **Proposed Solution**:
Throttle pre-handler requests strictly by client IP, and only increment email-specific failure counters in the application layer after an invalid code attempt.

## Issue 14: Unauthenticated Upstream Mapbox Proxy Access & Denial of Wallet
- **Severity**: High
- **Category**: Security / Access Control
- **File**: `server/internal/modules/location/transport/http/routes.go:32-34`
- **Problematic Code Excerpt**:
```go
	router.mux.Handle("GET /location/search", handler.Search())
	router.mux.Handle("GET /location/nearby", handler.Nearby())
	router.mux.Handle("GET /location/reverse", handler.Reverse())
```
- **Explanation of Impact**: `/location/search`, `/location/nearby`, and `/location/reverse` do not require authentication (`RequireAuth` is omitted). Public bots and scrapers can freely proxy geocoding requests through the backend, exhausting Mapbox API quotas and driving up billing costs.
- **Proposed Solution**:
Apply `authenticate := middleware.RequireAuth(router.verifier)` to location search and geocoding routes.

## Issue 15: Unauthenticated Fleet Surveillance via Public Driver Availability Route
- **Severity**: Medium
- **Category**: Security / Information Disclosure
- **File**: `server/internal/modules/dispatch/transport/http/routes.go:39`, `availability_handler.go:30-47`
- **Problematic Code Excerpt**:
```go
	router.mux.Handle("GET /drivers/public/summaries", handler.DriverSummaries())
```
- **Explanation of Impact**: `GET /api/v1/drivers/public/summaries` is served without `RequireAuth`. Unauthenticated scrapers can crawl real-time driver availability, ratings, and vehicle fleet distribution across the city.
- **Proposed Solution**:
Guard `/drivers/public/summaries` with `withAuthenticatedPolicy(middleware.RouteRead)`.

## Issue 16: Broken Access Control / Access Denial on Broadcast Bidding Sessions
- **Severity**: High
- **Category**: Security / Broken Access Control
- **File**: `server/internal/modules/dispatch/transport/http/handler.go:265-270`
- **Problematic Code Excerpt**:
```go
func canViewSession(session domain.BidSession, actorID int) bool {
	if session.PassengerID == actorID {
		return true
	}
	return session.TargetDriverID != nil && *session.TargetDriverID == actorID
}
```
- **Explanation of Impact**: In broadcast bidding sessions, `session.TargetDriverID` is `nil`. Any invited driver querying `GET /api/v1/bids/{sessionID}` is denied with HTTP 403 Forbidden, breaking broadcast bidding for all participating drivers.
- **Proposed Solution**:
Allow authenticated drivers to view open broadcast bid sessions:
```go
func canViewSession(session domain.BidSession, actorID int, actorRole string) bool {
	if session.PassengerID == actorID {
		return true
	}
	if session.TargetDriverID != nil && *session.TargetDriverID == actorID {
		return true
	}
	if session.TargetDriverID == nil && actorRole == "driver" {
		return true
	}
	return false
}
```

## Issue 17: Modulo Bias in Cryptographic OTP Randomness Generation
- **Severity**: Medium
- **Category**: Security / Cryptographic Flaw
- **File**: `server/internal/modules/auth/app/otp.go:549-556`
- **Problematic Code Excerpt**:
```go
	value := binary.BigEndian.Uint32(bytes)
	code := fmt.Sprintf("%06d", value%1_000_000)
```
- **Explanation of Impact**: Calculating `value % 1_000_000` from `uint32` bytes (`2^32 = 4,294,967,296`) introduces modulo bias, favoring OTP codes below 967,296 and degrading cryptographic entropy.
- **Proposed Solution**:
Use `crypto/rand.Int(rand.Reader, big.NewInt(1_000_000))` for rejection-sampled uniform randomness:
```go
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
```

## Issue 18: Unauthenticated Final Fare Calculation & Commission Margin Disclosure
- **Severity**: Medium
- **Category**: Security / Information Disclosure
- **File**: `server/internal/modules/ride/transport/http/routes.go:46`, `handler.go:557-591`
- **Problematic Code Excerpt**:
```go
	router.mux.Handle("POST /fares/calculate-final", handler.CalculateFinalFare())
```
- **Explanation of Impact**: `POST /api/v1/fares/calculate-final` accepts custom trip coordinates, distance, and duration, returning exact `commission_amount` and `driver_payout_amount` without authentication. Public clients can reverse-engineer internal pricing margins and commission tiers.
- **Proposed Solution**:
Require authenticated driver or admin session on `/fares/calculate-final`.

## Issue 19: Architectural Violation & Driver Error Leaking in HTTP Transport
- **Severity**: Medium
- **Category**: Architectural Boundary Violation
- **File**: `server/internal/modules/user/transport/http/handler.go:18, 264-274`
- **Problematic Code Excerpt**:
```go
import (
	...
	"github.com/jackc/pgx/v5"
)
...
func isProfileNotFound(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}
```
- **Explanation of Impact**: The HTTP transport layer directly imports PostgreSQL driver package `pgx/v5` and checks driver-specific errors instead of domain errors (`domain.ErrProfileNotFound`). This violates Hexagonal/Clean Architecture, tightly coupling presentation to persistence.
- **Proposed Solution**:
Remove `pgx/v5` from HTTP handler. In adapter/repository, map `pgx.ErrNoRows` to `domain.ErrProfileNotFound`, and check `errors.Is(err, domain.ErrProfileNotFound)`.

## Issue 20: Architectural Violation in Application Core (pgx dependency in dispatch/app)
- **Severity**: Medium
- **Category**: Architectural Boundary Violation
- **File**: `server/internal/modules/dispatch/app/ride_lookup.go:12, 47-49`
- **Problematic Code Excerpt**:
```go
import (
	...
	"github.com/jackc/pgx/v5"
)
...
func isRideNotFound(err error) bool {
	return errors.Is(err, ridedomain.ErrRideNotFound) || errors.Is(err, pgx.ErrNoRows)
}
```
- **Explanation of Impact**: The application use case layer (`dispatch/app`) directly imports the database driver (`pgx/v5`), breaking domain and application layer independence from infrastructure.
- **Proposed Solution**:
Remove `pgx/v5` import from `ride_lookup.go`. Ensure repository implementation returns `ridedomain.ErrRideNotFound`.

## Issue 21: Missing Deferred Rollback in Ride Lifecycle Transactions
- **Severity**: High
- **Category**: Transaction Lifecycle Management
- **File**: `server/internal/modules/ride/adapter/postgres/ride_lifecycle_store.go:47-101, 121-147, 165-191, 209-280, 374-460`
- **Problematic Code Excerpt**:
```go
	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin ride arrival transaction: %w", err)
	}
	// Missing: defer platformdatabase.Rollback(ctx, transaction)
```
- **Explanation of Impact**: All 5 status transition methods (`MarkArrived`, `StartTrip`, `CompleteTrip`, `MarkPassengerNoShow`, `CancelRide`) call `Begin(ctx)` without `defer platformdatabase.Rollback(ctx, transaction)`. On panics or early return additions, uncommitted transactions leak pooled connections.
- **Proposed Solution**:
Add `defer platformdatabase.Rollback(ctx, transaction)` immediately after `Begin(ctx)` in all 5 methods.

## Issue 22: Fragile Timestamp Parsing Swallowing Errors and Locking Contact Access
- **Severity**: High
- **Category**: Code Quality / Error Swallowing
- **File**: `server/internal/modules/ride/adapter/postgres/counterparty_reader.go:92-95` & `server/internal/modules/dispatch/app/ride_lookup.go:96-99`
- **Problematic Code Excerpt**:
```go
	completedAt, err := time.Parse(time.RFC3339, *ride.CompletedAt)
	if err != nil {
		return false, nil // Swallowed!
	}
```
- **Explanation of Impact**: Timestamps are formatted with `time.RFC3339Nano` (which includes fractional seconds). Parsing with `time.RFC3339` fails on nanoseconds. The error is swallowed and returns `false`, prematurely cutting off telephone masking and in-app chat for riders and drivers.
- **Proposed Solution**:
Parse with `time.RFC3339Nano` with fallback to `time.RFC3339`, and handle parse errors properly.

## Issue 23: Silent Error Swallowing in WebSocket Chat Event Handler
- **Severity**: High
- **Category**: Code Quality / Error Swallowing
- **File**: `server/internal/modules/chat/transport/ws/event_handler.go:24-26, 30-32, 49-51, 53-55`
- **Problematic Code Excerpt**:
```go
	if json.Unmarshal(message, &header) != nil {
		return nil // Swallowed!
	}
	switch header.Type {
...
	default:
		return nil // Dropped without trace!
	}
```
- **Explanation of Impact**: Malformed client payloads, unparseable events, or unknown message types are silently dropped with `return nil`. Callers believe the message was handled, leaving developers and clients with zero error feedback or logs.
- **Proposed Solution**:
Return explicit error or log structured warnings on unmarshal failures and unknown types.

## Issue 24: Silent Profile Update Failure Returning Zero-Value Profile on Unsupported Role
- **Severity**: High
- **Category**: Inconsistent Domain Validation / Silent Failure
- **File**: `server/internal/modules/user/adapter/postgres/profile_repository.go:134-175`
- **Problematic Code Excerpt**:
```go
	var updated domain.Profile
	switch profile.Role {
	case "driver":
...
	case "passenger":
...
	}

	if err := transaction.Commit(ctx); err != nil { ... }
	return updated, nil
```
- **Explanation of Impact**: When `profile.Role` is neither `"driver"` nor `"passenger"`, the switch falls through without an error. The user name change is committed, but an empty `domain.Profile{}` is returned with `nil` error, returning corrupt blank data to the client.
- **Proposed Solution**:
Add an explicit `default:` branch returning a domain validation error:
```go
	default:
		return domain.Profile{}, fmt.Errorf("%w: unsupported profile role %q", domain.ErrInvalidRole, profile.Role)
```

## Issue 25: Misleading Copy-Pasted Error Message in Review HTTP Handler
- **Severity**: Low
- **Category**: Code Quality / Copy-Paste Flaw
- **File**: `server/internal/modules/review/transport/http/handler.go:180-182`
- **Problematic Code Excerpt**:
```go
	default:
		return "The ride request could not be completed."
```
- **Explanation of Impact**: When an unhandled error occurs during review operations, the client receives `"The ride request could not be completed."`, misleading users into believing a ride booking failed.
- **Proposed Solution**:
Return an appropriate generic review message:
```go
	default:
		return "The review could not be submitted. Please try again."
```
