# Impact and Breaking-Change Detection

## General method

1. Identify changed symbols, routes, models, configuration keys, persistence fields, and exported methods.
2. Search direct consumers with `rg -F` and broader references with `rg`.
3. Trace one level upstream and downstream through middleware, repositories, state management, API clients, and tests.
4. Compare producer and consumer contracts: names, types, nullability, units, defaults, status codes, errors, and ordering.
5. Check whether tests exercise the changed path and whether a deployment can roll back safely.

## Flutter and shared Dart

```bash
rg -n "ClassName|methodName|/api/v1|queryParameters|state\.extra|fromJson|toJson|BaseOptions|API_BASE_URL" apps packages
```

Trace `Dio` base URI and interceptors -> remote data source -> repository/use case -> Bloc/Cubit -> screen/widget. Also trace shared models in `packages/shared_core` to passenger and driver parsers, and route names to query parameters, route extras, and screen constructor requirements.

Flag as breaking when a required route extra, query field, model field, enum, endpoint path, or response shape changes without compatible consumers. Treat a server 2xx response as insufficient until the Dart model and UI state accept it.

## Go services and gateway

```bash
rg -n "RegisterRoutes|api\.V1Prefix|NewRouter|http\.Handler|json:\"|Authorization|Claim|Verify|Get\(|Post\(|Patch\(" server
rg -n "(/api/v1|CORE_API_URL|REALTIME_SERVICE_URL|GATEWAY_PORT)" .
```

Trace gateway path -> upstream proxy -> service router -> middleware -> handler -> DTO -> use case -> repository/provider. Trace JWT verifier -> subject/role -> ownership predicate, and Ent schema/migration -> repository query -> response DTO -> Flutter/admin consumer. Check Redis/RabbitMQ producers against consumers and retry/idempotency behavior.

Flag changes to route prefixes, auth middleware placement, claims, ownership checks, JSON field names, money units, status transitions, idempotency keys, and error status codes.

## Admin TypeScript and deployment

```bash
rg -n "fetch\(|admin-api|GATEWAY_URL|cookies|session|csv|load|actions" web/admin_app
rg -n "environment:|ports:|depends_on:|CORE_API|REALTIME_SERVICE|GATEWAY" docker-compose.yml server
```

Check that admin loaders/actions still call the intended gateway route, preserve server-only credentials, and do not expose new data through CSV or browser payloads. Check that Docker environment keys, health checks, private/public bindings, and startup dependencies remain compatible.

## Breaking-change signals

- New mandatory input or configuration key without a migration/default.
- Removed or renamed output field consumed by an app, admin page, job, or test.
- Narrowed accepted enum/status values.
- Endpoint method/path/auth requirement changed without coordinated consumers.
- Changed coordinate order, money units, duration units, timezone, pagination, or nullability.
- Changed retry/idempotency semantics for a state-changing operation.
- Database schema change without additive migration or rollback plan.

An additive optional field is usually non-breaking, but verify strict JSON decoders, generated models, and unknown-field rejection before classifying it as safe.
