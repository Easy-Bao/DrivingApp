package domain

import "testing"

func TestValidateSafetyReportDerivesRoleSpecificSeverity(t *testing.T) {
	tests := []struct {
		name         string
		role         string
		category     SafetyReportCategory
		wantSeverity SafetyReportSeverity
	}{
		{
			name:         "passenger unsafe driving",
			role:         "passenger",
			category:     SafetyReportUnsafeDriving,
			wantSeverity: SafetyReportHigh,
		},
		{
			name:         "driver threat",
			role:         "driver",
			category:     SafetyReportThreatOrViolence,
			wantSeverity: SafetyReportCritical,
		},
		{
			name:         "driver no show",
			role:         "driver",
			category:     SafetyReportNoShow,
			wantSeverity: SafetyReportStandard,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			severity, valid := ValidateSafetyReport(
				test.role,
				test.category,
				"The incident was observed during the ride.",
			)
			if !valid || severity != test.wantSeverity {
				t.Fatalf("ValidateSafetyReport() = %q, %t; want %q, true", severity, valid, test.wantSeverity)
			}
		})
	}
}

func TestValidateSafetyReportRejectsCounterpartyOnlyCategory(t *testing.T) {
	if _, valid := ValidateSafetyReport(
		"passenger",
		SafetyReportNonPayment,
		"The passenger did not pay the agreed cash fare.",
	); valid {
		t.Fatal("expected passenger non-payment report to be rejected")
	}
}

func TestValidateSafetyReportRejectsBlankOrOversizedDescription(t *testing.T) {
	if _, valid := ValidateSafetyReport("driver", SafetyReportOther, " "); valid {
		t.Fatal("expected blank description to be rejected")
	}
	if _, valid := ValidateSafetyReport("driver", SafetyReportOther, string(make([]byte, 2001))); valid {
		t.Fatal("expected oversized description to be rejected")
	}
}
