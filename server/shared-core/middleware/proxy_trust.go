package middleware

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"net/netip"
	"strings"
)

type ProxyTrust struct {
	trusted []netip.Prefix
}

func NewProxyTrust(rawCIDRs string) (*ProxyTrust, error) {
	values := strings.Split(rawCIDRs, ",")
	trusted := make([]netip.Prefix, 0, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		prefix, err := netip.ParsePrefix(value)
		if err != nil {
			return nil, fmt.Errorf("parse trusted proxy CIDR %q: %w", value, err)
		}
		trusted = append(trusted, prefix.Masked())
	}
	return &ProxyTrust{trusted: trusted}, nil
}

func (trust *ProxyTrust) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		peer, peerOK := parseRequestAddress(request.RemoteAddr)
		client := peer
		scheme := connectionScheme(request)
		if peerOK && trust.isTrusted(peer) {
			if forwarded, ok := trust.forwardedClient(request.Header.Values("X-Forwarded-For")); ok {
				client = forwarded
			}
			if forwarded := forwardedScheme(request.Header.Values("X-Forwarded-Proto")); forwarded != "" {
				scheme = forwarded
			}
		}

		clearForwardedHeaders(request.Header)
		clientValue := strings.TrimSpace(request.RemoteAddr)
		if client.IsValid() {
			clientValue = client.String()
			request.Header.Set("X-Forwarded-For", clientValue)
		}
		request.Header.Set("X-Forwarded-Proto", scheme)

		contextValue := context.WithValue(request.Context(), clientIPKey{}, clientValue)
		contextValue = context.WithValue(contextValue, requestSchemeKey{}, scheme)
		next.ServeHTTP(writer, request.WithContext(contextValue))
	})
}

func ClientIPFromRequest(request *http.Request) string {
	if request == nil {
		return "unknown"
	}
	if value, ok := request.Context().Value(clientIPKey{}).(string); ok && value != "" {
		return value
	}
	if address, ok := parseRequestAddress(request.RemoteAddr); ok {
		return address.String()
	}
	if value := strings.TrimSpace(request.RemoteAddr); value != "" {
		return value
	}
	return "unknown"
}

func RequestSchemeFromRequest(request *http.Request) string {
	if request == nil {
		return "http"
	}
	if value, ok := request.Context().Value(requestSchemeKey{}).(string); ok && value != "" {
		return value
	}
	return connectionScheme(request)
}

func (trust *ProxyTrust) isTrusted(address netip.Addr) bool {
	if trust == nil {
		return false
	}
	address = address.Unmap()
	for _, prefix := range trust.trusted {
		if prefix.Contains(address) {
			return true
		}
	}
	return false
}

func (trust *ProxyTrust) forwardedClient(headerValues []string) (netip.Addr, bool) {
	addresses := forwardedAddresses(headerValues)
	for index := len(addresses) - 1; index >= 0; index-- {
		if !trust.isTrusted(addresses[index]) {
			return addresses[index], true
		}
	}
	if len(addresses) > 0 {
		return addresses[0], true
	}
	return netip.Addr{}, false
}

func forwardedAddresses(headerValues []string) []netip.Addr {
	addresses := make([]netip.Addr, 0, len(headerValues))
	for _, headerValue := range headerValues {
		for _, value := range strings.Split(headerValue, ",") {
			if address, ok := parseRequestAddress(strings.TrimSpace(value)); ok {
				addresses = append(addresses, address)
			}
		}
	}
	return addresses
}

func forwardedScheme(headerValues []string) string {
	for valueIndex := len(headerValues) - 1; valueIndex >= 0; valueIndex-- {
		parts := strings.Split(headerValues[valueIndex], ",")
		for partIndex := len(parts) - 1; partIndex >= 0; partIndex-- {
			value := strings.ToLower(strings.TrimSpace(parts[partIndex]))
			if value == "http" || value == "https" {
				return value
			}
		}
	}
	return ""
}

func parseRequestAddress(value string) (netip.Addr, bool) {
	value = strings.TrimSpace(value)
	if addressPort, err := netip.ParseAddrPort(value); err == nil {
		return addressPort.Addr().Unmap(), true
	}
	if address, err := netip.ParseAddr(value); err == nil {
		return address.Unmap(), true
	}
	host, _, err := net.SplitHostPort(value)
	if err != nil {
		return netip.Addr{}, false
	}
	address, err := netip.ParseAddr(host)
	if err != nil {
		return netip.Addr{}, false
	}
	return address.Unmap(), true
}

func clearForwardedHeaders(header http.Header) {
	header.Del("Forwarded")
	header.Del("X-Forwarded-For")
	header.Del("X-Forwarded-Host")
	header.Del("X-Forwarded-Port")
	header.Del("X-Forwarded-Proto")
}

func connectionScheme(request *http.Request) string {
	if request != nil && request.TLS != nil {
		return "https"
	}
	return "http"
}

type clientIPKey struct{}
type requestSchemeKey struct{}
