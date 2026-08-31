package application

import (
	"fmt"
	"strings"
	"time"
)

var defaultReportingLocation = time.FixedZone("Asia/Manila", 8*60*60)

func LoadReportingLocation(name string) (*time.Location, error) {
	name = strings.TrimSpace(name)
	if name == "" || name == "Asia/Manila" {
		return defaultReportingLocation, nil
	}
	location, err := time.LoadLocation(name)
	if err != nil {
		return nil, fmt.Errorf("load reporting timezone %q: %w", name, err)
	}
	return location, nil
}

func (service *RideService) WithReportingLocation(location *time.Location) *RideService {
	if location != nil {
		service.reportingLocation = location
	}
	return service
}

func (service *RideService) reportingDayBounds(now time.Time) (time.Time, time.Time) {
	location := service.reportingLocation
	if location == nil {
		location = defaultReportingLocation
	}
	localNow := now.In(location)
	start := time.Date(localNow.Year(), localNow.Month(), localNow.Day(), 0, 0, 0, 0, location)
	return start.UTC(), start.AddDate(0, 0, 1).UTC()
}

func (service *RideService) reportingWeekBounds(now time.Time) (time.Time, time.Time) {
	location := service.reportingLocation
	if location == nil {
		location = defaultReportingLocation
	}
	localNow := now.In(location)
	dayStart := time.Date(localNow.Year(), localNow.Month(), localNow.Day(), 0, 0, 0, 0, location)
	weekStart := dayStart.AddDate(0, 0, -(int(dayStart.Weekday())+6)%7)
	return weekStart.UTC(), weekStart.AddDate(0, 0, 7).UTC()
}
