# EasyRide Ecosystem Performance Audit and Implementation Plan

> Status: IMPLEMENTATION PLAN / TODO — audit findings only; no optimization changes have been implemented.

**Audit date:** 2026-10-08
**Scope:** Passenger Flutter app, Driver Flutter app, shared Flutter/Dart packages, Go modular monolith, PostgreSQL, Redis, Mapbox, Android lifecycle/build configuration, and realtime/location paths.

This document is the implementation backlog and measurement contract for a performance pass. It records what the repository proves today, what is only a strong hypothesis, and what must be measured before code is changed. It must not be read as evidence that a proposed optimization has already shipped or improved runtime behavior.

## 1. Performance Executive Summary

The repository has a reasonable lifecycle and correctness foundation: it uses lifecycle-aware periodic tasks, generation/stale-result guards, request coalescing in several hot paths, bounded caches, realtime reconnect/resynchronization, server-side validation, stale-location handling, and idempotent ride transition tests. Those protections must remain in place while performance work proceeds.

The highest-value performance risks found by static inspection are:

1. **High-frequency work is multiplied across clients and layers.** Passenger active-trip reconciliation runs every two seconds and performs both status and driver-location reads. Passenger offer fallback refresh runs every three seconds while realtime is also active. Driver foreground ride polling runs every four seconds, and the background service separately polls ride requests every four seconds, location every ten seconds, and presence every twenty seconds. These are verified schedules, not measured bottlenecks; request volume, latency, and battery impact are not currently instrumented.
2. **Map marker updates can perform expensive platform and raster work.** Marker replacement reads all annotations, regenerates PNG bytes through a `PictureRecorder`, and optionally performs 18 Mapbox annotation updates with 20 ms delays. This is a high-confidence candidate for frame and platform-channel pressure when location updates are frequent, but no frame trace was available.
3. **Startup is serialized before the first `runApp`.** Both bootstraps stop an existing background service, read preferences, load dotenv, initialize Sentry, configure routing/dependencies, initialize Mapbox, and only then render the app. Some work may be required before routing, but the cost and criticality of each step are not measured.
4. **Driver location spooling rewrites a complete JSON array.** Every enqueue decodes and re-encodes the full bounded list. Flush removes the first item and writes the remaining list after each successful send. This is a verified allocation and I/O pattern; its runtime impact depends on spool depth and device storage latency.
5. **Location ingestion and nearby-driver lookup have repeated backend work.** Location ingestion validates online presence before persistence and again after persistence, then loads active rides and publishes events. Nearby lookup performs expiry cleanup before every search, then GeoSearch and MGET. These are correctness-sensitive paths and should only be consolidated after query, Redis, and end-to-end timings are captured.
6. **Several UI and state paths are broad enough to measure.** The Driver Dashboard has a broad `BlocBuilder` with a `buildWhen`, and its dynamic feed must be checked for lazy construction. Active-ride chat unread counts are refreshed every four seconds in multiple screens. These are candidates for selective subscriptions or shared realtime state, not automatic refactoring targets.

No P0 performance defect is confirmed by the available evidence. A P0 must be opened if runtime testing demonstrates a tracking failure, unreleased resource, user-visible UI freeze, or correctness-threatening race. The immediate work is P1 measurement and reduction of unnecessary repeated work without weakening authentication, ride transitions, presence, or tracking correctness.

## 2. Audit Method, Evidence Rules, and Limitations

### Evidence rules

Each finding uses one of these classifications:

- **Verified performance-relevant behavior:** the source, configuration, or test demonstrably performs the described work. This does not prove that the work is slow on a device.
- **Strongly suspected bottleneck:** the work occurs on a high-frequency or latency-sensitive path and has a plausible cost. A runtime trace, counter, or profile is required before changing behavior.
- **Potential optimization:** a safe candidate whose value depends on measurement or product policy.
- **Already optimized:** an existing safeguard was found. It should not be removed or duplicated without evidence.
- **Requires runtime measurement:** source inspection cannot establish cost, user impact, or battery behavior.

### What was inspected

- Passenger and Driver entry points, bootstraps, dependency composition, routing, active ride, booking, chat, dashboard, location, telemetry, and realtime paths.
- Shared `foundation`, `design_system`, and `maps` packages, including device location, route caching, Mapbox initialization, annotations, and marker motion.
- Go HTTP handlers, services, repositories, location tracking, realtime event publication, PostgreSQL pool configuration, generated sqlc query boundaries, and Redis location storage.
- Android manifests/build files and release-related configuration at a structural level.
- Existing unit, widget, integration, and backend tests, static analysis, and repository status.

### Current limitations

The following were not available in this environment and therefore are explicitly **Not measured**:

