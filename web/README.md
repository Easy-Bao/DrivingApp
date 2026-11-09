# Web Workspace

Monorepo workspace for web applications (`web/apps/*`) and shared packages (`web/packages/*`).

## Workspace Architecture & Layout Structure

```text
web/
├── package.json                                # @web/workspace
├── apps/
│   ├── admin/                                  # @web/admin
│   │   └── src/
│   │       ├── core/
│   │       │   ├── config/environment-configuration.ts
│   │       │   ├── session/authentication-session.ts
│   │       │   └── network/api-bridge.ts
│   │       └── features/
│   │           └── dashboard-overview/
│   │               ├── domain/administration-dashboard.model.ts
│   │               ├── data/administration-dashboard.repository.ts
│   │               └── presentation/
│   │                   ├── administration-dashboard.store.ts
│   │                   └── AdministrationDashboardPage.vue
│   └── landing/                                # @web/landing
│       └── src/
│           ├── app/router/application-router.ts
│           ├── core/
│           │   ├── config/environment-configuration.ts
│           │   └── network/api-bridge.ts
│           └── features/
│               ├── marketing-home/
│               │   ├── domain/fare-estimation.model.ts
│               │   ├── data/fare-estimation.repository.ts
│               │   └── presentation/
│               │       ├── fare-estimation.store.ts
│               │       └── LandingHomePage.vue
│               └── platform-architecture/
│                   └── presentation/PlatformArchitecturePage.vue
└── packages/
    ├── api-client/                             # @web/api-client
    │   └── src/
    │       ├── contracts/                      # Request/response DTO contracts (*.contract.ts)
    │       ├── errors/                         # api-client-error.ts
    │       ├── http/                           # api-http-client.ts & request-builder.ts
    │       └── modules/                        # Domain endpoint modules (*.module.ts)
    └── ui/                                     # @web/ui (Pure CSS/Tailwind & Vue Atomic Components)
        └── src/
            ├── styles/theme.css
            ├── atoms/
            │   ├── BaseButton.vue
            │   ├── BaseBadge.vue
            │   └── BaseTextField.vue
            ├── molecules/
            │   ├── SurfaceCard.vue
            │   ├── AlertBanner.vue
            │   └── StatisticCard.vue
            ├── organisms/
            │   └── NavigationHeader.vue
            └── templates/
                └── ApplicationShellLayout.vue
```
