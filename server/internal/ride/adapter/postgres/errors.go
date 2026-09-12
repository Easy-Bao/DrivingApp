package postgres

import (
	"errors"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5"
)

func driverUnavailableError(operation string, err error) error {
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.ErrDriverUnavailable
	}
	return fmt.Errorf("%s: %w", operation, err)
}
