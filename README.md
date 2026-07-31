# EasyRide Monorepo

This repository contains the EasyRide Passenger and Driver mobile apps, shared
Flutter packages, Bun backend services, and the current private operations
portal prototype for the Pagadian City Bao Bao pilot.

---

## Repository Structure

```text
.
├── Apps/
│   ├── DriverApp/           # Driver Flutter client
│   └── PassengerApp/        # Passenger Flutter client
├── web/
│   └── admin_app/           # Private SvelteKit operations portal
├── Packages/                # Shared Dart and Flutter packages
├── server/                  # Gateway and Bun/Hono backend services
├── docs/                    # Product, operations, runtime, and meeting documents
├── pubspec.yaml             # Flutter workspace configuration
├── melos.yaml               # Melos workspace scripts
└── docker-compose.yml       # Local multi-service stack
```

---

## Getting Started

### 1. Install Melos
Melos is used to manage packages in this workspace. Install it globally:
```bash
dart pub global activate melos
```

### 2. Bootstrap the Workspace
Bootstrapping links all local packages together and installs their external dependencies:
```bash
melos bootstrap
```

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

Start with [AGENTS.md](AGENTS.md) for repository-specific implementation,
documentation, testing, security, and Git guidance. Existing tool-specific rule
files remain secondary context when they apply.

## Admin MVP

See [docs/admin-mvp.md](docs/admin-mvp.md) for the private operations portal,
driver prepaid-balance operations, migrations, deployment, and acceptance
runbook.

See [docs/product-plan.md](docs/product-plan.md) for the cross-team passenger,
driver, Admin, and backend feature map, decisions, gaps, and open questions.

See [docs/repo-current-state.md](docs/repo-current-state.md) for the verified
branch, local runtime, test results, and immediate blockers.
