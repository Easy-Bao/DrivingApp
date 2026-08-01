package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"location-service/internal/domain"
	"location-service/internal/usecase"
	"math"
	"sort"
	"strings"

	_ "github.com/lib/pq"
)

type postgresAdapter struct {
	db           *sql.DB
	fallbackPOIs []domain.Place
}

func NewPostgresAdapter(dbURL string) domain.LocationRepository {
	var db *sql.DB
	if dbURL != "" {
		if d, err := sql.Open("postgres", dbURL); err == nil {
			db = d
		}
	}

	//TODO: No seeders
	seedPOIs := []domain.Place{
		{ID: "poi-1", Name: "Springland Resort", Address: "Springland Resort Road, Pagadian City", Category: "Resort", Latitude: 7.8242, Longitude: 123.4350},
		{ID: "poi-2", Name: "Four Queens Resort", Address: "Four Queens Road, Pagadian City", Category: "Resort", Latitude: 7.8280, Longitude: 123.4345},
		{ID: "poi-3", Name: "N Hotel", Address: "N Hotel Blvd, Pagadian City", Category: "Hotel", Latitude: 7.8320, Longitude: 123.4360},
		{ID: "poi-4", Name: "LEX Badminton Center", Address: "Sports Complex Road, Pagadian City", Category: "Sports", Latitude: 7.8305, Longitude: 123.4330},
		{ID: "poi-5", Name: "Tuburan Central School", Address: "Tuburan, Pagadian City", Category: "School", Latitude: 7.8290, Longitude: 123.4300},
		{ID: "poi-6", Name: "Pagadian Cemetery", Address: "Cemetery Road, Pagadian City", Category: "Cemetery", Latitude: 7.8260, Longitude: 123.4250},
		{ID: "poi-7", Name: "Pagadian Doctors Hospital", Address: "Hospital Road, Pagadian City", Category: "Hospital", Latitude: 7.8220, Longitude: 123.4280},
		{ID: "poi-8", Name: "Casa de Lolita", Address: "Lolita Street, Pagadian City", Category: "Restaurant", Latitude: 7.8255, Longitude: 123.4320},
		{ID: "poi-9", Name: "Pagadian City Hall", Address: "Rizal Avenue, Pagadian City", Category: "Government", Latitude: 7.8250, Longitude: 123.4380},
		{ID: "poi-10", Name: "Manila City Hall", Address: "Padre Burgos Ave, Ermita, Manila", Category: "Government", Latitude: 14.5896, Longitude: 120.9817},
	}

	return &postgresAdapter{
		db:           db,
		fallbackPOIs: seedPOIs,
	}
}

func (p *postgresAdapter) SearchPlaces(ctx context.Context, query string, lat, lng float64) ([]domain.Place, error) {
	if p.db != nil {
		rows, err := p.db.QueryContext(ctx,
			"SELECT id, name, address, category, latitude, longitude FROM places WHERE name ILIKE $1 OR address ILIKE $2 LIMIT 20",
			"%"+query+"%", "%"+query+"%",
		)
		if err == nil {
			defer rows.Close()
			var results []domain.Place
			for rows.Next() {
				var item domain.Place
				if err := rows.Scan(&item.ID, &item.Name, &item.Address, &item.Category, &item.Latitude, &item.Longitude); err == nil {
					item.DistanceKm = usecase.CalculateHaversine(lat, lng, item.Latitude, item.Longitude)
					results = append(results, item)
				}
			}
			if len(results) > 0 {
				sort.Slice(results, func(i, j int) bool {
					return results[i].DistanceKm < results[j].DistanceKm
				})
				return results, nil
			}
		}
	}

	qLower := strings.ToLower(strings.TrimSpace(query))
	var matched []domain.Place
	for _, item := range p.fallbackPOIs {
		if qLower == "" || strings.Contains(strings.ToLower(item.Name), qLower) || strings.Contains(strings.ToLower(item.Address), qLower) || strings.Contains(strings.ToLower(item.Category), qLower) {
			copyItem := item
			copyItem.DistanceKm = usecase.CalculateHaversine(lat, lng, item.Latitude, item.Longitude)
			matched = append(matched, copyItem)
		}
	}

	sort.Slice(matched, func(i, j int) bool {
		return matched[i].DistanceKm < matched[j].DistanceKm
	})

	return matched, nil
}

func (p *postgresAdapter) ReverseGeocode(ctx context.Context, lat, lng float64) (*domain.Place, error) {
	if p.db != nil {
		row := p.db.QueryRowContext(ctx,
			"SELECT id, name, address, category, latitude, longitude FROM places ORDER BY (latitude - $1)^2 + (longitude - $2)^2 ASC LIMIT 1",
			lat, lng,
		)
		var item domain.Place
		if err := row.Scan(&item.ID, &item.Name, &item.Address, &item.Category, &item.Latitude, &item.Longitude); err == nil {
			item.DistanceKm = usecase.CalculateHaversine(lat, lng, item.Latitude, item.Longitude)
			return &item, nil
		}
	}

	var closest *domain.Place
	minDist := math.MaxFloat64
	for _, item := range p.fallbackPOIs {
		dist := usecase.CalculateHaversine(lat, lng, item.Latitude, item.Longitude)
		if dist < minDist {
			minDist = dist
			copyItem := item
			copyItem.DistanceKm = dist
			closest = &copyItem
		}
	}

	if closest != nil {
		return closest, nil
	}

	return &domain.Place{
		ID:         fmt.Sprintf("rev-%.4f-%.4f", lat, lng),
		Name:       fmt.Sprintf("Location at (%.4f, %.4f)", lat, lng),
		Address:    fmt.Sprintf("%.4f, %.4f, Pagadian City", lat, lng),
		Category:   "Point of Interest",
		Latitude:   lat,
		Longitude:  lng,
		DistanceKm: 0.0,
	}, nil
}

func (p *postgresAdapter) GetNearbyPois(ctx context.Context, lat, lng float64, page int) ([]domain.Place, error) {
	return p.SearchPlaces(ctx, "", lat, lng)
}

func (p *postgresAdapter) GetRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*domain.Route, error) {
	distKm := usecase.CalculateHaversine(originLat, originLng, destLat, destLng)
	durationMin := math.Max(1.0, (distKm/30.0)*60.0)

	waypoints := [][]float64{
		{originLat, originLng},
		{(originLat + destLat) / 2.0, (originLng + destLng) / 2.0},
		{destLat, destLng},
	}

	return &domain.Route{
		OriginLat:   originLat,
		OriginLng:   originLng,
		DestLat:     destLat,
		DestLng:     destLng,
		DistanceKm:  distKm,
		DurationMin: durationMin,
		Polyline:    fmt.Sprintf("poly_%.4f_%.4f_to_%.4f_%.4f", originLat, originLng, destLat, destLng),
		Waypoints:   waypoints,
	}, nil
}
