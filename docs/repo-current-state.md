# Backend cutover status

The backend runtime is represented by the Go `core-api` and `realtime-service`
processes under `server/cmd`. Legacy Bun services, the location service, API
gateway, and `server/database` bootstrap are no longer present. Ent schemas are
declared by `server/internal/*/schema` and composed into the generated client by
`server/cmd/entgenerate`.

The consolidated core handler currently covers the tested registration/login,
authenticated profile, ride, bid, and driver-document flows. Its repository is
still an in-memory implementation pending the next persistence slice; Ent
generation and the migration command are wired and verified independently.
