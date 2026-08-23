package usecase

import (
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

func TestSummarizeDriverEarningsUsesReportingTimezoneAndDriverPayout(t *testing.T) {
	location := time.FixedZone("Asia/Manila", 8*60*60)
	now := time.Date(2026, time.August, 23, 9, 0, 0, 0, location)
	entries := []domain.DriverEarning{
		{CompletedAt: time.Date(2026, time.August, 22, 16, 30, 0, 0, time.UTC), PayoutCentavos: 2000},
		{CompletedAt: time.Date(2026, time.August, 18, 2, 0, 0, 0, time.UTC), PayoutCentavos: 1500},
		{CompletedAt: time.Date(2026, time.August, 2, 2, 0, 0, 0, time.UTC), PayoutCentavos: 500},
	}

	summary := summarizeDriverEarnings(entries, now, location)

	if summary.Timezone != "Asia/Manila" {
		t.Fatalf("timezone = %q", summary.Timezone)
	}
	if summary.Today.EarningsCentavos != 2000 || summary.Today.CompletedTrips != 1 {
		t.Fatalf("today = %#v", summary.Today)
	}
	if summary.ThisWeek.EarningsCentavos != 3500 || summary.ThisWeek.CompletedTrips != 2 {
		t.Fatalf("this week = %#v", summary.ThisWeek)
	}
	if summary.ThisMonth.EarningsCentavos != 4000 || summary.ThisMonth.CompletedTrips != 3 {
		t.Fatalf("this month = %#v", summary.ThisMonth)
	}
	if summary.Weekdays[6].EarningsCentavos != 2000 || summary.MonthWeeks[3].EarningsCentavos != 2000 {
		t.Fatalf("unexpected buckets: weekdays=%#v month=%#v", summary.Weekdays, summary.MonthWeeks)
	}
}
