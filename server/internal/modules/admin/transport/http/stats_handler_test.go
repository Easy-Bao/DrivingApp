package http

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	adminapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/domain"
)

type statsReaderStub struct{ stats domain.Stats }

func (reader statsReaderStub) Stats(context.Context) (domain.Stats, error) {
	return reader.stats, nil
}

func TestStatsKeepsPublicJSONFieldNames(t *testing.T) {
	handler := NewHandler(adminapp.NewStatsService(statsReaderStub{
		stats: domain.Stats{Users: 3, Rides: 5, DriverDocuments: 2},
	}))
	request := httptest.NewRequest(http.MethodGet, "/api/v1/admin/stats", nil)
	writer := httptest.NewRecorder()

	handler.Stats(writer, request)

	if writer.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", writer.Code, http.StatusOK)
	}
	const want = `{"users":3,"rides":5,"driver_documents":2}`
	if got := strings.TrimSpace(writer.Body.String()); got != want {
		t.Fatalf("body = %s, want %s", got, want)
	}
}
