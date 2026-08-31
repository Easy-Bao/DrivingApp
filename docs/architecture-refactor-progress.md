# Architecture refactor progress

This log records ownership decisions and validation for the production architecture refactor.

## Completed

| Module | Before | Actual responsibility | After | Reason | Tests | Remaining risk |
| --- | --- | --- | --- | --- | --- | --- |
| theme and appearance | Apps exposed selectable dark/system appearance through shared theme code | Fixed light visual contract, persisted appearance selection, and appearance settings were product behavior | Dark rendering paths and appearance settings removed; app-local theme ownership still pending | Keep the current product light-only while removing a user-facing option that no longer exists | Shared, passenger, and driver focused theme/settings tests passed | `ThemeData` still needs to leave the shared design-system package |
| foundation | `shared_core` mixed generic infrastructure with app/domain exports | Generic failures, lifecycle, network, realtime, and route-payload utilities | `foundation` owns the technical subset; compatibility exports remain temporarily | Give technical dependencies a focused shared owner | Foundation and compatibility-package tests passed | Remove `shared_core` after remaining app consumers migrate |
| maps | Map/location capability was mixed into `shared_core` and app-local duplicates | Provider/platform map, location, geocoding, and route capability | `maps` owns the shared provider boundary | Both apps use the same provider capability without sharing workflow state | Maps package tests passed | Review app-specific map behavior still importing shared helpers |
| passenger booking and active ride | Passenger `trip` mixed booking and accepted-ride tracking | Booking, driver discovery, fare display, offers, and draft state versus live tracking and driver match | `booking` and `active_ride` feature boundaries | Make the passenger lifecycle explicit and independently navigable | Passenger app tests: 165 passed | Activity/history split remains |
| driver active ride | Driver `trip` contained the accepted-ride lifecycle | Dispatch acceptance, pickup, passenger wait, transit, telemetry, and fare summary | `active_ride` feature boundary | Match the business concept used by the server and passenger app | Driver app tests: 90 passed; analysis clean | Dashboard rename and activity split remain |
| auth | Shared package provided transport contracts, failures, and presentation events while apps owned role-specific repositories | Authentication transport, failures, credentials, repositories, and presentation state | Passenger and Driver auth features own their complete workflows; `packages/auth` removed | Keep authentication changes role-specific and remove product behavior from shared packages | Passenger auth: 22 passed; Driver auth: 7 passed | Shared session and infrastructure ownership still needs the broader `core` migration |

## In progress

| Module | Before | Actual responsibility | After | Reason | Tests | Remaining risk |
| --- | --- | --- | --- | --- | --- | --- |
| chat | Shared package owns chat entities, repository, failure, and transport | Chat is product workflow in both apps, not generic infrastructure | Keep app-local chat state/repositories/pages; share only generic realtime transport | Avoid cross-client feature coupling | Targeted validation pending | Compare both implementations before removing the shared package |
| ride | Shared package owns ride entities, DTOs, fare structures, and failures | Passenger and Driver use different ride workflows | Move ride domain/data contracts into the owning app features; retain only generic infrastructure | Server remains authoritative for ride and fare rules | Targeted validation pending | Avoid changing API payloads or status transitions |

## Pending

- localize theme definitions while retaining shared brand tokens and generic components
- rename driver `home` to `dashboard`
- split driver activity into the smallest useful earnings, performance, and history owners
- remove `shared_core`, `packages/chat`, and `packages/ride` after reference and export audits
- classify and simplify server integration/realtime structure without editing generated persistence output
- run final monorepo analysis, client tests, and server tests; record pre-existing failures separately
