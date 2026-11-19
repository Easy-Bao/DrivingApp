package ws

import (
	"sync"
	"time"
)

const defaultMaxChatLimiterEntries = 10_000

type chatBudgetKey struct {
	roomID    string
	principal string
}

type chatBudget struct {
	messageCount int
	messageReset time.Time

	hasTypingState  bool
	lastTypingState bool
	lastTypingTime  time.Time
	typingCount     int
	typingReset     time.Time

	lastActivity time.Time
}

type ChatLimiter struct {
	mu             sync.Mutex
	budgets        map[chatBudgetKey]*chatBudget
	maxEntries     int
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
		budgets:        make(map[chatBudgetKey]*chatBudget),
		maxEntries:     defaultMaxChatLimiterEntries,
		messageLimit:   10,
		messageWindow:  5 * time.Second,
		typingLimit:    10,
		typingWindow:   5 * time.Second,
		typingCooldown: 2 * time.Second,
		now:            time.Now,
	}
}

func (limiter *ChatLimiter) budgetLocked(roomID, principal string, now time.Time) *chatBudget {
	limiter.operations++
	if limiter.operations%128 == 0 {
		limiter.cleanup(now)
	}

	key := chatBudgetKey{roomID: roomID, principal: principal}
	budget, ok := limiter.budgets[key]
	if !ok {
		maxEntries := limiter.maxEntries
		if maxEntries <= 0 {
			maxEntries = defaultMaxChatLimiterEntries
		}
		if len(limiter.budgets) >= maxEntries {
			limiter.cleanup(now)
			for len(limiter.budgets) >= maxEntries {
				limiter.evictOldestLocked()
			}
		}
		budget = &chatBudget{}
		limiter.budgets[key] = budget
	}
	budget.lastActivity = now
	return budget
}

func (limiter *ChatLimiter) evictOldestLocked() {
	var (
		oldestKey  chatBudgetKey
		oldestTime time.Time
		found      bool
	)
	for key, budget := range limiter.budgets {
		if !found || budget.lastActivity.Before(oldestTime) {
			oldestKey = key
			oldestTime = budget.lastActivity
			found = true
		}
	}
	if found {
		delete(limiter.budgets, oldestKey)
	}
}

func (limiter *ChatLimiter) allowMessage(roomID, principal string) bool {
	if limiter == nil {
		return true
	}
	limiter.mu.Lock()
	defer limiter.mu.Unlock()

	now := limiter.now()
	b := limiter.budgetLocked(roomID, principal, now)

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
	b := limiter.budgetLocked(roomID, principal, now)

	// Coalesce redundant typing events of the same state within the cooldown window.
	if b.hasTypingState && b.lastTypingState == isTyping {
		if now.Sub(b.lastTypingTime) < limiter.typingCooldown {
			return false
		}
	}

	// Always allow a single stop-typing transition from active typing so peers
	// are never left with a stuck typing indicator when throttled.
	stoppingFromTyping := !isTyping && b.hasTypingState && b.lastTypingState

	// Throttle rapid typing state toggles.
	if now.After(b.typingReset) {
		b.typingReset = now.Add(limiter.typingWindow)
		b.typingCount = 0
	}
	if b.typingCount >= limiter.typingLimit && !stoppingFromTyping {
		return false
	}

	if b.typingCount < limiter.typingLimit {
		b.typingCount++
	}
	b.hasTypingState = true
	b.lastTypingState = isTyping
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
