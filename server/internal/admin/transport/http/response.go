package http

import "github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"

type statsResponse struct {
	Users           int `json:"users"`
	Rides           int `json:"rides"`
	DriverDocuments int `json:"driver_documents"`
}

func statsResponseFromDomain(stats domain.Stats) statsResponse {
	return statsResponse{
		Users:           stats.Users,
		Rides:           stats.Rides,
		DriverDocuments: stats.DriverDocuments,
	}
}
