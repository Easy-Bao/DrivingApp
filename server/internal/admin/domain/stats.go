package domain

type Stats struct {
	Users           int `json:"users"`
	Rides           int `json:"rides"`
	DriverDocuments int `json:"driver_documents"`
}
