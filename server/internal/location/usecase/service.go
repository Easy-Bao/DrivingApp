package usecase

import (
	"context"
	"errors"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

var ErrEmptySearch = errors.New("location search query is empty")

type Service struct {
	provider domain.Provider
}

func NewService(provider domain.Provider) *Service {
	return &Service{provider: provider}
}

func (service *Service) Search(ctx context.Context, query string, origin domain.Coordinates) ([]domain.Place, error) {
	query = strings.TrimSpace(query)
	if query == "" {
		return nil, ErrEmptySearch
	}
	return service.provider.Search(ctx, query, origin)
}

func (service *Service) ReverseGeocode(ctx context.Context, coordinates domain.Coordinates) (*domain.Place, error) {
	return service.provider.ReverseGeocode(ctx, coordinates)
}

func (service *Service) Route(ctx context.Context, origin, destination domain.Coordinates) (*domain.Route, error) {
	return service.provider.Route(ctx, origin, destination)
}
