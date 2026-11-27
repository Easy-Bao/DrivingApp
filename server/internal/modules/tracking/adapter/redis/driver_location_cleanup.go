package redis

import (
	"context"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/domain"
	"time"
)

type driverLocationRecord struct {
	DriverID   string    `json:"driver_id"`
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	Heading    float64   `json:"heading,omitempty"`
	Speed      float64   `json:"speed,omitempty"`
	ObservedAt time.Time `json:"observed_at"`
}

func newDriverLocationRecord(point domain.DriverPoint) driverLocationRecord {
	return driverLocationRecord{
		DriverID:   point.DriverID,
		Latitude:   point.Latitude,
		Longitude:  point.Longitude,
		Heading:    point.Heading,
		Speed:      point.Speed,
		ObservedAt: point.ObservedAt,
	}
}

func (record driverLocationRecord) point() domain.DriverPoint {
	return domain.DriverPoint{
		DriverID:   record.DriverID,
		Latitude:   record.Latitude,
		Longitude:  record.Longitude,
		Heading:    record.Heading,
		Speed:      record.Speed,
		ObservedAt: record.ObservedAt,
	}
}

func (repository *DriverLocationStore) cleanupExpiredDriversBounded(ctx context.Context) (int, error) {
	totalExpired := 0
	for range _locationCleanupMaxBatches {
		expiredCount, err := repository.cleanupExpiredDrivers(ctx)
		totalExpired += expiredCount
		if err != nil {
			return totalExpired, err
		}
		if expiredCount < _locationCleanupBatchSize {
			break
		}
	}
	return totalExpired, nil
}

func (repository *DriverLocationStore) cleanupExpiredDrivers(ctx context.Context) (int, error) {
	if err := repository.validate(); err != nil {
		return 0, err
	}
	expiredCount, err := _cleanupExpiredDriversScript.Run(
		ctx,
		repository.client,
		[]string{_driverLocationExpiryKey, _driverLocationsKey},
		time.Now().UnixMilli(),
		_locationCleanupBatchSize,
		_driverLocationKeyPrefix,
		_driverLocationObservedAtPrefix,
	).Int()
	if err != nil {
		return 0, fmt.Errorf("clean up expired driver locations: %w", err)
	}
	return expiredCount, nil
}
