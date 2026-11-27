package app

import (
	"context"
	"errors"
	"net"
	"net/http"
	"sync"
	"testing"
	"time"
)

type testSubscriber struct {
	ready  chan struct{}
	runErr error
	stop   chan struct{}
	once   sync.Once
}

func newTestSubscriber(runErr error) *testSubscriber {
	return &testSubscriber{
		ready:  make(chan struct{}),
		runErr: runErr,
		stop:   make(chan struct{}),
	}
}

func (subscriber *testSubscriber) Ready() <-chan struct{} {
	return subscriber.ready
}

func (subscriber *testSubscriber) signalReady() {
	subscriber.once.Do(func() {
		close(subscriber.ready)
	})
}

func (subscriber *testSubscriber) Run(ctx context.Context) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-subscriber.stop:
		return subscriber.runErr
	}
}

func TestRunStopsServerOnSubscriberError(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen failed: %v", err)
	}

	subscriberErr := errors.New("simulated redis subscriber disconnect")
	subscriber := newTestSubscriber(subscriberErr)

	server := &http.Server{
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
		}),
	}

	app := &Application{
		server:          server,
		eventSubscriber: subscriber,
	}

	runDone := make(chan error, 1)

	_ = listener.Close()
	server.Addr = listener.Addr().String()

	go func() {
		runDone <- app.Run(context.Background())
	}()

	subscriber.signalReady()

	var clientErr error
	for range 20 {
		time.Sleep(20 * time.Millisecond)
		resp, err := http.Get("http://" + server.Addr)
		if err == nil {
			resp.Body.Close()
			clientErr = nil
			break
		}
		clientErr = err
	}
	if clientErr != nil {
		t.Fatalf("server did not start accepting requests: %v", clientErr)
	}

	close(subscriber.stop)

	select {
	case err := <-runDone:
		if !errors.Is(err, subscriberErr) {
			t.Fatalf("Run() error = %v, want %v", err, subscriberErr)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("Run() did not return within timeout after subscriber error")
	}

	_, err = http.Get("http://" + server.Addr)
	if err == nil {
		t.Fatal("expected server to be stopped and reject requests, but request succeeded")
	}
}

func TestRunStopsServerOnContextCancellation(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen failed: %v", err)
	}
	addr := listener.Addr().String()
	_ = listener.Close()

	subscriber := newTestSubscriber(nil)
	server := &http.Server{
		Addr: addr,
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
		}),
	}

	app := &Application{
		server:          server,
		eventSubscriber: subscriber,
	}

	ctx, cancel := context.WithCancel(context.Background())
	runDone := make(chan error, 1)
	go func() {
		runDone <- app.Run(ctx)
	}()

	subscriber.signalReady()

	for range 20 {
		time.Sleep(20 * time.Millisecond)
		resp, err := http.Get("http://" + addr)
		if err == nil {
			resp.Body.Close()
			break
		}
	}

	cancel()

	select {
	case err := <-runDone:
		if err != nil {
			t.Fatalf("Run() error = %v, want nil on cancel", err)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("Run() did not return within timeout after context cancellation")
	}

	_, err = http.Get("http://" + addr)
	if err == nil {
		t.Fatal("expected server to be stopped after cancellation")
	}
}

type orderRecordingRedisClient struct {
	mu     *sync.Mutex
	events *[]string
}

func (client orderRecordingRedisClient) Close() error {
	client.mu.Lock()
	*client.events = append(*client.events, "redis_closed")
	client.mu.Unlock()
	return nil
}

func TestRunExecutesChatHistoryRetentionAsynchronouslyAndAwaitsBeforeClosingRedis(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen failed: %v", err)
	}
	addr := listener.Addr().String()
	_ = listener.Close()

	var (
		mu             sync.Mutex
		lifecycleOrder []string
	)
	retentionStarted := make(chan struct{})
	subscriber := newTestSubscriber(nil)
	server := &http.Server{
		Addr: addr,
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
		}),
	}
	application := &Application{
		server:          server,
		eventSubscriber: subscriber,
		redisClient:     orderRecordingRedisClient{mu: &mu, events: &lifecycleOrder},
		migrateChatHistory: func(ctx context.Context) error {
			close(retentionStarted)
			<-ctx.Done()
			mu.Lock()
			lifecycleOrder = append(lifecycleOrder, "retention_done")
			mu.Unlock()
			return ctx.Err()
		},
	}

	ctx, cancel := context.WithCancel(context.Background())
	runDone := make(chan error, 1)
	go func() {
		runDone <- application.Run(ctx)
	}()

	subscriber.signalReady()

	select {
	case <-retentionStarted:
	case <-time.After(3 * time.Second):
		t.Fatal("migrateChatHistory did not start")
	}

	// HTTP must already be serving while retention is still blocked.
	var clientErr error
	for range 20 {
		time.Sleep(20 * time.Millisecond)
		resp, err := http.Get("http://" + addr)
		if err == nil {
			resp.Body.Close()
			clientErr = nil
			break
		}
		clientErr = err
	}
	if clientErr != nil {
		t.Fatalf("server blocked on chat retention: %v", clientErr)
	}

	cancel()

	select {
	case err := <-runDone:
		if err != nil {
			t.Fatalf("Run() error = %v, want nil", err)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("Run() did not stop cleanly")
	}

	mu.Lock()
	defer mu.Unlock()
	if len(lifecycleOrder) != 2 || lifecycleOrder[0] != "retention_done" || lifecycleOrder[1] != "redis_closed" {
		t.Fatalf("shutdown order = %v, want [retention_done redis_closed]", lifecycleOrder)
	}
}
