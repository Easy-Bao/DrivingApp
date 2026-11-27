package app

import (
	"context"
	"net"
	"net/http"
	"sync"
	"testing"
	"time"
)

type backgroundTestRedisClient struct {
	mu     *sync.Mutex
	events *[]string
}

func (client backgroundTestRedisClient) Close() error {
	client.mu.Lock()
	defer client.mu.Unlock()
	*client.events = append(*client.events, "redis_close")
	return nil
}

func TestRunExecutesPeriodicRefreshPruningAndStopsBeforeClose(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen failed: %v", err)
	}
	addr := listener.Addr().String()
	_ = listener.Close()

	subscriber := newTestSubscriber(nil)
	var (
		mu         sync.Mutex
		events     []string
		pruneCalls int
	)
	firstPrune := make(chan struct{})
	var firstOnce sync.Once

	app := &Application{
		server: &http.Server{
			Addr: addr,
			Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusOK)
			}),
		},
		eventSubscriber:      subscriber,
		redisClient:          backgroundTestRedisClient{mu: &mu, events: &events},
		pruneRefreshInterval: 10 * time.Millisecond,
		pruneRefreshSessions: func(ctx context.Context) (int64, error) {
			mu.Lock()
			pruneCalls++
			call := pruneCalls
			events = append(events, "prune_start")
			mu.Unlock()
			firstOnce.Do(func() { close(firstPrune) })
			if call == 1 {
				time.Sleep(35 * time.Millisecond)
			}
			mu.Lock()
			events = append(events, "prune_end")
			mu.Unlock()
			return 1, nil
		},
	}

	ctx, cancel := context.WithCancel(context.Background())
	runDone := make(chan error, 1)
	go func() {
		runDone <- app.Run(ctx)
	}()

	subscriber.signalReady()

	select {
	case <-firstPrune:
	case <-time.After(3 * time.Second):
		t.Fatal("timed out waiting for periodic refresh session pruning")
	}

	cancel()

	select {
	case err := <-runDone:
		if err != nil {
			t.Fatalf("Run() error = %v, want nil", err)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("Run() did not stop after cancellation")
	}

	mu.Lock()
	recorded := append([]string(nil), events...)
	mu.Unlock()

	if len(recorded) < 3 {
		t.Fatalf("expected prune_start, prune_end, redis_close; got %v", recorded)
	}
	if recorded[len(recorded)-1] != "redis_close" {
		t.Fatalf("expected redis_close last after background task drained, got %v", recorded)
	}
}
