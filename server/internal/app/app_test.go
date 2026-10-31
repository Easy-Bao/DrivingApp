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
	go func() {
		// Replace server.ListenAndServe with custom listener serving by wrapping
		// For Application.Run, it calls application.server.ListenAndServe().
		// Since Addr is listener.Addr().String(), close listener first so ListenAndServe can bind.
	}()

	_ = listener.Close()
	server.Addr = listener.Addr().String()

	go func() {
		runDone <- app.Run(context.Background())
	}()

	// Wait briefly, signal subscriber readiness so server starts listening
	subscriber.signalReady()

	// Wait for server to bind and listen
	var clientErr error
	for i := 0; i < 20; i++ {
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

	// Trigger subscriber error
	close(subscriber.stop)

	select {
	case err := <-runDone:
		if !errors.Is(err, subscriberErr) {
			t.Fatalf("Run() error = %v, want %v", err, subscriberErr)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("Run() did not return within timeout after subscriber error")
	}

	// Verify server was stopped: requests should fail
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

	for i := 0; i < 20; i++ {
		time.Sleep(20 * time.Millisecond)
		resp, err := http.Get("http://" + addr)
		if err == nil {
			resp.Body.Close()
			break
		}
	}

	// Cancel context to stop application
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
