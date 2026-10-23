package response

type OffsetPage[T any] struct {
	Items      []T     `json:"items"`
	HasMore    bool    `json:"has_more"`
	NextOffset *int    `json:"next_offset"`
	NextCursor *string `json:"next_cursor,omitempty"`
}

func NewOffsetPage[T any](items []T, limit, offset int) OffsetPage[T] {
	if items == nil {
		items = make([]T, 0)
	}
	hasMore := len(items) > limit
	if hasMore {
		items = items[:limit]
	}
	page := OffsetPage[T]{Items: items, HasMore: hasMore}
	if hasMore {
		nextOffset := offset + len(items)
		page.NextOffset = &nextOffset
	}
	return page
}

// NewCursorPage retains the item envelope while distinguishing continuation
// from legacy offsets. An empty next cursor signals the end of the list.
func NewCursorPage[T any](items []T, limit int, next string) OffsetPage[T] {
	page := NewOffsetPage(items, limit, 0)
	page.NextOffset = nil
	page.NextCursor = &next
	return page
}
