package usecase

import (
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
)

func HashPassword(password string) string { return security.HashPassword(password) }
func intSubject(id int) string            { return strconv.Itoa(id) }
