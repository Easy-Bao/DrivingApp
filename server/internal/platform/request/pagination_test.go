package request

import (
	"net/url"
	"testing"
)

func TestParseOffsetPaginationAppliesBounds(t *testing.T) {
	page, err := ParseOffsetPagination(url.Values{"limit": {"25"}, "offset": {"50"}}, 20, 100)
	if err != nil {
		t.Fatal(err)
	}
	if page.Limit != 25 || page.Offset != 50 {
		t.Fatalf("page = %#v", page)
	}

	for _, values := range []url.Values{
		{"limit": {"0"}},
		{"limit": {"101"}},
		{"offset": {"-1"}},
		{"offset": {"many"}},
	} {
		if _, err := ParseOffsetPagination(values, 20, 100); err == nil {
			t.Fatalf("expected pagination %v to fail", values)
		}
	}
}
