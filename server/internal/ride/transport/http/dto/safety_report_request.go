package dto

type SafetyReportRequest struct {
	Category    string `json:"category"`
	Description string `json:"description"`
}
