package ws

import (
	"sync"
	"time"
)

type chatBudget struct {
	messageCount int
	messageReset time.Time

	lastTypingState *bool
	lastTypingTime  time.Time
	typingCount     int
	typingReset     time.Time

	lastActivity time.Time
}

type ChatLimiter struct {
	mu             sync.Mutex
	budgets        map[string]*chatBudget
	messageLimit   int
	messageWindow  time.Duration
	typingLimit    int
	typingWindow   time.Duration
	typingCooldown time.Duration
	operations     uint64
	now            func() time.Time
}

func newChatLimiter() *ChatLimiter {
	return &ChatLimiter{
		budgets:        make(map[string]*chatBudget),
		messageLimit:   10,
		messageWindow:  5 * time.Second,
		typingLimit:    10,
		typingWindow:   5 * time.Second,
		typingCooldown: 2 * time.Second,
		now:            time.Now,
	}
}

func (limiter *ChatLimiter) allowMessage(roomID, principal string) bool {
	if limiter == nil {
		return true
	}
	limiter.mu.Lock()
	defer limiter.mu.Unlock()

	now := limiter.now()
	limiter.operations++
	if limiter.operations%128 == 0 {
		limiter.cleanup(now)
	}

	key := roomID + ":" + principal
	b, ok := limiter.budgets[key]
	if !ok {
		b = &chatBudget{}
		limiter.budgets[key] = b
	}
	b.lastActivity = now

	if now.After(b.messageReset) {
		b.messageReset = now.Add(limiter.messageWindow)
		b.messageCount = 0
	}
	if b.messageCount >= limiter.messageLimit {
		return false
	}
	b.messageCount++
	return true
}

func (limiter *ChatLimiter) allowTyping(roomID, principal string, isTyping bool) bool {
	if limiter == nil {
		return true
	}
	limiter.mu.Lock()
	defer limiter.mu.Unlock()

	now := limiter.now()
	limiter.operations++
	if limiter.operations%128 == 0 {
		limiter.cleanup(now)
	}

	key := roomID + ":" + principal
	b, ok := limiter.budgets[key]
	if !ok {
		b = &chatBudget{}
		limiter.budgets[key] = b
	}
	b.lastActivity = now

	// Coalesce redundant typing events of the same state within the cooldown window
	if b.lastTypingState != nil && *b.lastTypingState == isTyping {
		if now.Sub(b.lastTypingTime) < limiter.typingCooldown {
			return false
		}
	}

	// Throttle rapid typing state toggles
	if now.After(b.typingReset) {
		b.typingReset = now.Add(limiter.typingWindow)
		b.typingCount = 0
	}
	if b.typingCount >= limiter.typingLimit {
		return false
	}

	b.typingCount++
	stateCopy := isTyping
	b.lastTypingState = &stateCopy
	b.lastTypingTime = now
	return true
}

func (limiter *ChatLimiter) cleanup(now time.Time) {
	for key, b := range limiter.budgets {
		if now.Sub(b.lastActivity) > 5*time.Minute {
			delete(limiter.budgets, key)
		}
	}
}
