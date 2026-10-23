package http

import (
	"encoding/json"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	sharedrequest "github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/request"
)

func TestRideHistoryPageUsesLastVisibleRowForCursor(t *testing.T) {
	timestamp := "2026-10-23T10:00:00.123456Z"
	items := []domain.Ride{{ID: 6, CreatedAt: &timestamp}, {ID: 5, CreatedAt: &timestamp}, {ID: 4, CreatedAt: &timestamp}}
	writer := httptest.NewRecorder()
	writeRideHistoryPage(writer, items, sharedrequest.CursorPagination{OffsetPagination: sharedrequest.OffsetPagination{Limit: 2}, Enabled: true}, "driver:9")
	var page struct {
		Items      []RideResponse `json:"items"`
		HasMore    bool           `json:"has_more"`
		NextCursor string         `json:"next_cursor"`
		NextOffset *int           `json:"next_offset"`
	}
	if err := json.Unmarshal(writer.Body.Bytes(), &page); err != nil {
		t.Fatal(err)
	}
	expected, err := sharedrequest.EncodeListCursor("driver:9", timestamp, 5)
	if err != nil || len(page.Items) != 2 || !page.HasMore || page.NextOffset != nil || page.NextCursor != expected {
		t.Fatalf("page=%+v %v", page, err)
	}
}
