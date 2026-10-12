package event

// RealtimeEvent is the application-facing input to transient event delivery.
// Persisted resources remain authoritative when delivery is unavailable.
type RealtimeEvent struct {
	Type    Type
	Scope   Scope
	Payload map[string]any
}
