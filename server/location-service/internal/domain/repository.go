package domain

import "context"

type LocationRepository interface {
	SearchPlaces(ctx context.Context, query string, lat, lng float64) ([]Place, error)
	ReverseGeocode(ctx context.Context, lat, lng float64) (*Place, error)
	GetNearbyPois(ctx context.Context, lat, lng float64, page int) ([]Place, error)
	GetRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*Route, error)
	GetTravelMatrix(ctx context.Context, origin Point, destinations []Point) (*MatrixResult, error)
}

type CacheRepository interface {
	GetGeocodeCache(ctx context.Context, lat, lng float64) (*Place, error)
	SetGeocodeCache(ctx context.Context, lat, lng float64, place *Place) error
	GetNearbyCache(ctx context.Context, lat, lng float64, page int) ([]Place, error)
	SetNearbyCache(ctx context.Context, lat, lng float64, page int, places []Place) error
	GetSearchCache(ctx context.Context, query string, lat, lng float64) ([]Place, error)
	SetSearchCache(ctx context.Context, query string, lat, lng float64, places []Place) error
	GetRouteCache(ctx context.Context, originLat, originLng, destLat, destLng float64) (*Route, error)
	SetRouteCache(ctx context.Context, route *Route) error
}

type QueuePublisher interface {
	PublishLocationEvent(ctx context.Context, event *LocationUpdateEvent) error
}
