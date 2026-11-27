package cache

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

type sampleCachePayload struct {
	Name string `json:"name"`
	Age  int    `json:"age"`
}

func startFakeRedis(t *testing.T) (*redisclient.Client, map[string]string, *sync.Mutex) {
	t.Helper()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	var mu sync.Mutex
	store := make(map[string]string)

	done := make(chan struct{})
	t.Cleanup(func() {
		close(done)
		_ = ln.Close()
	})

	go func() {
		for {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			go serveFakeRESP(conn, store, &mu, done)
		}
	}()

	client := redisclient.NewClient(&redisclient.Options{
		Addr:     ln.Addr().String(),
		Protocol: 2,
	})
	t.Cleanup(func() { _ = client.Close() })
	return client, store, &mu
}

func serveFakeRESP(conn net.Conn, store map[string]string, mu *sync.Mutex, done <-chan struct{}) {
	defer func() { _ = conn.Close() }()
	reader := bufio.NewReader(conn)
	for {
		select {
		case <-done:
			return
		default:
		}
		args, err := readRESPArray(reader)
		if err != nil {
			return
		}
		if len(args) == 0 {
			continue
		}
		cmd := strings.ToUpper(args[0])
		mu.Lock()
		switch cmd {
		case "HELLO":
			_, _ = conn.Write([]byte("-ERR unknown command 'HELLO'\r\n"))
		case "CLIENT":
			_, _ = conn.Write([]byte("+OK\r\n"))
		case "SET":
			if len(args) >= 3 {
				store[args[1]] = args[2]
			}
			_, _ = conn.Write([]byte("+OK\r\n"))
		case "GET":
			if len(args) >= 2 {
				if val, ok := store[args[1]]; ok {
					_, _ = fmt.Fprintf(conn, "$%d\r\n%s\r\n", len(val), val)
				} else {
					_, _ = conn.Write([]byte("$-1\r\n"))
				}
			}
		default:
			_, _ = conn.Write([]byte("+OK\r\n"))
		}
		mu.Unlock()
	}
}

func readRESPArray(reader *bufio.Reader) ([]string, error) {
	line, err := reader.ReadString('\n')
	if err != nil {
		return nil, err
	}
	line = strings.TrimSuffix(line, "\r\n")
	if !strings.HasPrefix(line, "*") {
		return nil, errors.New("expected array")
	}
	count, err := strconv.Atoi(line[1:])
	if err != nil || count < 0 {
		return nil, io.EOF
	}
	args := make([]string, 0, count)
	for range count {
		hdr, err := reader.ReadString('\n')
		if err != nil {
			return nil, err
		}
		hdr = strings.TrimSuffix(hdr, "\r\n")
		if !strings.HasPrefix(hdr, "$") {
			return nil, errors.New("expected bulk string")
		}
		length, err := strconv.Atoi(hdr[1:])
		if err != nil {
			return nil, err
		}
		buf := make([]byte, length+2)
		if _, err := io.ReadFull(reader, buf); err != nil {
			return nil, err
		}
		args = append(args, string(buf[:length]))
	}
	return args, nil
}

func TestGetSetJSONRoundTripAndMiss(t *testing.T) {
	ctx := context.Background()
	if _, err := GetJSON[sampleCachePayload](ctx, nil, "missing"); err == nil {
		t.Fatal("expected error for nil redis client")
	}
	if err := SetJSON(ctx, nil, "missing", sampleCachePayload{}, time.Minute); err == nil {
		t.Fatal("expected error for nil redis client on SetJSON")
	}

	client, _, _ := startFakeRedis(t)
	if _, err := GetJSON[sampleCachePayload](ctx, client, "absent"); !errors.Is(err, ErrCacheMiss) {
		t.Fatalf("GetJSON miss error = %v, want ErrCacheMiss", err)
	}

	want := sampleCachePayload{Name: "driver", Age: 5}
	if err := SetJSON(ctx, client, "sample:1", want, time.Minute); err != nil {
		t.Fatalf("SetJSON failed: %v", err)
	}
	got, err := GetJSON[sampleCachePayload](ctx, client, "sample:1")
	if err != nil {
		t.Fatalf("GetJSON failed: %v", err)
	}
	if got != want {
		t.Fatalf("GetJSON = %#v, want %#v", got, want)
	}
}
