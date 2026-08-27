package response

type OffsetPage[T any] struct {
	Items      []T  `json:"items"`
	HasMore    bool `json:"has_more"`
	NextOffset *int `json:"next_offset"`
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
