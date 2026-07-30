package grpc

import (
	"location-service/internal/usecase"
)

type GRPCHandler struct {
	useCase usecase.LocationUseCase
}

func NewGRPCHandler(uc usecase.LocationUseCase) *GRPCHandler {
	return &GRPCHandler{useCase: uc}
}
