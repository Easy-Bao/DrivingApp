package ws

import (
	"location-service/internal/usecase"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type WSHandler struct {
	useCase usecase.LocationUseCase
}

func NewWSHandler(uc usecase.LocationUseCase) *WSHandler {
	return &WSHandler{useCase: uc}
}

func (h *WSHandler) RegisterRoutes(router *gin.Engine) {
	router.GET("/location/ws", h.HandleWebSocket)
}

func (h *WSHandler) HandleWebSocket(c *gin.Context) {
	ws, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Failed to upgrade websocket: %v", err)
		return
	}
	defer ws.Close()

	for {
		var msg map[string]interface{}
		err := ws.ReadJSON(&msg)
		if err != nil {
			break
		}
		_ = ws.WriteJSON(map[string]string{
			"status": "ack",
		})
	}
}
