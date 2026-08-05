---
name: flutter-bloc-clean-architecture
description: Build and refactor Flutter features in this driving-app monorepo with sealed immutable BLoCs, feature-first clean architecture, injected repositories and data sources, design-system consistency, and go_router_modular navigation. Use when creating screens, widgets, state management, API integrations, feature modules, or reorganizing existing Flutter code.
---

# Flutter BLoC Clean Architecture

Use this skill for new or substantially refactored Flutter features. Preserve
existing behavior and local conventions while moving new work toward the
boundaries below. Do not migrate unrelated legacy Cubits merely to satisfy the
structure; migrate them only when the task requires a feature-level refactor.

## Repository-specific conventions

- Driver and passenger apps are under `apps/`; reusable behavior belongs in
  `packages/`.
- Driver application source is under
  `apps/driver_app/lib/src/features/<feature>/`.
- The established feature layers are `data`, `domain`, and `presentation`.
- Remote and local SDK calls belong in `data/data_sources/`. Repositories map
  data models and translate failures for the domain layer.
- Use injected `Dio` for new HTTP data sources. Do not instantiate a client or
  read environment values from a screen, widget, BLoC, or repository.
- Repository and use-case contracts use `Either<Failure, T>` from `fpdart`.
  Do not leak raw exceptions or nullable success values across a domain
  boundary.
- Register dependencies with the existing Modular modules and constructor
  injection. Use `Modular.get` only at composition boundaries such as module
  route builders, not inside feature business logic or reusable widgets.
- The current design system is `AppTheme` and the active `ThemeData` text
  theme. Use `Theme.of(context).colorScheme`, `textTheme`, and the shared theme
  constants. If a spacing, radius, or typography token is missing, add it to a
  central design-system API before reusing it; do not create a second ad hoc
  token namespace or scatter literal values through new screens.

## Feature structure

For new work, use this shape and keep dependencies pointing inward:

```text
features/<feature>/
├── data/
│   ├── data_sources/       # HTTP, WebSocket, storage, location adapters
│   ├── models/             # serialization DTOs
│   └── repositories/       # domain repository implementations
├── domain/
│   ├── entities/           # immutable business objects
│   ├── repositories/       # abstract contracts returning Either
│   └── use_cases/          # one business operation per class when useful
└── presentation/
    ├── bloc/<bloc_name>/   # one nested directory per BLoC
    ├── screens/
    └── widgets/
```

Keep UI-only pieces in `presentation`. Keep mapping, retry policy, caching,
and data-source coordination in `data`. Keep business rules independent of
Flutter, routing, HTTP, storage, and map SDK types in `domain`.

## Choose the implementation scope

- **New screen or feature:** define the domain contract, data source/model,
  repository, BLoC, module registration, route, screen, widgets, and focused
  tests. Do not put the whole feature in a screen file.
- **New reusable widget:** place feature-specific widgets under that feature;
  place a widget in a shared package only after confirming two or more real
  consumers. Widgets dispatch events and render state; they do not orchestrate
  data access.
- **Data integration:** add or extend a data source and repository. Inject the
  configured client and map transport failures before the BLoC sees them.
- **Refactor:** trace callers first, preserve public contracts, separate map
  rendering state from ride/business state, and avoid broad mechanical moves.

## BLoC contract

Every new feature BLoC must use the official part-file pattern and a nested
directory:

```text
presentation/bloc/earnings/
├── earnings_bloc.dart
├── earnings_event.dart
└── earnings_state.dart
```

The library file owns the declarations:

```dart
part 'earnings_event.dart';
part 'earnings_state.dart';

class EarningsBloc extends Bloc<EarningsEvent, EarningsState> {
  // Inject a repository or use case; never call an API from here indirectly
  // through a service locator hidden inside the handler.
}
```

The companion files begin with `part of 'earnings_bloc.dart';`. Events and
states are `sealed`, immutable, and Equatable (or generated with an equivalent
immutable value implementation). Give every field a `final` declaration and
define complete `props`. Prefer explicit state variants such as `Initial`,
`Loading`, `Success`, and `Failure` so the UI can handle every state
exhaustively.

Use a full `Bloc<Event, State>` for new features with multiple user/system
events or asynchronous workflows. An existing `Cubit` remains acceptable for
a small, single-purpose state machine or while making a narrowly scoped fix;
do not mix a Cubit migration into unrelated feature work.

### Async and concurrency rules

1. Emit a loading state before every asynchronous operation.
2. Await exactly one repository/use-case operation per handler where practical.
3. Fold `Either` results into success or failure states; map unexpected errors
   to a safe, user-facing failure without exposing tokens, stack traces, or
   transport details.
4. Use an event transformer such as `restartable()` for latest-value searches
   and `droppable()` for repeatable actions that must not overlap. Confirm the
   transformer dependency in the app package before adding or using it.
5. Cancel subscriptions, timers, location streams, and map resources in
   `close()` or the owning repository lifecycle.

The UI may listen for navigation, dialogs, and other side effects with
`BlocListener`; those effects must not be hidden inside a BLoC. Use
`BlocBuilder` for state rendering and `BlocConsumer` only when both are needed.

