package postgres

import (
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
)

func TestOnlineDriverMappingPreservesAvailabilityDetails(t *testing.T) {
	item := databasepostgres.ListOnlineDriversRow{
		ID:                    5,
		UserID:                11,
		Name:                  "Driver",
		VehicleType:           "Sedan",
		PlateNumber:           "ABC 123",
		Rating:                4.75,
		OnboardPassengerCount: 2,
	}
	driver, err := fromPostgresOnlineDriver(item)
	if err != nil {
		t.Fatalf("fromPostgresOnlineDriver() error = %v", err)
	}
	if driver.ID != 11 || driver.UserID != 11 || driver.Name != "Driver" || driver.VehicleType != "Sedan" ||
		driver.PlateNumber != "ABC 123" || driver.Rating != 4.75 || driver.OnboardPassengerCount != 2 {
		t.Fatalf("online driver = %+v", driver)
	}
}

func TestToPostgresDriverIDsRejectsInvalidIDs(t *testing.T) {
	if ids, err := pgutil.ToPositiveInt32s([]int{7, 11}, "driver id"); err != nil || len(ids) != 2 || ids[1] != 11 {
		t.Fatalf("pgutil.ToPositiveInt32s() = %v, %v", ids, err)
	}
	if _, err := pgutil.ToPositiveInt32s([]int{7, 0}, "driver id"); err == nil {
		t.Fatal("expected invalid driver id to be rejected")
	}
}

func TestOnlineDriverCountRejectsNegativeValues(t *testing.T) {
	if _, err := fromPostgresOnlineDriver(databasepostgres.ListOnlineDriversRow{
		OnboardPassengerCount: -1,
	}); err == nil {
		t.Fatal("expected negative onboard passenger count to be rejected")
	}
}
