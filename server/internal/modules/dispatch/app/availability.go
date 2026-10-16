package app

import (
	"context"
	"errors"
	"fmt"
	"slices"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
)

var errAvailabilityPersistenceUnavailable = errors.New("driver availability persistence is unavailable")

type AvailabilityService struct {
	reader DriverAvailabilityReader
}

func NewAvailabilityService(reader DriverAvailabilityReader) *AvailabilityService {
	return &AvailabilityService{reader: reader}
}

func (service *AvailabilityService) OnlineDrivers(
	ctx context.Context,
	driverIDs []int,
) ([]domain.OnlineDriver, error) {
	if service == nil || service.reader == nil {
		return nil, errAvailabilityPersistenceUnavailable
	}
	if len(driverIDs) == 0 || len(driverIDs) > 20 {
		return nil, errors.New("driver availability ids are invalid")
	}
	drivers, err := service.reader.OnlineDrivers(ctx, driverIDs)
	if err != nil {
		return nil, fmt.Errorf("load online drivers: %w", err)
	}
	return slices.Clone(drivers), nil
}

func (service *AvailabilityService) PublicDriverSummaries(
	ctx context.Context,
	limit int,
) ([]domain.PublicDriverSummary, error) {
	if service == nil || service.reader == nil {
		return nil, errAvailabilityPersistenceUnavailable
	}
	if limit <= 0 || limit > 20 {
		return nil, errors.New("public driver summary limit is invalid")
	}
	drivers, err := service.reader.PublicDriverSummaries(ctx, limit)
	if err != nil {
		return nil, fmt.Errorf("load public driver summaries: %w", err)
	}
	return slices.Clone(drivers), nil
}
