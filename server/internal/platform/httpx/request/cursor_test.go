package request

import (
	"net/url"
	"strings"
	"testing"
	"time"
)

func TestCursorPaginationPreservesBoundaryAndScope(t *testing.T) {
	timestamp := "2026-10-23T12:34:56.123456Z"
	encoded, err := EncodeListCursor("driver:9:completed", timestamp, 42)
	if err != nil {
		t.Fatal(err)
	}
	page, err := ParseCursorPagination(url.Values{"cursor": {encoded}, "limit": {"10"}}, 25, 100, "driver:9:completed")
	expected, _ := time.Parse(time.RFC3339Nano, timestamp)
	if err != nil || !page.Enabled || page.BeforeID != 42 || !page.BeforeCreatedAt.Equal(expected) || page.Limit != 10 {
		t.Fatalf("page=%+v err=%v", page, err)
	}
	for _, scope := range []string{"driver:10:completed", "driver:9:active", "passenger:9"} {
		if _, err := ParseCursorPagination(url.Values{"cursor": {encoded}}, 25, 100, scope); err == nil {
			t.Fatalf("accepted changed scope %s", scope)
		}
	}
	for _, values := range []url.Values{
		{"cursor": {"bad!"}}, {"cursor": {encoded}, "offset": {"1"}},
		{"cursor": {strings.Repeat("a", 513)}}, {"cursor": {encoded, encoded}},
		{"cursor": {"e30"}}, {"cursor": {encoded}, "limit": {"0"}},
	} {
		if _, err := ParseCursorPagination(values, 25, 100, "driver:9:completed"); err == nil {
			t.Fatalf("accepted %v", values)
		}
	}
	page, err = ParseCursorPagination(url.Values{"cursor": {""}}, 25, 100, "driver:9:completed")
	if err != nil || !page.Enabled || !page.BeforeCreatedAt.IsZero() {
		t.Fatalf("first page=%+v %v", page, err)
	}
	page, err = ParseCursorPagination(url.Values{"offset": {"25"}}, 25, 100, "driver:9:completed")
	if err != nil || page.Enabled || page.Offset != 25 {
		t.Fatalf("legacy page=%+v %v", page, err)
	}
}
