# EasyRide Monorepo

This is the Melos-based monorepo for the EasyRide booking application. It houses both passenger and driver applications, along with shared Dart and Flutter packages.

---

## Repository Structure

```
.
├── apps/
│   ├── driver/           # Driver-specific UI, onboarding, background tracking
│   └── passenger/        # Passenger-specific UI, ride booking, payment flows
├── packages/
│   ├── design_system/     # Shared UI components, theme, and transitions
│   ├── foundation/        # Shared networking, lifecycle, and error handling
│   └── maps/              # Shared maps, location, search, and routing
├── web/
│   └── admin/             # Owner operations portal
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

### Configuration ownership and precedence

Configuration is intentionally split by runtime boundary:

- `.env` at the repository root is for the native Go API, Docker Compose
  interpolation, migrations, and local service scripts. It is never bundled
  into either Flutter application.
- `apps/passenger/.env` and `apps/driver/.env` are separate public client
  configuration assets. Their templates may share values because each app is
  built and shipped independently; the Driver template also owns its
  background-telemetry switch.
- `web/admin/.env` is private server-side configuration for the SvelteKit
  process. It is not loaded by the Go API or Flutter clients.
- Melos only orchestrates workspace commands. It does not load or copy any
  environment file.

For Flutter, a non-empty `--dart-define` value takes precedence over the
app-local `.env` asset, followed by the configuration class default. The
asset is public once bundled, so it must contain no backend credentials. The
Go API reads process environment variables once in `app.LoadConfig`; native
commands receive the root `.env` through Just, while Compose maps root values
or derives container-network values such as `DATABASE_URL` and `REDIS_URL`.
Docker Compose supplies its own container defaults for optional settings.

The root template is the server/Compose contract, while each application or
the admin service owns its own template. Do not copy the root `.env` into an
application directory.

When upgrading an older checkout, remove these unused legacy entries from the
local root `.env` after confirming they are not needed by a private local
tool: `CORE_API_URL`, `CORE_API_INTERNAL_URL`, `REALTIME_SERVICE_URL`,
`REALTIME_SERVICE_INTERNAL_URL`, and `RABBITMQ_URL`. They have no consumers in
this repository and are intentionally absent from `.env.example`.

### Run the Go backend natively

The default local backend workflow runs the API natively and starts the
configured PostgreSQL and Redis containers as dependencies. Copy `.env.example`
to `.env`, configure the native credentials, and run:

```bash
just server
```

To start or stop the containerized API stack instead, use:

```bash
just server --start
just server --stop
```

All clients use the Go API through the one `API_BASE_URL` configured in each
app's `.env`. The API bind host and service ports are configured in the root
`.env`; the explicit `just services-up` and `just docker-up` recipes remain
available as aliases. Loopback is the safe default for published development
ports. For a physical device on the local network, set `API_HOST=0.0.0.0`
when running the native API, or `GATEWAY_HOST=0.0.0.0` when running the
containerized API, then point the app's `API_BASE_URL` at the computer's LAN
address. Keep the host firewall limited to the development network.

---

## Melos Workspace Scripts

The following commands are configured in `melos.yaml`:

* **Bootstrap all packages:**
  ```bash
  melos bootstrap
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
