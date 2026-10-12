package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"

type SafetyReportResponse struct {
	ID             int                         `json:"id"`
	RideID         int                         `json:"ride_id"`
	ReporterID     int                         `json:"reporter_id"`
	ReportedUserID int                         `json:"reported_user_id"`
	ReporterRole   string                      `json:"reporter_role"`
	Category       domain.SafetyReportCategory `json:"category"`
	Severity       domain.SafetyReportSeverity `json:"severity"`
	Description    string                      `json:"description"`
	Status         domain.SafetyReportStatus   `json:"status"`
	CreatedAt      string                      `json:"created_at"`
}

func NewSafetyReportResponse(report domain.SafetyReport) SafetyReportResponse {
	return SafetyReportResponse{
		ID:             report.ID,
		RideID:         report.RideID,
		ReporterID:     report.ReporterID,
		ReportedUserID: report.ReportedUserID,
		ReporterRole:   report.ReporterRole,
		Category:       report.Category,
		Severity:       report.Severity,
		Description:    report.Description,
		Status:         report.Status,
		CreatedAt:      report.CreatedAt,
	}
}
