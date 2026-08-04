package domain

import "context"

type Repository interface {
	CreateRide(ctx context.Context, ride Ride) (Ride, error)
	CreateBid(ctx context.Context, bid Bid) (Bid, error)
	AcceptBid(ctx context.Context, bidID, driverID int) (Bid, Ride, error)
	Get(ctx context.Context, id int) (Ride, error)
}
