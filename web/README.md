# Web Workspace Architecture

Enterprise monorepo workspace for Vue 3 + Vite applications (`web/apps/*`) and shared foundation packages (`web/packages/*`), organized using an **Improvised Domain-Driven Feature-Sliced Architecture**.

---

## 1. Architectural Philosophy & Improvisations

This structure improves upon the classic feature-based architecture by addressing the real-world scale and tooling requirements of modern Vue 3 (Composition API), Vite, and enterprise monorepos:

1. **5-Tier Strict Unidirectional Stratification**:
   - `packages/` (Tier 0: Workspace Foundation & Atomic Design System)
   - `core/` (Tier 1: Application Infrastructure & Environment Singletons)
   - `shared/` (Tier 2: App-Specific Reusables, Layouts & Common UI)
   - `features/` (Tier 3: Domain Business Slices & Encapsulated Logic)
   - `pages/` (Tier 4: Route Orchestration & View Assembly)
   - `app/` (Tier 5: Application Composition Root & Router Setup)

2. **Lean Facade Boundary Pattern (Solving the Vite Dev Barrel Tax)**:
   - Each feature exposes an explicit `index.ts` front door that exports **only** the top-level view/widget, primary composable, and side-effect-free type exports (`export type *`).
   - Feature internal subcomponents and deep files stay private and unexported.
   - Eliminates bloated Vite dev-server module graphs, prevents circular dependencies, and enables clean tree-shaking and route chunking.

3. **Strict Path Aliasing (`@/` Only)**:
   - All app-internal imports use `@/` path aliases (e.g., `@/features/...`, `@/pages/...`, `@/shared/...`, `@/core/...`).
   - Relative backtrackers (`.` or `..`) are forbidden, ensuring refactoring immunity when files or folders move.

4. **Idiomatic Vue 3 Slices (Eliminating Java/Flutter Clean Arch Boilerplate)**:
   - Replaces redundant Flutter-style `domain/`, `data/`, `presentation/` folders with cohesive, lightweight Vue slices:
     - `api/`: API endpoints, query/mutation functions wrapping `@web/api-client`.
     - `components/`: Feature-private Vue SFC components.
     - `composables/`: Feature business logic, state machines, and reactive hooks.
     - `stores/`: (Optional) Pinia stores for cross-view state only when necessary.
     - `types.ts`: Strongly-typed TypeScript contracts and interfaces.
     - `index.ts`: Curated public entrypoint.

5. **Route Pages as Orchestrators**:
   - Route components live in `src/pages/` and act as coordinators: they bind route parameters, assign layout shells, and compose feature widgets without hosting monolithic business logic.

---

## 2. Directory Layout

```text
web/
├── package.json                                    # @web/workspace
├── packages/                                       # TIER 0: Cross-App Foundation Packages
│   ├── api-client/                                 # @web/api-client (Type-safe API & DTO contracts)
│   │   └── src/
│   │       ├── contracts/                          # Request/response DTO contracts (*.contract.ts)
│   │       ├── errors/                             # api-client-error.ts
│   │       ├── http/                               # api-http-client.ts & request-builder.ts
│   │       └── modules/                            # Domain endpoint modules (*.module.ts)
│   └── ui/                                         # @web/ui (Pure Tailwind v4 & Atomic Design System)
│       └── src/
│           ├── styles/theme.css
│           ├── atoms/                              # BaseButton, BaseBadge, BaseTextField
│           ├── molecules/                          # SurfaceCard, AlertBanner, StatisticCard
│           ├── organisms/                          # NavigationHeader
│           └── templates/                          # ApplicationShellLayout
│
└── apps/                                           # Applications
    ├── admin/                                      # @web/admin (Administration Portal)
    │   └── src/
    │       ├── app/                                # App composition & bootstrapping
    │       │   └── App.vue                         # Root shell
    │       ├── core/                               # App Infrastructure (Singleton)
    │       │   ├── config/                         # environment-configuration.ts
    │       │   ├── session/                        # authentication-session.ts
    │       │   └── network/                        # api-bridge.ts
    │       ├── shared/                             # App-Level Reusables
    │       │   ├── components/                     # AdminShellLayout.vue
    │       │   ├── composables/
    │       │   └── types/
    │       ├── features/                           # Business Feature Verticals
    │       │   └── dashboard-overview/
    │       │       ├── api/                        # dashboard.api.ts
    │       │       ├── components/                 # AdministrationDashboardView.vue
    │       │       ├── composables/                # useAdministrationDashboard.ts
    │       │       ├── types.ts                    # Dashboard domain contracts
    │       │       ├── index.ts                    # Lean public facade
    │       │       └── __tests__/                  # Feature unit tests
    │       ├── pages/                              # Route Views & Page Composition
    │       │   ├── AdministrationDashboardPage.vue
    │       │   └── __tests__/                      # Page integration tests
    │       └── main.ts                             # Application entrypoint
    │
    └── landing/                                    # @web/landing (Customer Landing Portal)
        └── src/
            ├── app/
            │   ├── router/                         # application-router.ts
            │   └── App.vue                         # Root <RouterView />
            ├── core/
            │   ├── config/                         # environment-configuration.ts
            │   └── network/                        # api-bridge.ts
            ├── shared/
            │   ├── components/
            │   ├── layouts/                        # LandingLayout.vue
            │   └── composables/
            ├── features/
            │   ├── fare-estimation/
            │   │   ├── api/                        # fare-estimation.api.ts
            │   │   ├── components/                 # FareEstimatorCard.vue
            │   │   ├── composables/                # useFareEstimation.ts
            │   │   ├── types.ts                    # Fare domain models
            │   │   ├── index.ts                    # Lean public facade
            │   │   └── __tests__/                  # Feature unit tests
            │   └── platform-architecture/
            │       ├── components/                 # PlatformArchitectureExplorer.vue
            │       ├── types.ts
            │       ├── index.ts
            │       └── __tests__/
            ├── pages/
            │   ├── LandingHomePage.vue             # Composes hero + FareEstimatorCard
            │   ├── PlatformArchitecturePage.vue    # Composes PlatformArchitectureExplorer
            │   └── __tests__/
            └── main.ts
```

---

## 3. Dependency & Import Rules Matrix

| Importing From | Can Import From | Forbidden Imports |
| :--- | :--- | :--- |
| **`pages/`** | `@/features/*` (via facade), `@/shared/*`, `@/core/*`, `@web/*` | Other `pages/`, deep feature internals |
| **`features/`** | `@/shared/*`, `@/core/*`, `@web/*`, other features (via facade ONLY) | `pages/`, `app/`, internal files of other features |
| **`shared/`** | `@/core/*`, `@web/*` | `features/*`, `pages/*`, `app/*` |
| **`core/`** | `@web/*` | `shared/*`, `features/*`, `pages/*`, `app/*` |
| **`packages/*`** | Peer workspace packages (e.g. `@web/api-client` within `@web/ui`) | Any `apps/*` code |

---

## 4. Verification Commands

```bash
# Typecheck entire workspace
bun run type-check

# Run unit tests across all web apps and packages
bun run test:unit

# Build all applications for production
bun run build

# Format codebase with oxfmt
bun run format
```
