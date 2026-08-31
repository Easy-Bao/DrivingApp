# Architecture refactor progress

This log records ownership decisions and validation for the production architecture refactor.

## Completed

| Module | Before | Actual responsibility | After | Reason | Tests | Remaining risk |
| --- | --- | --- | --- | --- | --- | --- |
| theme composition | Shared package exposed the client `ThemeData` and a selectable appearance surface | Client palette, typography, semantic colors, and generic UI styling | Each client owns `src/app/theme/app_theme.dart` and exposes only `AppTheme.data`; design_system retains semantic tokens and generic context helpers | Keep the default appearance app-local without creating a shared theme or selection API | Design-system suite: 17 passed; Passenger and Driver app-theme suites: 3 passed each | Final monorepo validation should confirm no shared `ThemeData` remains |
| foundation | `shared_core` mixed generic infrastructure with app/domain exports | Generic failures, lifecycle, network, realtime, and route-payload utilities | `foundation` owns the technical subset and all app consumers import it directly | Give technical dependencies a focused shared owner | Foundation tests passed; both app analyses have no errors | Review app-wide infrastructure placement during the `core` migration |
| maps | Map/location capability was mixed into `shared_core` and app-local duplicates | Provider/platform map, location, geocoding, and route capability | `maps` owns the shared provider boundary | Both apps use the same provider capability without sharing workflow state | Maps package tests passed | Review app-specific map behavior still importing shared helpers |
| app infrastructure | Each client kept configuration, transport, session, telemetry, and unrelated helpers under `src/core` | App-wide external-system adapters versus feature-owned validation and presentation formatting | Each client now owns config, API client/interceptor, session store, storage keys, and background telemetry under `src/infrastructure`; auth endpoints and helpers live with their features; `src/core` and dead `SecureStorage` adapters were removed | Make the application boundary explicit without turning infrastructure into a product-feature dumping ground | Passenger client: 178 passed; Driver client: 106 passed; both analyses report no errors or warnings | Root composition files still need their final `src/app` placement |
| shared core models | `shared_core` exposed generic foundation exports plus Driver, Profile, and Notification models | Passenger nearby-driver discovery and each client’s profile workflows | Passenger booking owns `DriverModel`, each profile feature owns `ProfileModel`, unused notifications were removed, and `shared_core` was deleted | Remove the compatibility package and keep product models with their owning features | Passenger profile/booking tests passed; Driver profile tests passed; both analyses have no errors | Finalize the remaining app-shell placement |
| passenger booking and active ride | Passenger `trip` mixed booking and accepted-ride tracking | Booking, driver discovery, fare display, offers, and draft state versus live tracking and driver match | `booking` and `active_ride` feature boundaries | Make the passenger lifecycle explicit and independently navigable | Passenger app tests: 165 passed | Activity/history split remains |
| driver active ride | Driver `trip` contained the accepted-ride lifecycle | Dispatch acceptance, pickup, passenger wait, transit, telemetry, and fare summary | `active_ride` feature boundary | Match the business concept used by the server and passenger app | Driver app tests: 90 passed; analysis clean | Dashboard rename and activity split remain |
| auth | Shared package provided transport contracts, failures, and presentation events while apps owned role-specific repositories | Authentication transport, failures, credentials, repositories, and presentation state | Passenger and Driver auth features own their complete workflows; `packages/auth` removed | Keep authentication changes role-specific and remove product behavior from shared packages | Passenger auth: 22 passed; Driver auth: 7 passed | Shared session and infrastructure ownership still needs the broader `core` migration |
| chat | Shared package owned chat entities, repository, failure, and transport | Chat room lifecycle, message protocol, websocket reconnect, and presentation state | Passenger and Driver `chat` features own their data, domain, repository, factory, and tests; `packages/chat` removed | Keep chat as a product workflow while leaving only generic transport candidates for shared infrastructure | Passenger chat: 12 passed; Driver chat: 12 passed; Passenger analysis has no errors; Driver analysis clean | Review websocket transport duplication during the later infrastructure pass |
| ride | Shared package owned ride entities, DTOs, fare structures, and workflow failures | Passenger booking/fare/history contracts and Driver active-ride lifecycle contracts | Passenger booking, activity, and active-ride features plus Driver active-ride own the required contracts; `packages/ride` removed | Keep client workflows local while the server remains authoritative for fare and ride rules | Passenger affected features: 95 passed; Driver affected features: 42 passed; both analyses have no errors | Continue removing remaining `shared_core` product models and review cross-feature model dependencies |

## In progress

| Module | Before | Actual responsibility | After | Reason | Tests | Remaining risk |
| --- | --- | --- | --- | --- | --- | --- |

## Pending

- rename driver `home` to `dashboard`
- split driver activity into the smallest useful earnings, performance, and history owners
- classify and simplify server integration/realtime structure without editing generated persistence output
- run final monorepo analysis, client tests, and server tests; record pre-existing failures separately
