# EasyRide architecture

EasyRide is a modular monolith with one public HTTP entry point. Transactional
features run in `core-api`; high-frequency location and chat traffic runs in
`realtime-service`; `api-gateway` is the only process exposed to clients.

```text
client -> api-gateway:8000
             |-- /ws, /chat/*, and /telemetry/* -> realtime-service:8081
             `-- everything else      -> core-api:8080
```

The service ports are private Compose-network ports. Client applications use
the gateway URL from their ignored environment file and never need a module or
service URL.

## Backend boundaries

```text
server/
├── cmd/
│   ├── core-api/main.go
│   ├── realtime-service/main.go
│   ├── entgenerate/main.go
│   └── migrate/main.go
├── internal/
│   ├── auth/
│   │   ├── adapter/{email,postgres,redis,token}
│   │   ├── domain/{errors,ports,user}.go
│   │   ├── schema/user.go
│   │   ├── transport/http/{dto,handler,router.go}
│   │   └── usecase/{authenticate_user,otp,password,register_passenger}.go
│   ├── users/{adapter,domain,schema,transport/http,usecase}
│   ├── driver_doc/{adapter,domain,schema,transport/http,usecase}
│   ├── rides/{adapter,domain,schema,transport/http,usecase}
│   ├── location/{adapter,domain,transport/http,usecase}
│   ├── admin/{adapter,domain,schema,transport/http,usecase}
│   ├── realtime/{chat,geo,ws}
│   └── platform/{ent/schema,migration}
├── shared-core/
│   ├── database/{postgres,redis}.go
│   ├── security/{jwt,password}.go
│   ├── middleware/{auth,logging}_middleware.go
│   ├── logger/logger.go
│   └── response/response.go
└── ent/                         # generated client and migration API
```

Each `internal/<module>` owns its domain, use cases, adapters, DTOs, HTTP
handlers, routes, and Ent schema declarations. Handlers only translate HTTP;
use cases own business rules; adapters own Ent, Redis, RabbitMQ, go-mail, Mapbox,
and document persistence. The generated client is shared because cross-module
transactions need one Ent graph, but `server/internal/platform/ent/schema` is
generated metadata only. Business schemas remain in their owning modules and
must not be edited in the platform aggregate.

`core-api` owns authentication, passenger/driver profiles, driver document
verification, rides, fare calculation, bid sessions and offers, location
search/routing, and Admin statistics. Passenger registration and login, driver
registration and login, password hashing, profile provisioning, and JWT issue
are explicit auth use cases. Passenger registration is held in Redis until OTP
verification succeeds, then the PostgreSQL user and profile are created.
Passenger OTP verification and password recovery use Redis-backed one-time
codes and a go-mail adapter; driver accounts do not use the passenger
verification route.

`realtime-service` owns the authenticated WebSocket hub, Redis GEO driver
locations, passenger/driver telemetry lookup, Redis-backed chat history, and
live chat event relay. Core ride behavior includes passenger ride history,
driver online status, trip statistics, driver reviews, and notifications.
RabbitMQ is used only for optional location-domain events. PostgreSQL remains
the source of truth for identity, profiles, documents, rides, bids, and audit
records; Redis is for ephemeral/high-throughput state and document payloads in
this deployment. Money is integer centavos and Ent migrations are additive.

## Migration and runtime configuration

```sh
just start-all
```

`start-all` starts PostgreSQL, Redis, and RabbitMQ, runs the one Ent migration
stream, starts the three Go applications, and waits on the gateway health
endpoint. `scripts/database/migrate.sh` makes local PostgreSQL connections use
`sslmode=disable` without changing remote database URLs. Every `.env` file is
ignored, including examples and test variants. Configure mail delivery with
`MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM`,
`MAIL_FROM_NAME`, `MAIL_SUBJECT`, `MAIL_SECURITY`, and `MAIL_TIMEOUT`.

No Drizzle command, legacy service directory, or `server/database` directory
is part of the runtime.

## Flutter packages

Only two shared packages remain:

```text
packages/shared_core/
├── lib/src/{api,constants,models,realtime,chat,fare,location}
└── test/

packages/shared_ui/
└── lib/src/{components,maps}
```

`shared_core` contains models, HTTP/WebSocket clients, location, fare, and
shared errors. `shared_ui` contains reusable widgets, maps, dialogs, and
bottom sheets. Themes remain private to `apps/passenger_app` and
`apps/driver_app`, so each client can evolve its brand independently.
