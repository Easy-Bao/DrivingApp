package response

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestNewOffsetPageUsesLookaheadWithoutReturningIt(t *testing.T) {
	page := NewOffsetPage([]int{1, 2, 3}, 2, 4)
	if len(page.Items) != 2 || !page.HasMore || page.NextOffset == nil || *page.NextOffset != 6 {
		t.Fatalf("page = %#v", page)
	}

	last := NewOffsetPage([]int{1}, 2, 0)
	if last.HasMore || last.NextOffset != nil || len(last.Items) != 1 {
		t.Fatalf("last page = %#v", last)
	}
}

func TestOffsetPageKeepsAStableNullNextOffsetContract(t *testing.T) {
	payload, err := json.Marshal(NewOffsetPage([]int{1}, 2, 0))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(payload), `"next_offset":null`) {
		t.Fatalf("page contract = %s", payload)
	}
}

func TestCursorPageKeepsBoundaryAndEndMetadata(t *testing.T) {
	page := NewCursorPage([]int{6, 5, 4}, 2, "boundary")
	if len(page.Items) != 2 || !page.HasMore || page.NextOffset != nil || page.NextCursor == nil || *page.NextCursor != "boundary" {
		t.Fatalf("page=%+v", page)
	}
	for _, items := range [][]int{nil, {1}} {
		page := NewCursorPage(items, 2, "")
		if page.Items == nil || page.HasMore || page.NextCursor == nil || *page.NextCursor != "" {
			t.Fatalf("end=%+v", page)
		}
	}
	payload, err := json.Marshal(NewOffsetPage([]int{1}, 2, 0))
	if err != nil || strings.Contains(string(payload), "next_cursor") {
		t.Fatalf("legacy shape changed: %s %v", payload, err)
	}
}