- Physical Android device or usable emulator for profile/release traces. `adb devices -l` could not start its daemon because socket creation was denied.
- Docker, PostgreSQL, and Redis runtime access. The Docker socket was denied.
- Flutter DevTools frame, memory, network, CPU, GPU, battery, or thermal traces.
- Go pprof, production-like server metrics, request tracing, or Redis command timings.
- PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)` on representative data.
- Gradle release build verification; the read-only Gradle wrapper cache blocked it.

The repository had unrelated pre-existing changes before this document was created. This task does not modify or stage those changes.

## 3. Codebase Performance Inventory

| Layer | Ownership and entry points | Performance-sensitive paths | Current evidence |
|---|---|---|---|
| Passenger app | `apps/passenger/lib/main.dart`, `passenger_bootstrap.dart`, `PassengerApp`, `PassengerDependencies` | Bootstrap, session/auth restoration, home/search, booking offers, active ride tracking, chat unread state, lifecycle/background reconciliation | Startup is sequential; active-trip and offer polling are present; lifecycle and generation guards exist. |
| Driver app | `apps/driver/lib/main.dart`, `driver_bootstrap.dart`, `DriverApp`, `DriverDependencies` | Session restoration, online/offline transitions, location stream, ride request refresh, realtime ride events, background telemetry, active ride/chat | Foreground and background schedules are explicit; several cancellation and generation guards exist. |
| Shared foundation | `packages/foundation` | HTTP/auth token refresh, realtime transport, lifecycle coordination, error handling, cache/request helpers | Reuse and connection lifecycle should be measured before changing client behavior. |
| Shared maps | `packages/maps` | Mapbox initialization, native place service, route cache, location permission/current position/stream, annotation creation/update, marker image rasterization | High accuracy and distance filters are configured; route cache exists; marker image work is repeated. |
| Shared design system | `packages/design_system` | Theme construction and widget tree cost | No source evidence alone establishes a rendering bottleneck. Use frame/build traces before changing widgets. |
| API/data sources | App feature repositories and Dio clients in the composition roots | Request creation, refresh-token flow, serialization, cancellation, duplicate reads, realtime fallback | Clients are composed as shared dependencies; request counts and payload bytes are not instrumented. |
| Go transport | `server/internal/app`, feature HTTP handlers and middleware | Authentication, logging/security/rate-limit middleware, JSON encoding, request context and timeouts | Middleware overhead and endpoint timings are not measured. |
| Go application/services | Ride, location, dispatch, bidding, lifecycle, and realtime application packages | Matching, ride transitions, location ingestion, event publication, route provider use | Correctness and idempotency tests exist; pprof/tracing data is absent. |
| PostgreSQL | `server/database/schema`, `server/database/queries`, generated sqlc package, `postgres_pool.go` | Active rides/bids, profile lookup, status/location reads, settlement checks, pool waits and locks | Query shape is inspectable; plans and production-like cardinalities are not measured. |
| Redis | `server/internal/location/tracking/driver_location_store.go`, Redis client wiring | Driver presence/location upserts, expiry cleanup, GeoSearch, MGET, stale-member cleanup | Cleanup and read sequence are verified; command latency and memory are not measured. |
| Android/release | `apps/*/android`, Flutter build configuration and manifests | Startup services, background location, foreground service policy, ABI/package size, release shrinking | Structural review only; release APK/AAB and device lifecycle behavior are not measured. |

### Existing protections to preserve

- Passenger tracking checks foreground state, prevents overlapping synchronization, guards stale generations, disposes its periodic task, and stops background telemetry at terminal ride states.
- Booking offer refresh coexists with realtime recovery and rejects stale sessions/closed blocs; `_isRefreshingOffers` prevents overlapping fallback reads.
- Driver foreground polling uses `_pollGeneration`, checks `mounted`, stops timers, and uses realtime events for immediate refreshes.
- Background telemetry checks visibility, online-work eligibility, token validity, and in-flight flags before location, presence, and request polling.
- Map route caching and route retry gates already limit some route-provider calls.
- The server validates coordinates, timestamps, motion, driver presence, context cancellation, stale locations, and active ride assignments. Ride transitions use idempotency/locking tests and must remain authoritative.
- Redis nearby reads filter malformed/stale payloads and remove stale members as best effort rather than hiding valid drivers.

### Focus-area coverage

| Required focus | Audit result | Status |
|---|---|---|
| Flutter rendering/layout | The Driver Dashboard has a broad but guarded `BlocBuilder`; dynamic content and map annotation work are the main source-visible rebuild/render candidates. No frame trace proves a jank source, and no blanket `const`/`RepaintBoundary` rewrite is justified. | Potential; requires frame/build measurement |
| State management/asynchrony | BLoC/Cubit paths use closed/mounted checks, generation checks, and in-flight flags. The next pass must map each event to `restartable`/`droppable`/`sequential` semantics before changing concurrency: search-like work may cancel stale requests; ride/settlement transitions must remain ordered and idempotent; telemetry refresh may be coalesced. | Already protected in places; policy review required |
| Navigation/input | Route configuration and page ownership were inspected, but no device interaction trace establishes slow transitions, keyboard delay, duplicate pushes, or input lag. Network work must not be awaited unnecessarily before a route becomes visible unless the route contract requires it. | Requires runtime measurement |
| Network/API | Dio clients and refresh/realtime dependencies are composed at app level; polling/fallback paths are known. Request duration, payload bytes, duplicate requests, retries, and cancellation are not currently available as a performance baseline. | Strongly suspected in high-frequency paths; instrument first |
| Memory/resource lifecycle | Controllers, periodic tasks, location subscriptions, realtime subscriptions, and service shutdown paths include disposal/cancellation guards. Heap retention after repeated journeys has not been measured, so no leak is confirmed. | Already protected in source; requires memory test |
| CPU/GPU/battery/thermal | GPS settings, marker rasterization, animation updates, JSON spool work, and polling are plausible consumers. No CPU/GPU/battery/thermal sample exists. | Requires device measurement |
| Android lifecycle/background | Visibility checks and background telemetry shutdown/recovery exist, but Android process death, Doze, screen lock, permission loss, and foreground-service behavior cannot be proven without a device. | Requires physical-device matrix |
| Backend/Go | Context checks, stale-point rejection, event publication, and lifecycle idempotency are present. Location and active-bid paths contain measurable stage boundaries but no pprof/trace baseline. | Strongly suspected under load; instrument first |
| PostgreSQL/Redis | Query call sequences, pool defaults, Redis expiry cleanup, GeoSearch, MGET, and stale cleanup are visible. Execution plans, pool waits, command latency, lock behavior, and memory are unavailable. | Requires service-backed measurement |
| Release/package size | Android build files and manifests are present, but clean release output and ABI breakdown are unavailable because the Gradle cache is read-only. | Requires release build |

### Concurrency and correctness policy for implementation

Concurrency changes must follow operation semantics rather than timer frequency:

- Search/typeahead and obsolete read-only queries may use cancellation/restart semantics after request cancellation is verified.
- Refresh and telemetry work may use droppable/coalesced execution when a newer snapshot supersedes an older one.
- Booking, offer acceptance, ride transitions, cash settlement, wallet/earnings, and authorization-sensitive operations must remain ordered, idempotent, and server-authoritative.
- The location spool must remain serialized so enqueue/flush cannot reorder or lose points.
- A realtime event and fallback snapshot must be deduplicated by the existing session/ride identity rules; changing concurrency must not create duplicate state emissions.

## 4. Performance Audit Matrix

| Component | Application | Issue | Evidence | Severity | Proposed optimization |
|---|---|---|---|---|---|
| Pre-render startup | Passenger and Driver | Independent and possibly noncritical initialization is serialized before `runApp`. | `apps/passenger/lib/src/app/passenger_bootstrap.dart:17-62`; `apps/driver/lib/src/app/driver_bootstrap.dart:18-67` | P1, strongly suspected; measure | Add startup timeline markers, identify the first-frame critical set, parallelize only independent work, and defer noncritical Mapbox/telemetry setup without delaying auth or active-ride recovery. |
| Active ride reconciliation | Passenger | A two-second task reads ride status and then driver location on each successful tick. | `apps/passenger/lib/src/features/active_ride/presentation/bloc/track_driver/track_driver_cubit.dart:72-261` | P1, strongly suspected; measure | Prefer authoritative realtime location/status where valid, coalesce a snapshot endpoint only if the contract preserves status and freshness, and use state-dependent cadence with a bounded foreground fallback. |
| Booking offer fallback | Passenger | Three-second snapshot refresh runs while realtime is connected or reconnecting. | `apps/passenger/lib/src/features/booking/presentation/bloc/booking/booking_bloc.dart:426-513` | P1, strongly suspected; measure | Keep fallback for recovery, but pause/back off it after healthy realtime delivery and use connection state plus server freshness to choose cadence. |
| Driver foreground work | Driver | High-accuracy stream, four-second ride polling, twenty-second presence heartbeat, and realtime are active while online. | `apps/driver/lib/src/features/dashboard/presentation/view/driver_dashboard_page.dart:438-477` | P1, strongly suspected; measure | Separate matching, presence, map display, and telemetry policies; make cadence adaptive to idle/offer/active-trip state while preserving server presence expiry and immediate realtime events. |
| Driver background work | Driver | Background service polls location every ten seconds, requests every four seconds, and presence every twenty seconds. | `apps/driver/lib/src/infrastructure/telemetry/driver_background_telemetry.dart:316-510`; constants at lines 14-16 | P1, strongly suspected; measure | Use an explicit state machine for online idle, offer pending, pickup, waiting, and active trip; retain only work Android can support and make recovery/reconciliation authoritative. |
| Location acquisition | Shared maps and Driver | High accuracy with a five-meter stream filter and approximately ten-meter current-position reads may increase GPS and wakeup cost. | `packages/maps/lib/src/device/device_location_service.dart:70-103`; background read at `driver_background_telemetry.dart:335-341` | P1, potential; measure | Define product-approved accuracy/freshness per state, adapt accuracy/distance/time limits, and test real tracking error before changing defaults. |
| Map marker replacement | Shared maps | Each replacement enumerates annotations, creates PNG bytes, and updates a Mapbox annotation; animation performs 18 updates. | `packages/maps/lib/src/map/map_annotation_service.dart:90-189`, `211-275` | P1, strongly suspected; measure | Cache marker bytes by immutable style key, retain one annotation handle, coalesce location updates, animate only visible/meaningful moves, and avoid camera movement for every sample. |
| Chat unread polling | Passenger and Driver | Active-ride screens refresh unread state about every four seconds. | Passenger `track_driver_page.dart:83-176`; Driver `pickup_navigation_page.dart`, `waiting_passenger_page.dart`, and `in_transit_page.dart` | P2, potential; measure | Prefer the existing chat/realtime stream or a shared unread cursor; keep a bounded fallback for reconnects and stop it when the screen is hidden. |
| Driver location spool | Driver | Complete JSON spool is decoded/encoded repeatedly; flush removes index zero and rewrites after each send. | `apps/driver/lib/src/infrastructure/telemetry/driver_location_spool.dart:41-111` | P2, verified allocation/I/O pattern; measure | Preserve FIFO and the 3600-point cap while batching successful removals and writes. Consider a storage format change only if traces show this path is material. |
| Driver dashboard rebuild scope | Driver | A broad `BlocBuilder` owns a large dashboard subtree; the dynamic feed requires lazy-list verification. | `apps/driver/lib/src/features/dashboard/presentation/view/driver_dashboard_page.dart:973-1135` | P2, potential; measure | Capture build counts and frame timings, then use `BlocSelector`/smaller builders and lazy builders only where the trace shows avoidable rebuild/layout work. |
| Location ingestion | Backend | Each accepted point checks presence before persistence and again after persistence, then resolves active rides and publishes one or more events. | `server/internal/location/tracking/location_tracking_service.go:81-156`; wiring at `server/internal/app/wiring.go:176-204` | P1, strongly suspected; measure | Add stage timings and counters first. If safe, use a repository operation that preserves the precondition and post-write freshness check without dropping authorization or stale-point protection. |
| Nearby-driver lookup | Backend/Redis | Expired-driver cleanup runs before every search, followed by GeoSearch, MGET, payload decoding, and stale-member cleanup. | `server/internal/location/tracking/driver_location_store.go:127-220` | P2, strongly suspected; measure | Measure cleanup cost and stale ratio; move cleanup to bounded background maintenance or a carefully scoped Redis script only if consistency and result-slot behavior remain equivalent. |
| Presence/profile lookup | Backend/PostgreSQL | Profile lookup can query the account, driver profile, and passenger profile fallback; presence validation can therefore add multiple reads. | `server/internal/user/adapter/postgres/profile_store.go:77-103` | P2, potential; measure | Use role-aware or single-query lookup only after plans confirm benefit; preserve not-found and role semantics. |
| Active bids endpoint | Backend/PostgreSQL | Driver-scoped active sessions validate online profile, count active rides, check overdue cash settlement, then list targeted sessions. | `server/internal/ride/adapter/postgres/bidding_store.go:120-187` | P1, strongly suspected under polling; measure | Trace per-query latency and pool wait; consolidate into one read/CTE or cache only when transaction visibility, online cutoff, settlement gate, and authorization remain equivalent. |
| PostgreSQL pool | Backend | Default pool is 25 max connections, zero minimum/warm connections, 30-minute max lifetime, and five-minute idle lifetime. | `server/internal/platform/database/postgres_pool.go:26-45` | P2, requires measurement | Record pool acquisition wait, active/idle counts, query latency, and database saturation; tune environment-specific values from evidence rather than changing defaults blindly. |
| Realtime fallback traffic | Passenger, Driver, Backend | Realtime and polling coexist by design for recovery, but total request/event volume is unknown. | Booking/driver polling paths and `server/internal/platform/websocket` | P1, requires measurement | Add connection-state, fallback-hit, duplicate-event, and request-count metrics; retain fallback where it is the recovery path. |
| Binary size/release startup | Android clients | ABI, native libraries, assets, and release shrinking have not been measured in this environment. | `apps/passenger/android/app/build.gradle.kts`, `apps/driver/android/app/build.gradle.kts`, manifests, Flutter package manifests | P3, requires measurement | Produce release AAB/APK size reports by ABI, inspect asset/native contributions, enable only safe shrinking/splitting, and compare startup separately from download size. |
| Runtime observability | All | No durable frame, startup, request, memory, battery, pprof, or query-plan baseline is available. | Audit environment and existing source inspection | P1 enabler | Add low-overhead, privacy-safe timing/counter hooks behind existing observability boundaries before changing hot paths. |

## 5. Root Cause Analysis

The following items are significant enough to receive individual implementation gates. “Observed” below means observed in source behavior; no item is presented as a measured production regression.

### 5.1 Serialized application startup

- **Sources/functions:** `bootstrapPassengerApp` and `bootstrapDriverApp` in the two bootstrap files listed above.
- **Source-observable behavior:** background-service stop, preferences access, environment loading, Sentry setup, dependency/router configuration, Mapbox service/token setup, and `MapProvider.initialize` occur before `runApp`.
- **Root cause:** the composition root currently treats all initialization as a pre-render critical path. The code does not expose stage timings or distinguish “must exist before first interactive frame” from “can be warmed after the frame.”
- **Expected benefit:** lower time to first rendered and interactive screen if independent/noncritical work is deferred or parallelized. The magnitude is **Not measured**.
- **Regression risks:** auth/session restoration may race navigation; active-ride recovery may be omitted; Mapbox-dependent routes may fail if initialization moves too far; background-service shutdown must remain safe. Preserve a minimal critical dependency graph and add startup tests for both authenticated and unauthenticated states.

### 5.2 Passenger active-trip polling and route work

- **Source/function:** `TrackDriverCubit` tracking operation and its `syncTracking` closure.
- **Source-observable behavior:** every two-second foreground task fetches status and then driver location. Route requests are separately gated to six seconds, and terminal status disposes the task.
- **Root cause:** status reconciliation and location freshness share one periodic loop even though they have different freshness/cost requirements; realtime can deliver overlapping information.
- **Expected benefit:** fewer HTTP requests, JSON decodes, bloc emissions, and route/map updates while maintaining authoritative recovery. **Not measured.**
- **Regression risks:** stale passenger UI, missing terminal transitions, incorrect driver marker position, or a bad transition during realtime loss. Any change must test realtime disconnect, background/foreground, server timeout, cancellation, completion, and stale generation handling.

### 5.3 Passenger offer fallback alongside realtime

- **Source/function:** `BookingBloc._subscribeToSession`, `_startOfferRefresh`, and `_loadOfferSnapshot`.
- **Source-observable behavior:** a three-second fallback snapshot task starts with the realtime subscription; reconnects can also trigger a snapshot. Overlap is guarded, but the fallback remains scheduled during healthy realtime.
- **Root cause:** recovery correctness is implemented as continuous polling rather than a connection-health/fallback policy.
- **Expected benefit:** fewer active-bid reads and state transformations during healthy websocket sessions; preserved recovery when the socket is unavailable. **Not measured.**
- **Regression risks:** missed offers, delayed auto-accept behavior, duplicate offer application, and session cross-talk. Keep session IDs, offer identity replacement, reconnect snapshot, and idempotency tests.

### 5.4 Driver location, matching, and presence cadence

- **Sources/functions:** `DriverDashboardPage._startPolling` and background telemetry `sendLocation`, `pollRideRequests`, `sendOnlinePresence`.
- **Source-observable behavior:** foreground high-accuracy stream plus four-second ride polling and twenty-second heartbeat; background service independently performs ten-second location reads, four-second request polling, and twenty-second heartbeat.
- **Root cause:** multiple concerns use fixed schedules even though idle, offer, pickup, waiting, and active-trip states have different freshness requirements. Foreground/background ownership is split by necessity but lacks a measured unified policy.
- **Expected benefit:** lower radio/GPS wakeups and server load during idle periods, with quicker updates in active-trip states if resources are allocated adaptively. **Not measured.**
- **Regression risks:** backend marks an online driver stale; driver misses a request; passenger sees stale position; duplicate telemetry occurs after process/lifecycle transitions. The server remains authoritative; add presence-expiry and reconnect acceptance tests before cadence changes.

### 5.5 Mapbox marker image and annotation churn

- **Sources/functions:** `MapAnnotationService.replaceMarker`, `_animateMarker`, `_markerOptions`, `_createMarkerImage`.
- **Source-observable behavior:** replacement reads annotations, renders marker PNG bytes, updates the annotation, and optionally runs 18 asynchronous updates with 20 ms delays. Image generation uses a `PictureRecorder` and text layout.
- **Root cause:** immutable visual data and mutable position/bearing are recomputed together; each location update can cross the plugin boundary multiple times.
- **Expected benefit:** lower Dart raster/PNG work and platform-channel traffic; smoother map interaction. **Not measured.**
- **Regression risks:** marker style collisions, wrong label/color/bearing, leaked image resources, marker ordering changes, jumpy motion, or a stale update overwriting a newer one. Cache only immutable bytes, preserve annotation ownership, and add marker replacement/animation tests.

### 5.6 Driver location spool serialization

- **Source/function:** `DriverLocationSpool.enqueue` and `flush`.
- **Source-observable behavior:** the complete JSON list is loaded from `SharedPreferencesAsync`, decoded, changed, and written. Flush writes after each item and uses `removeAt(0)`.
- **Root cause:** a bounded queue is represented as one repeatedly rewritten array, which makes each operation proportional to spool size and adds storage churn.
- **Expected benefit:** lower storage writes, JSON allocation, and flush latency during reconnection. **Not measured.**
- **Regression risks:** loss or reordering of telemetry after process death, concurrent enqueue/flush corruption, exceeding the cap, or retrying already accepted points. Keep the serialized operation chain, FIFO, cap, and “stop on first failed send” semantics.

### 5.7 Backend location ingestion

- **Source/function:** `LocationTrackingService.Ingest`.
- **Source-observable behavior:** validates context/coordinates/motion/age, verifies online presence, upserts location, verifies presence again, resolves active rides, and publishes events.
- **Root cause:** each point has a correctness-protective but potentially expensive sequence of Redis/database/cache reads and event fan-out. The cost scales with telemetry frequency and active assignments.
- **Expected benefit:** lower per-point latency and database/Redis load if equivalent atomic or cached checks are proven safe. **Not measured.**
- **Regression risks:** accepting offline drivers, overwriting fresh data with stale points, missing ride-scoped events, publishing after cancellation, or weakening authorization. Do not remove validation based on call count alone.

### 5.8 Redis nearby lookup cleanup

- **Source/function:** `DriverLocationStore.Nearby` and `cleanupExpiredDrivers`.
- **Source-observable behavior:** an expiry sweep runs before every GeoSearch; up to 20 members are fetched, payloads are MGET-decoded, and stale members are cleaned in a transaction.
- **Root cause:** consistency cleanup is coupled to the read path, so search latency includes maintenance cost even when the expired set is large.
- **Expected benefit:** more predictable nearby-driver latency and fewer repeated cleanup operations. **Not measured.**
- **Regression risks:** expired drivers occupying result slots, stale presence being shown as available, cleanup races, or Redis memory growth. Any background cleanup must preserve bounded stale filtering in the read path.

### 5.9 PostgreSQL lookup shape and pool behavior

- **Sources/functions:** `ProfileRepository.Get`, `RideRepository.ActiveSessions`, `DefaultPostgresNativePoolConfig`, and corresponding SQL under `server/database/queries`.
- **Source-observable behavior:** profile lookup may execute account plus driver/passenger profile queries. Driver active-bid polling can execute online-profile, active-ride count, overdue-settlement, and active-session queries. The pool has configurable but unmeasured defaults.
- **Root cause:** policy gates are represented as sequential repository calls. This preserves readability and correctness but can multiply latency under polling.
- **Expected benefit:** lower p95 endpoint latency and pool pressure through measured query consolidation/index improvements, if plans support it. **Not measured.**
- **Regression risks:** changed transaction visibility, incorrect online cutoff, settlement bypass, role leakage, longer locks, or greater write cost from unjustified indexes. Use representative data and `EXPLAIN ANALYZE`; do not add indexes from naming alone.

## 6. Optimization Roadmap

### P0 — Critical, only if runtime evidence promotes a finding

No P0 performance defect is verified in this audit. Promote a finding to P0 only when a reproducible trace or test demonstrates one of the following:

- active ride tracking stops, presents invalid state, or cannot recover after lifecycle/network changes;
- a controller, subscription, timer, service, or websocket is retained after its owner is disposed and causes an unbounded leak;
- a user action blocks the UI isolate long enough to prevent interaction or a critical booking/ride transition;
- an optimization introduces a booking, fare, cash settlement, wallet, presence, authorization, or safety correctness defect.

P0 response: stop optimization rollout, preserve server authority, add a focused regression test, revert the responsible change, and collect a profile/reproduction before continuing.

### P1 — High priority

1. Instrument startup and first-frame/interactivity stages in both bootstraps.
2. Instrument request counts/bytes/latency, fallback-hit rate, realtime connection state, location update rate, and active-trip freshness.
3. Measure Passenger active-trip status/location traffic and offer fallback traffic under healthy realtime, degraded network, and reconnect conditions.
4. Measure Driver foreground/background GPS, request polling, presence heartbeat, duplicate telemetry, and backend online-expiry behavior in idle, offer, pickup, waiting, and active-trip states.
5. Profile Mapbox marker update frequency, PNG generation time, platform-channel calls, UI/raster frame timing, and camera movement.
6. Only after baseline data, implement the smallest approved adaptive cadence/coalescing change with state and lifecycle tests.
7. Add backend stage timings for location ingestion and active-bid reads; measure Redis command latency and PostgreSQL pool wait before restructuring queries.

### P2 — Medium priority

1. Optimize driver spool writes if storage/JSON profiles show material cost.
2. Narrow Driver Dashboard rebuild scopes and lazy-list construction only where build/frame traces identify work.
3. Replace duplicate chat unread polling with a shared stream/cursor or bounded fallback if request counts justify it.
4. Evaluate profile and active-bid query consolidation with query plans and contract tests.
5. Evaluate Redis expiry maintenance decoupling while retaining read-time stale filtering.
6. Add memory-retention tests for navigation, maps, booking cancellation/completion, and background/foreground cycles.

### P3 — Low priority

1. Produce release APK/AAB size and startup reports by ABI.
2. Inspect asset/font/native-library contributions and safe tree-shaking/shrinking opportunities.
3. Apply small `const`/widget decomposition changes only when the frame/build trace shows a benefit.
4. Do not add isolates for JSON parsing or route work until payload sizes and UI timeline evidence justify the complexity.

## 7. Measurement and Benchmark Protocol

All baseline and after measurements must use the same app commit, device, OS, build mode, network profile, account fixtures, location traces, and backend dataset. Use profile/release builds for runtime claims; debug numbers are diagnostic only.

### Instrumentation to add before optimization

- **Flutter startup:** `dart:developer` timeline events around bootstrap stages; first-frame callback/timing; explicit markers for auth restoration, initial route visibility, and interactive controls.
- **Flutter frames:** `FrameTiming`/DevTools UI and raster timing, build counts for suspected widgets, Mapbox update counters, and route request counters.
- **Network:** request name, start/end, status, bytes, retry count, cancellation, connection state, and correlation ID; exclude tokens and personal data.
- **Location:** requested/received GPS interval, distance, accuracy, stale age, dropped/coalesced samples, sent telemetry count, and active-trip display age.
- **Memory:** snapshots at defined lifecycle checkpoints plus retained-object checks for controllers, subscriptions, timers, bloc instances, annotations, and map resources.
- **Backend:** middleware/request duration, handler/service/repository stage duration, status code, payload size, context cancellation, websocket events, and pprof profiles under a controlled load.
- **PostgreSQL/Redis:** query duration, pool acquisition wait, rows/bytes, lock wait, Redis command duration, key counts, stale cleanup count, and cache hit/miss. Never log user secrets or raw location unnecessarily.

### Required scenarios

| Scenario | Passenger | Driver | Backend/data |
|---|---:|---:|---:|
| Cold startup, signed out | Yes | Yes | Config/auth endpoints as applicable |
| Cold startup, authenticated with no active ride | Yes | Yes | Session/profile reconciliation |
| Warm resume | Yes | Yes | Reconnect and stale-session behavior |
| Passenger search and booking | Yes | No | Route, bid session, offer delivery |
| Driver online idle | No | Yes | Presence, nearby/matching, Redis |
| Driver receives and handles offer | No | Yes | Active bids and transition endpoints |
| Passenger watches pickup/live trip | Yes | Yes | Location ingestion and realtime fan-out |
| Waiting/arrival/start/complete/cash settle | Yes | Yes | Ride lifecycle and settlement gates |
| Cancellation and recovery | Yes | Yes | Idempotent transitions and reconciliation |
| Background/foreground and screen lock | Yes | Yes | Android lifecycle/foreground service |
| Wi-Fi/mobile switch, high latency, packet loss, offline, restart | Yes | Yes | Retry, reconnect, timeout, pool/cache behavior |
| Ten repeated navigation/map/booking cycles | Yes | Yes | Memory retention and resource disposal |

### Proposed acceptance gates

These are proposed release gates, not current measurements. Product and operations owners must approve exact thresholds where business freshness requirements are not yet formalized.

| Metric | Baseline | Proposed gate after an approved change |
|---|---|---|
| Cold/warm startup to first frame and interactive screen | Not measured | No regression; target at least 15% relative improvement for a startup change, with auth and active-ride recovery intact |
| Frame timing during scroll/map/transition | Not measured | 95th-percentile UI and raster frame within the device refresh budget; no new sustained jank in the same trace |
| Navigation/input latency | Not measured | No regression; target at least 15% relative improvement for a navigation change |
| API latency p50/p95/p99 | Not measured | No p95/p99 regression for correctness paths; target reduction for the measured endpoint only |
| Request count and bytes per scenario | Not measured | Reduced only where fallback/recovery semantics remain covered; no duplicate transactional requests |
| Retained memory after ten lifecycle cycles | Not measured | No monotonic growth; retained heap returns to an approved band around baseline |
| CPU/GPU/battery/thermal | Not measured | Lower or non-regressing resource use in the targeted scenario; active-trip freshness/accuracy preserved |
| GPS frequency/accuracy/staleness | Not measured | Must meet product-approved state-specific freshness and accuracy; lower frequency alone is not success |
| Reconnection to valid state | Not measured | No correctness regression; p95 recovery target is established from baseline before changing policy |
| PostgreSQL/Redis pool and command latency | Not measured | No saturation or error-rate regression; improvements must be shown on representative data |
| AAB/APK download/install/runtime size | Not measured | Report separately by ABI; size reduction must not remove required native code/assets |

## 8. Before-and-After Benchmark Report

No implementation change or device/backend benchmark has been performed in this audit. The table below is intentionally populated with `Not measured` rather than invented values and is the template to complete for each approved change.

| Area | Before | After | Improvement | Test conditions |
|---|---|---|---|---|
| Cold startup | Not measured | Not measured | Not measured | Profile/release, physical Android device, signed-out and authenticated runs |
| Warm startup/resume | Not measured | Not measured | Not measured | Same device, process alive and process-death cases |
| UI/raster frame timing | Not measured | Not measured | Not measured | Scroll, route transition, map pan, marker update, 60/90 Hz as applicable |
| Jank/missed frames | Not measured | Not measured | Not measured | Same deterministic interaction trace |
| Navigation/input latency | Not measured | Not measured | Not measured | Tap-to-visible and tap-to-interactive timestamps |
| Passenger tracking API p50/p95/p99 | Not measured | Not measured | Not measured | Active trip, healthy realtime and fallback network conditions |
| Passenger offer request count/bytes | Not measured | Not measured | Not measured | One booking session, healthy/reconnecting websocket |
| Driver foreground request count/bytes | Not measured | Not measured | Not measured | Online idle, offer, pickup, waiting, active trip |
| Driver background request/GPS frequency | Not measured | Not measured | Not measured | Screen locked/background, supported Android service mode |
| Map annotation update/image time | Not measured | Not measured | Not measured | Marker-only and camera-follow traces |
| Memory baseline/peak/retained heap | Not measured | Not measured | Not measured | Ten navigation/map/booking/lifecycle cycles |
| CPU/GPU utilization | Not measured | Not measured | Not measured | Idle, active map, active trip, background |
| Battery/thermal consumption | Not measured | Not measured | Not measured | Fixed duration and battery state on the same physical device |
| Reconnect recovery | Not measured | Not measured | Not measured | Wi-Fi/mobile switch, timeout, backend restart |
| Backend endpoint p50/p95/p99 | Not measured | Not measured | Not measured | Controlled representative load with tracing enabled |
| PostgreSQL plans/pool wait | Not measured | Not measured | Not measured | Representative nonproduction data and `EXPLAIN ANALYZE` |
| Redis latency/memory/stale cleanup | Not measured | Not measured | Not measured | Representative driver population and expiry distribution |
| APK/AAB size by ABI | Not measured | Not measured | Not measured | Clean release build, same signing/resource set |

## 9. File-Level Implementation Plan

Every item below is TODO until separately approved and measured. A change should be implemented as one logical slice, validated, compared with baseline, and reverted or revised if its targeted metric does not improve without a compensating benefit.

| Affected files/areas | Required modification | Expected effect | Dependencies | Testing and regression requirements |
|---|---|---|---|---|
| `apps/passenger/lib/src/app/passenger_bootstrap.dart`; Passenger startup tests | Add stage timeline markers and classify critical versus deferred initialization. Parallelize only independent work after dependency tracing; defer noncritical Mapbox/Sentry work only when safe. | Reduce time to first frame/interactivity. | Startup trace and authenticated/active-ride dependency map. | Cold/warm startup, auth restoration, active-trip recovery, map route entry, error fallback. |
| `apps/driver/lib/src/app/driver_bootstrap.dart`; Driver startup tests | Add equivalent markers; preserve driver session decision and background-service startup/stop semantics. | Reduce Driver startup without showing an invalid online state. | Driver session and Android lifecycle evidence. | Signed-out/session startup, online recovery, background process restart, first-frame timings. |
| `apps/passenger/lib/src/features/active_ride/presentation/bloc/track_driver/track_driver_cubit.dart`; active-ride repositories/API contracts | Replace fixed work only after measuring with state/realtime-aware status/location cadence or a safe snapshot read. Keep terminal reconciliation and stale guards. | Lower request/emission/map work while preserving trip truth. | Realtime health/freshness metrics; backend contract review. | Realtime loss, timeout, background/foreground, cancel/complete, stale generation, route retry. |
| `apps/passenger/lib/src/features/booking/presentation/bloc/booking/booking_bloc.dart`; realtime client/state tests | Make the three-second offer refresh a bounded fallback driven by connection health and last authoritative event. Keep reconnect snapshot and session identity. | Reduce duplicate offer requests and parsing. | Realtime event delivery metrics and offer contract. | Offer ordering, auto-accept, reconnect, duplicate event, session switch, server timeout. |
| `apps/driver/lib/src/features/dashboard/presentation/view/driver_dashboard_page.dart`; `driver_background_telemetry.dart`; Android service/lifecycle code | Introduce a measured, state-specific cadence policy for matching, telemetry, presence, and UI. Keep server expiry and foreground/background reconciliation. | Reduce GPS/radio/CPU use in idle while protecting active-trip freshness. | Product-approved freshness/presence requirements and Android support matrix. | Idle, offer, pickup, waiting, active trip, screen lock, Doze/permission loss, process death, reconnect. |
| `packages/maps/lib/src/device/device_location_service.dart`; Driver location callers | Add policy inputs or state-owned settings only if measurements show fixed high accuracy is excessive. Preserve access-state errors and current-position fallback. | Reduce battery/GPS cost without unsafe stale locations. | GPS accuracy/staleness baseline and product approval. | Accuracy, distance, stale sample, permission change, background/foreground, active trip. |
| `packages/maps/lib/src/map/map_annotation_service.dart`; maps tests | Cache immutable marker PNG bytes, retain/update the owned annotation, coalesce stale updates, and bound animation overlap. Do not cache mutable coordinates. | Reduce PNG/raster/platform-channel work and map jank. | Marker style key definition and Mapbox lifecycle evidence. | Marker style/label/bearing/origin, animation cancellation, rapid updates, disposal, multiple annotations. |
| `apps/driver/lib/src/infrastructure/telemetry/driver_location_spool.dart`; spool tests | Batch successful removals/writes or change representation only after profiling. Keep serialized operation chain, FIFO, cap, and retry semantics. | Reduce JSON/storage churn during offline/reconnect periods. | Spool depth and storage timing profile. | Enqueue/flush interleaving, failed send, process interruption fixture, cap eviction, malformed storage. |
| Driver Dashboard widgets around `BlocBuilder` and feed list | Capture build counts first; then narrow state subscriptions and use lazy item construction where justified. | Reduce unnecessary rebuild/layout work. | Flutter frame/build trace. | Existing dashboard widget tests, offer transitions, online/offline, scrolling, keys, accessibility. |
| Passenger/Driver active-ride chat screens and chat realtime repository | Replace repeated unread reads with shared realtime/cursor state plus bounded fallback if measured. | Reduce active-trip request volume and small state rebuilds. | Chat event/unread contract and reconnect behavior. | Unread increment/clear, chat open/close, reconnect, screen disposal, active ride transitions. |
| `server/internal/location/tracking/location_tracking_service.go`; location repository/ports | Add stage timings and counters. Consider a combined presence/persist operation only after proving equivalent authorization, stale-point, and post-write checks. | Lower per-location latency and backend load. | Load profile, Redis/database contract, event ordering review. | Existing location unit/integration tests, stale/offline points, active assignment fan-out, cancellation/context. |
| `server/internal/location/tracking/driver_location_store.go`; Redis scripts/tests | Measure expiry sweep/stale ratio. If justified, move bounded cleanup off the hot read path while retaining read-time validation and result-slot protection. | Improve nearby lookup tail latency and Redis predictability. | Redis benchmark and expiry consistency design. | Expiry races, stale payloads, empty/20-result searches, transient Redis failure, memory behavior. |
| `server/internal/user/adapter/postgres/profile_store.go`; `server/database/queries/users.sql` and generated code | Evaluate a role-aware/single-query profile lookup only with plans and contract tests. Regenerate sqlc artifacts through the repository workflow if SQL changes. | Reduce presence/profile database round trips. | Representative schema/data and query plans. | Driver/passenger role, missing profile, authorization, transaction visibility, error mapping. |
| `server/internal/ride/adapter/postgres/bidding_store.go`; `server/database/queries/bidding.sql`; indexes only if justified | Measure each active-bid gate, then consolidate or index only when `EXPLAIN ANALYZE` and write-cost review support it. | Reduce polling endpoint p95 and pool pressure. | PostgreSQL runtime and settlement/availability policy review. | Online cutoff, active ride, overdue cash settlement, targeted sessions, concurrent acceptance, no contract change. |
| `server/internal/platform/database/postgres_pool.go`; server metrics/config | Add pool acquisition/usage metrics and tune environment values from evidence. Avoid changing defaults without saturation data. | Avoid pool starvation and unnecessary connection churn. | PostgreSQL runtime and deployment capacity. | Pool config tests, timeout/cancellation, restart, concurrent polling/load test. |
| `server/internal/platform/websocket`, HTTP middleware, app telemetry boundary | Add privacy-safe correlation IDs and timing counters for websocket/fallback/request paths. | Distinguish client, transport, handler, database, and Redis latency. | Existing logging/observability policy. | No token/location leakage, cancellation, reconnect, error-rate stability, sampling overhead. |
| `apps/passenger/android/app/build.gradle.kts`, `apps/driver/android/app/build.gradle.kts`, manifests, package assets | Build clean release AAB/APKs, report ABI/native/assets contributions, and apply only safe shrinking/splitting. | Reduce install/download size and potentially startup work. | Writable Gradle cache, release signing/build environment. | Install/launch, Mapbox/location plugins, background service, crash/resource regression, size by ABI. |

### Implementation sequencing and stop boundaries

1. **Baseline and instrumentation:** no behavior change. Stop if metrics cannot distinguish client, network, backend, or data-store time.
2. **One client hot path:** choose either Passenger offer fallback, Passenger tracking, or Driver telemetry after baseline. Keep the change isolated and compare request/freshness/frame/resource metrics.
3. **Map path:** only after marker/image/platform traces show cost. Cache immutable assets first; do not alter tracking cadence in the same change.
4. **Backend path:** only after endpoint and query traces show a stage is material. Preserve validation and transaction boundaries; use contract and integration tests.
5. **Release/build path:** measure size and startup independently. Do not infer runtime improvement from APK reduction.
6. **Rollback:** revert a slice if its target metric does not improve, if tail latency/resource use regresses, or if any ride/tracking/lifecycle test fails.

## 10. Critical Business-Flow Regression Checklist

Every change affecting timing, polling, realtime, storage, or lifecycle must revalidate:

- Passenger authentication and session restoration.
- Driver authentication and session restoration.
- Passenger booking creation and duplicate-submit protection.
- Driver offer visibility and submission.
- Offer acceptance, direct assignment, matching, and idempotent retry.
- Live pickup/trip tracking, route/marker freshness, and location permissions.
- Arrival confirmation, ride start, completion, and cash settlement consistency.
- Passenger/driver cancellation and terminal-state reconciliation.
- Driver online/offline transitions and backend presence expiry.
- Wallet/earnings and fare/commission contracts remain unchanged.
- Chat unread/read state and active-ride navigation.
- Foreground/background, screen lock, network loss, backend restart, and process-death recovery.

No optimization may weaken authentication/session security, server-authoritative ride state, cash/settlement correctness, location authorization, or safety-related freshness without an explicit product/security decision.

## 11. Final Performance Validation

### Static and test validation already completed

The pre-existing audit work completed the following repository checks:

- `go vet ./...` — passed.
- `go test -count=1 -shuffle=on ./...` — passed in the available environment.
- Melos/Dart analysis for the five Flutter/Dart packages and both applications — passed.
- Flutter tests: Passenger 315, Driver 173, Maps 34, Foundation 89, Design System 30 — passed.

These checks establish code/test health for the inspected revision; they do not establish frame rate, startup, battery, network, database, or release-build performance.

### Runtime validation not completed

- Physical profile/release device run: **Not measured**.
- Flutter frame/UI/raster timeline: **Not measured**.
- Flutter memory snapshots/leak cycle: **Not measured**.
- CPU/GPU/battery/thermal scenarios: **Not measured**.
- Network p50/p95/p99/request count/bytes: **Not measured**.
- GPS update frequency/accuracy/staleness: **Not measured**.
- Reconnect recovery timing: **Not measured**.
- Go pprof/tracing: **Not measured**.
- PostgreSQL query plans, pool wait, locks: **Not measured**; PostgreSQL was unavailable.
- Redis latency, memory, and expiry behavior: **Not measured**; Redis/Docker was unavailable.
- Release APK/AAB size and Gradle verification: **Not measured**; the Gradle wrapper cache was read-only.

### Environment limitations and disposition

`adb devices -l` could not start its daemon because socket creation was denied. Docker socket access was denied, so PostgreSQL/Redis-backed runtime tests could not run. These are environment limitations, not application failures. The implementation phase must rerun the benchmark protocol on a physical Android device and controlled backend/data services before claiming an optimization.

### Document-scope validation

After this document is written, run `git diff --check` and verify that the only new file from this task is `PERFORMANCE_AUDIT_PLAN.md`. Do not stage or commit unrelated pre-existing changes.

## 12. Completion Definition

This plan is complete as an audit artifact when:

- every behavior claim is labeled as source evidence, hypothesis, existing protection, or runtime measurement;
- no unavailable benchmark is represented as a value;
- each approved optimization has an owner file, acceptance metric, regression suite, and rollback boundary;
- changes are implemented one logical slice at a time;
- before/after measurements use the same conditions;
- critical ride, payment/settlement, authentication, tracking, lifecycle, and safety flows remain green;
- remaining bottlenecks are recorded here with evidence rather than hidden by refactoring.
