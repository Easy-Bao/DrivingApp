# BaoRide Monorepo

This is the Melos-based monorepo for the BaoRide booking application. It houses both passenger and driver applications, along with shared Dart and Flutter packages.

---

## Repository Structure

```
.
├── apps/
│   ├── driver_app/          # Driver-specific UI, onboarding, background tracking
│   └── passenger_app/       # Passenger-specific UI, ride booking, payment flows
├── packages/
│   ├── api_client/          # Shared HTTP/WebSocket network layer
│   ├── core_models/         # Shared Dart classes (Trip, User, Location, RideStatus)
│   ├── design_system/       # Shared UI components, theme, buttons, custom maps
│   └── location_service/    # Shared background GPS and distance matrix utilities
├── pubspec.yaml             # Workspace configuration
├── melos.yaml               # Melos workspace scripts and package paths
└── README.md
```

---

## Getting Started

### 1. Use the pinned Flutter toolchain

This workspace targets Flutter 3.47.2 stable, which bundles Dart 3.13.2.
Verify the active SDK before bootstrapping:

```bash
flutter --version
dart --version
```

### 2. Install Melos
Melos is used to manage packages in this workspace. Install it globally:
```bash
dart pub global activate melos
```

### 3. Bootstrap the Workspace
Bootstrapping links all local packages together and installs their external dependencies:
```bash
melos bootstrap
```

### Run the Go backend natively

The default local backend workflow uses the host-installed PostgreSQL and Redis
services. Copy `.env.example` to `.env`, configure the native credentials, and
run:

```bash
just server
```

All clients use the Go API through the one `API_BASE_URL` configured in each
app's `.env`. The API bind host and service ports are configured in the root
`.env`; Docker Compose remains available through the explicit `just
services-up` or `just docker-up` recipes.

---

## Melos Workspace Scripts

The following commands are configured in `melos.yaml`:

* **Bootstrap all packages:**
  ```bash
  melos run bootstrap
  ```
* **Run Flutter analyzer on all packages:**
  ```bash
  melos run analyze
  ```
---

## Coding Guidelines

Please refer to the global agent configuration files (`.agent`, `.cursorrules`, `.clinerules`) in the root directory for instructions regarding:
* SOLID design and architecture.
* Strict naming conventions (camelCase/PascalCase for Dart).
* Narrative and lifecycle-oriented code documentation and git commits.