## Data and domain boundaries

Use this flow:

```text
widget event → BLoC → use case/repository → data source
             ← state  ← domain result     ← mapped response
```

- Data sources own HTTP, WebSocket, persistence, location, and map SDK calls.
- Models parse and serialize transport data; domain entities do not know JSON.
- Repository implementations combine sources, apply caching/retry policy, and
  convert exceptions into `Failure` values.
- Domain repository contracts contain no Flutter, Dio, Modular, or SDK types.
- BLoCs receive repositories/use cases through constructors.
- Screens never call `Dio`, `Modular.get`, storage, location, map, or socket
  APIs directly.

For continuous telemetry, throttle/debounce and reconnect behavior in the BLoC
or repository, not in a widget `State` or `build` method. For ride features,
keep the trip lifecycle BLoC separate from a live-map BLoC that owns camera,
markers, polylines, and location rendering. Coordinate them through listeners
and typed events rather than sharing mutable map state.

## Modular navigation and dependency injection

This repository uses `go_router_modular`, not the standalone `go_router`
configuration API. Do not introduce `GoRouter`, `GoRoute`, or a second router
stack for a feature.

- Define route names and paths in the feature's static `*_routes.dart` file.
- Declare `ChildRoute` and module `routes`/`shellRoutes` in the feature module.
- Use `context.goNamed` or `context.pushNamed` with the established route
  constants. Do not scatter literal route names through widgets.
- Use `AppTransitions.none` and `Duration.zero` for tab/shell navigation when
  the product requires instant switching. Preserve deliberate push/modal
  transitions for detail and task flows.
- Register data sources, repositories, use cases, and BLoCs in the owning
  Modular module. Use a fresh BLoC registration for screen-scoped state and a
  lazy singleton only for genuinely app-wide state.
- Provide shared BLoCs at the module/shell composition boundary. Avoid a local
  `BlocProvider` in every child screen when the state belongs to a feature set.
- Pass only primitive IDs, enums, strings, and serializable route values. Do
  not pass entities, repositories, BLoCs, or mutable controllers as route
  arguments; fetch the destination data through its injected BLoC/repository.

## UI and design-system rules

- Build screens from small, testable widgets with a single responsibility.
- Use the app theme instead of inline `Color`, `TextStyle`, spacing, or radius
  literals. Keep contrast, focus, disabled, loading, empty, and error states
  visible in both light and dark surfaces where supported.
- Keep business logic, API orchestration, navigation decisions, permission
  policy, and calculations out of `build()` methods.
- Use responsive constraints (`LayoutBuilder`, `Flexible`, `Expanded`, and
  safe scrolling) rather than assuming one device size.
- For permission flows, explain value before the system prompt, preserve a
  manual fallback, and do not show an immediate repetitive toast after a
  deliberate denial. Show recovery guidance in the location-dependent
  component when the user tries that action again.
- For map flows, render current-location, pickup, destination, route, stale,
  and unavailable states explicitly. Never claim a location fix succeeded from
  a stale or missing coordinate.
- Treat text, route parameters, server messages, and remote labels as untrusted
  data. Avoid unsafe HTML rendering, token logging, and sensitive data in
  analytics or error messages.

## Implementation workflow

1. Inspect the nearest feature, its module, route constants, BLoCs/Cubits,
   repository contracts, design tokens, and tests before editing.
2. Write or update immutable domain entities and repository contracts first.
3. Implement data-source parsing and repository failure mapping.
4. Add the nested sealed BLoC using `part`/`part of`; cover loading, success,
   empty, failure, retry, and cancellation behavior.
5. Register dependencies in the existing Modular composition root.
6. Add the screen and widgets with `BlocBuilder`/`BlocListener`; keep widgets
   declarative and use theme tokens.
7. Add route constants and `go_router_modular` declarations with the intended
   transition behavior.
8. Trace consumers and adjacent flows for breaking contracts, stale state,
   duplicate requests, permission regressions, accessibility, and security
   exposure.

## Verification checklist

- Run `dart format` on changed source.
- Run `flutter analyze --no-pub` for the affected app.
- Run focused BLoC tests that assert `Initial → Loading → Success/Failure`.
- Run focused widget tests for loading, empty, error, retry, navigation, and
  important interaction states.
- Run the relevant integration test when a route, permission, map, telemetry,
  or persistence flow changes.
- Search for direct SDK calls in presentation and for literal route strings.
- Confirm no generated files were manually edited and no secret, token, or
  personal data entered source or logs.
- Review the final diff for unrelated changes, then commit each completed task
  using the repository's narrative commit guidelines.

## Anti-patterns

Do not add a flat `presentation/bloc/` set for new BLoCs, mutable global state,
raw exceptions across domain boundaries, API calls from widgets, hidden
service-locator lookups in business logic, entity objects in route arguments,
hardcoded theme values, unbounded location/network streams, or a second
navigation framework. If an existing pattern conflicts with this guidance,
make the smallest compatible improvement and document the boundary in the
implementation rather than performing an unrelated migration.
