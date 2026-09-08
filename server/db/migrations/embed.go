package migrations

import "embed"

// FS contains the versioned PostgreSQL migrations shipped with the server.
//
//go:embed *.sql
var FS embed.FS
