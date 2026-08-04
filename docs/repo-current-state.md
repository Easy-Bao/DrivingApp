# Backend cutover status

The backend runtime is represented by the Go `core-api`, `realtime-service`,
and `api-gateway` applications. Legacy Bun services and the old location
service are no longer present. Ent schemas are declared by
`server/internal/*/schema` and composed into the generated client by
`server/cmd/entgenerate`.

The core process is composed from domain-owned routers. Auth registration and
login, users, driver documents, rides/bids, and Admin stats have explicit
use-case and Ent adapter boundaries. Location remains a Mapbox module with nearby
POI search, reverse-geocode/route operations, Redis result caching, and optional
RabbitMQ events; realtime geo is Redis-backed and chat is a realtime hub. Full legacy parity for OTP mail
delivery, richer Admin case/audit/report operations, and persistent chat history
remain follow-up implementation work rather than hidden compatibility logic.
