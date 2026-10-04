package domain

import "strings"

type SafetyReportCategory string

const (
	SafetyReportAccident               SafetyReportCategory = "accident"
	SafetyReportDriverIdentityMismatch SafetyReportCategory = "driver_identity_mismatch"
	SafetyReportFareDispute            SafetyReportCategory = "fare_dispute"
	SafetyReportFraud                  SafetyReportCategory = "fraud"
	SafetyReportHarassment             SafetyReportCategory = "harassment"
	SafetyReportNoShow                 SafetyReportCategory = "no_show"
	SafetyReportNonPayment             SafetyReportCategory = "non_payment"
	SafetyReportProhibitedCargo        SafetyReportCategory = "prohibited_cargo"
	SafetyReportPropertyDamage         SafetyReportCategory = "property_damage"
	SafetyReportRouteIssue             SafetyReportCategory = "route_issue"
	SafetyReportThreatOrViolence       SafetyReportCategory = "threat_or_violence"
	SafetyReportUnsafeDriving          SafetyReportCategory = "unsafe_driving"
	SafetyReportVehicleMismatch        SafetyReportCategory = "vehicle_mismatch"
	SafetyReportOther                  SafetyReportCategory = "other"
)

type SafetyReportSeverity string

const (
	SafetyReportStandard SafetyReportSeverity = "standard"
	SafetyReportHigh     SafetyReportSeverity = "high"
	SafetyReportCritical SafetyReportSeverity = "critical"
)

type SafetyReportStatus string

const SafetyReportSubmitted SafetyReportStatus = "submitted"

type SafetyReport struct {
	ID             int                  `json:"id"`
	RideID         int                  `json:"ride_id"`
	ReporterID     int                  `json:"reporter_id"`
	ReportedUserID int                  `json:"reported_user_id"`
	ReporterRole   string               `json:"reporter_role"`
	Category       SafetyReportCategory `json:"category"`
	Severity       SafetyReportSeverity `json:"severity"`
	Description    string               `json:"description"`
	Status         SafetyReportStatus   `json:"status"`
	CreatedAt      string               `json:"created_at"`
}

func ValidateSafetyReport(reporterRole string, category SafetyReportCategory, description string) (SafetyReportSeverity, bool) {
	reporterRole = strings.ToLower(strings.TrimSpace(reporterRole))
	category = SafetyReportCategory(strings.ToLower(strings.TrimSpace(string(category))))
	description = strings.TrimSpace(description)
	if len(description) == 0 || len(description) > 2000 {
		return "", false
	}
	if !validSafetyReportCategory(reporterRole, category) {
		return "", false
	}
	return safetyReportSeverity(category), true
}

func validSafetyReportCategory(reporterRole string, category SafetyReportCategory) bool {
	switch reporterRole {
	case "passenger":
		switch category {
		case SafetyReportAccident, SafetyReportDriverIdentityMismatch,
			SafetyReportFareDispute, SafetyReportFraud, SafetyReportHarassment,
			SafetyReportRouteIssue, SafetyReportThreatOrViolence,
			SafetyReportUnsafeDriving, SafetyReportVehicleMismatch, SafetyReportOther:
			return true
		default:
			return false
		}
	case "driver":
		switch category {
		case SafetyReportAccident, SafetyReportFraud, SafetyReportHarassment,
			SafetyReportNoShow, SafetyReportNonPayment, SafetyReportProhibitedCargo,
			SafetyReportPropertyDamage, SafetyReportThreatOrViolence, SafetyReportOther:
			return true
		default:
			return false
		}
	default:
		return false
	}
}

func safetyReportSeverity(category SafetyReportCategory) SafetyReportSeverity {
	switch category {
	case SafetyReportAccident, SafetyReportThreatOrViolence:
		return SafetyReportCritical
	case SafetyReportDriverIdentityMismatch, SafetyReportFraud,
		SafetyReportHarassment, SafetyReportNonPayment,
		SafetyReportProhibitedCargo, SafetyReportPropertyDamage,
		SafetyReportUnsafeDriving, SafetyReportVehicleMismatch:
		return SafetyReportHigh
	default:
		return SafetyReportStandard
	}
}
