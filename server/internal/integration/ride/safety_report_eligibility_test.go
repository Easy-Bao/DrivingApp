//go:build integration

package ride_test

import (
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

func TestSafetyReportsRestrictDriversToCompletedTrips(t *testing.T) {
	for _, state := range []string{"requested", "assigned", "accepted", "arrived", "in_transit", "cancelled", "completed"} {
		t.Run(state, func(t *testing.T) {
			fixture := newPostgresRideFixture(t)
			ctx := t.Context()
			fixture.seedPassenger(t, ctx, 101)
			fixture.seedDriver(t, ctx, 201)
			fixture.seedDriver(t, ctx, 202)
			rideID := fixture.createRide(t, ctx, 101, 201, state, 2000)
			driverReport := domain.SafetyReport{
				RideID: rideID, ReporterID: 201, ReporterRole: "driver",
				Category: domain.SafetyReportOther, Description: "Report details",
			}
			created, err := fixture.store.CreateSafetyReport(ctx, driverReport)
			if state == "completed" {
				if err != nil || created.ID <= 0 || created.ReportedUserID != 101 || created.ReporterID != 201 || created.ReporterRole != "driver" {
					t.Fatalf("completed driver report = %+v, %v", created, err)
				}
				driverReport.Description = "Retried report details"
				retry, err := fixture.store.CreateSafetyReport(ctx, driverReport)
				if err != nil || retry.ID != created.ID || retry.Description != created.Description {
					t.Fatalf("retry = %+v, %v; want original report", retry, err)
				}
			} else if !errors.Is(err, domain.ErrSafetyReportNotAllowed) {
				t.Fatalf("driver report for %s = %+v, %v; want not allowed", state, created, err)
			}
			for _, actor := range []struct {
				role string
				id   int
			}{
				{role: "driver", id: 202},
				{role: "passenger", id: 201},
				{role: "driver", id: 101},
			} {
				unauthorized := driverReport
				unauthorized.ReporterRole, unauthorized.ReporterID = actor.role, actor.id
				if _, err := fixture.store.CreateSafetyReport(ctx, unauthorized); !errors.Is(err, domain.ErrSafetyReportNotAllowed) {
					t.Fatalf("non-owner %s report = %v", actor.role, err)
				}
			}
			passengerReport := driverReport
			passengerReport.ReporterRole, passengerReport.ReporterID = "passenger", 101
			passenger, err := fixture.store.CreateSafetyReport(ctx, passengerReport)
			if err != nil || passenger.ReportedUserID != 201 || passenger.ReporterID != 101 || passenger.ReporterRole != "passenger" {
				t.Fatalf("passenger report for %s = %+v, %v", state, passenger, err)
			}
			retry, err := fixture.store.CreateSafetyReport(ctx, passengerReport)
			if err != nil || retry.ID != passenger.ID {
				t.Fatalf("passenger retry = %+v, %v", retry, err)
			}
			wantReports := 1
			if state == "completed" {
				wantReports = 2
			}
			assertRowCount(t, ctx, fixture.pool, "SELECT count(*) FROM ride_reports WHERE ride_id = $1", rideID, wantReports)
		})
	}
}
