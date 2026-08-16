package dto

type Credentials struct {
	Email       string `json:"email"`
	Phone       string `json:"phone"`
	Name        string `json:"name"`
	Password    string `json:"password"`
	VehicleType string `json:"vehicle_type"`
	PlateNumber string `json:"plate_number"`
	Role        string `json:"role"`
}

type OTPRequest struct {
	Email string `json:"email"`
}

type OTPVerification struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

type PasswordReset struct {
	Email       string `json:"email"`
	Code        string `json:"code"`
	NewPassword string `json:"newPassword"`
}

type RefreshToken struct {
	Token string `json:"refreshToken"`
}
