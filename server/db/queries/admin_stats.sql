-- name: GetAdminDashboardCounts :one
SELECT
    (SELECT count(*) FROM users) AS users_count,
    (SELECT count(*) FROM rides) AS rides_count,
    (SELECT count(*) FROM driver_documents) AS driver_documents_count;
