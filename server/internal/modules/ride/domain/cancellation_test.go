package domain

import "testing"

func TestValidateCancellationDoesNotAssignFaultFromUnverifiedClaims(t *testing.T) {
	tests := []struct {
		name   string
		actor  CancellationActor
		reason CancellationReason
		want   CancellationResponsibility
	}{
		{
			name:   "passenger says driver took too long",
			actor:  CancellationActorPassenger,
			reason: CancellationReasonDriverTakingTooLong,
			want:   CancellationResponsibilityPendingReview,
		},
		{
			name:   "passenger says driver asked to cancel",
			actor:  CancellationActorPassenger,
			reason: CancellationReasonDriverAskedToCancel,
			want:   CancellationResponsibilityPendingReview,
		},
		{
			name:   "passenger says driver did not arrive",
			actor:  CancellationActorPassenger,
			reason: CancellationReasonDriverNoShow,
			want:   CancellationResponsibilityPendingReview,
		},
		{
			name:   "driver says passenger requested cancellation",
			actor:  CancellationActorDriver,
			reason: CancellationReasonPassengerRequestedCancel,
			want:   CancellationResponsibilityPendingReview,
		},
		{
			name:   "driver says passenger is unreachable",
			actor:  CancellationActorDriver,
			reason: CancellationReasonPassengerUnreachable,
			want:   CancellationResponsibilityPendingReview,
		},
		{
			name:   "driver reports unsafe passenger behavior",
			actor:  CancellationActorDriver,
			reason: CancellationReasonPassengerBehaviorUnsafe,
			want:   CancellationResponsibilitySafetyRelated,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			responsibility, _, err := ValidateCancellation(
				test.actor,
				string(RideAccepted),
				test.reason,
				"",
			)
			if err != nil {
				t.Fatalf("ValidateCancellation() error = %v", err)
			}
			if responsibility != test.want {
				t.Fatalf("responsibility = %q, want %q", responsibility, test.want)
			}
		})
	}
}

func TestValidateCancellationRetainsEvidenceBasedResponsibility(t *testing.T) {
	tests := []struct {
		name   string
		actor  CancellationActor
		reason CancellationReason
		want   CancellationResponsibility
	}{
		{
			name:   "passenger admits changing mind",
			actor:  CancellationActorPassenger,
			reason: CancellationReasonPassengerChangedMind,
			want:   CancellationResponsibilityPassengerFault,
		},
		{
			name:   "driver reports vehicle problem",
			actor:  CancellationActorDriver,
			reason: CancellationReasonVehicleProblem,
			want:   CancellationResponsibilityDriverFault,
		},
		{
			name:   "driver reports blocked road",
			actor:  CancellationActorDriver,
			reason: CancellationReasonRoadBlocked,
			want:   CancellationResponsibilityNoFault,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			responsibility, _, err := ValidateCancellation(
				test.actor,
				string(RideAccepted),
				test.reason,
				"",
			)
			if err != nil {
				t.Fatalf("ValidateCancellation() error = %v", err)
			}
			if responsibility != test.want {
				t.Fatalf("responsibility = %q, want %q", responsibility, test.want)
			}
		})
	}
}
