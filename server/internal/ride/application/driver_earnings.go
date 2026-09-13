package application

import (
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

func summarizeDriverEarnings(
	entries []domain.DriverEarning,
	now time.Time,
	location *time.Location,
) domain.DriverEarningsSummary {
	localNow := now.In(location)
	today := time.Date(localNow.Year(), localNow.Month(), localNow.Day(), 0, 0, 0, 0, location)
	weekStart := today.AddDate(0, 0, -(int(today.Weekday())+6)%7)
	monthStart := time.Date(today.Year(), today.Month(), 1, 0, 0, 0, 0, location)

	summary := domain.DriverEarningsSummary{
		Timezone:   location.String(),
		Weekdays:   make([]domain.EarningsBucket, 7),
		MonthWeeks: make([]domain.EarningsBucket, 5),
	}
	for index := range summary.Weekdays {
		start := weekStart.AddDate(0, 0, index)
		summary.Weekdays[index].StartDate = start.Format(time.DateOnly)
	}
	for index := range summary.MonthWeeks {
		start := monthStart.AddDate(0, 0, index*7)
		summary.MonthWeeks[index].StartDate = start.Format(time.DateOnly)
	}

	for _, entry := range entries {
		completedAt := entry.CompletedAt.In(location)
		if completedAt.Before(monthStart) || !completedAt.Before(monthStart.AddDate(0, 1, 0)) {
			continue
		}
		addEarnings(&summary.ThisMonth, entry.PayoutAmount)
		monthWeek := (completedAt.Day() - 1) / 7
		addEarningsBucket(&summary.MonthWeeks[monthWeek], entry.PayoutAmount)

		if !completedAt.Before(weekStart) && completedAt.Before(weekStart.AddDate(0, 0, 7)) {
			addEarnings(&summary.ThisWeek, entry.PayoutAmount)
			weekday := (int(completedAt.Weekday()) + 6) % 7
			addEarningsBucket(&summary.Weekdays[weekday], entry.PayoutAmount)
		}
		if sameLocalDay(completedAt, today) {
			addEarnings(&summary.Today, entry.PayoutAmount)
		}
	}
	return summary
}

func addEarnings(period *domain.EarningsPeriod, amount int64) {
	period.EarningsAmount += amount
	period.CompletedTrips++
}

func addEarningsBucket(bucket *domain.EarningsBucket, amount int64) {
	bucket.EarningsAmount += amount
	bucket.CompletedTrips++
}

func sameLocalDay(left, right time.Time) bool {
	return left.Year() == right.Year() && left.Month() == right.Month() && left.Day() == right.Day()
}
