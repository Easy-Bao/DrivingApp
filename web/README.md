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

4. **Self-Referential Clean Naming (Zero Redundant Project Prefixes)**:
   - Avoids repetitive name stuttering when already inside a project (e.g. `router/index.ts`, `Sidebar.vue`, `AppLayout.vue`, `DashboardView.vue` instead of `admin-router.ts`, `AdminSidebar.vue`, `AdminLayout.vue`).

5. **Direct Company Payment & Driver Wallet Top-Up Workflow**:
   - Manual driver wallet replenishment via company bank accounts and company payment QR codes (no 3rd-party wallet redirects).
   - In-app driver request submission -> Admin verification queue with proof validation -> Single-click wallet credit restoring dispatch eligibility.

---

## 2. Directory Layout

```text
web/
├── package.json                                    # @web/workspace
├── packages/                                       # TIER 0: Cross-App Foundation Packages
│   ├── api-client/                                 # @web/api-client (Type-safe API & DTO contracts)
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
    │       │   ├── router/index.ts                 # Vue Router configuration
    │       │   └── App.vue                         # Root AppLayout + <RouterView />
    │       ├── core/                               # App Infrastructure (Singleton)
    │       │   ├── config/                         # environment-configuration.ts
    │       │   ├── session/                        # authentication-session.ts
    │       │   └── network/                        # api-bridge.ts
    │       ├── shared/                             # App-Level Reusables
    │       │   ├── components/                     # AppLayout.vue, Sidebar.vue
    │       │   ├── composables/
    │       │   └── types/
    │       ├── features/                           # Business Feature Verticals
    │       │   └── dashboard-overview/
    │       │       ├── api/                        # dashboard.api.ts
    │       │       ├── components/                 # DashboardView.vue
    │       │       ├── composables/                # useDashboard.ts
    │       │       ├── types.ts                    # Dashboard domain contracts
    │       │       ├── index.ts                    # Lean public facade
    │       │       └── __tests__/                  # Feature unit tests
    │       ├── pages/                              # Route Views & Page Composition
    │       │   ├── OverviewPage.vue
    │       │   ├── UsersPage.vue
    │       │   ├── VehiclesPage.vue
    │       │   ├── DocumentsPage.vue
    │       │   ├── TripsPage.vue
    │       │   ├── PaymentPage.vue                 # Driver top-ups, company QR, earnings
    │       │   ├── ReportsPage.vue                 # Universal filters & export center
    │       │   ├── SupportPage.vue
    │       │   ├── SettingsPage.vue
    │       │   ├── ProfilePage.vue
    │       │   └── __tests__/                      # Page integration tests
    │       └── main.ts                             # Application entrypoint
    │
    └── landing/                                    # @web/landing (Customer Landing Portal)
        └── src/
            ├── app/
            │   ├── router/                         # application-router.ts
            │   └── App.vue                         # Root <RouterView />
            ├── core/                               # App Infrastructure (Singleton)
            │   ├── config/                         # environment-configuration.ts
            │   └── network/                        # api-bridge.ts
            ├── shared/                             # App-Specific Layouts & UI
            │   └── layouts/                        # LandingLayout.vue
            ├── features/
            │   ├── fare-estimation/
            │   └── platform-architecture/
            ├── pages/
            │   ├── LandingHomePage.vue
            │   ├── PlatformArchitecturePage.vue
            │   └── __tests__/
            └── main.ts
```

---

## 3. Verification Commands

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
