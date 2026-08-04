# Backend cutover status

The backend runtime is represented by the Go `core-api` and `realtime-service`
processes under `server/cmd`. Legacy Bun services, the location service, API
gateway, and `server/database` bootstrap are no longer present. Ent schemas are
declared by `server/internal/*/schema` and composed into the generated client by
`server/cmd/entgenerate`.

The consolidated core handler covers registration/login (including dedicated
passenger and driver routes), OTP/password contract endpoints, authenticated
profiles, rides, bidding, driver online state and documents, fares, telemetry,
chat rooms, and the Admin session/overview contracts. Production startup opens
PostgreSQL through Ent and persists account registration/login; the remaining
operational aggregates are still being moved from the compatibility store into
their generated Ent repositories.
