package redis

import (
	"bytes"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

func TestPendingRegistrationRecordPreservesRedisPayload(t *testing.T) {
	t.Parallel()

	registration := domain.PendingRegistration{
		Email:             "driver@example.test",
		Phone:             "+639171234567",
		Name:              "Sample Driver",
		PasswordHash:      "hashed-password",
		Role:              domain.Driver,
		VehicleType:       "car",
		PlateNumber:       "ABC1234",
		PreferredRideType: "",
	}
	want := []byte(`{"email":"driver@example.test","phone":"+639171234567","name":"Sample Driver","password_hash":"hashed-password","role":"driver","vehicle_type":"car","plate_number":"ABC1234"}`)

	got, err := encodePendingRegistration(registration)
	if err != nil {
		t.Fatalf("encode pending registration: %v", err)
	}
	if !bytes.Equal(got, want) {
		t.Fatalf("encoded payload = %s, want %s", got, want)
	}

	decoded, err := decodePendingRegistration(got)
	if err != nil {
		t.Fatalf("decode pending registration: %v", err)
	}
	if decoded != registration {
		t.Fatalf("decoded registration = %#v, want %#v", decoded, registration)
	}
}

func TestDecodePendingRegistrationReadsExistingPayload(t *testing.T) {
	t.Parallel()

	payload := []byte(`{"email":"passenger@example.test","phone":"+639189876543","name":"Sample Passenger","password_hash":"hashed-password","role":"passenger","preferred_ride_type":"motorcycle"}`)
	want := domain.PendingRegistration{
		Email:             "passenger@example.test",
		Phone:             "+639189876543",
		Name:              "Sample Passenger",
		PasswordHash:      "hashed-password",
		Role:              domain.Passenger,
		PreferredRideType: "motorcycle",
	}

	got, err := decodePendingRegistration(payload)
	if err != nil {
		t.Fatalf("decode existing pending registration: %v", err)
	}
	if got != want {
		t.Fatalf("decoded registration = %#v, want %#v", got, want)
	}
}
