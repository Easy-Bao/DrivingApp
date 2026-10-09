package middleware

import (
	"net/http"
	"strings"
)

func Deprecation(successorPath string) func(http.Handler) http.Handler {
	return deprecationTarget(func(*http.Request) string {
		return successorPath
	})
}

func DeprecationPrefix(legacyPrefix, successorPrefix string) func(http.Handler) http.Handler {
	return deprecationTarget(func(request *http.Request) string {
		path := request.URL.EscapedPath()
		return successorPrefix + strings.TrimPrefix(path, legacyPrefix)
	})
}

func deprecationTarget(successorPath func(*http.Request) string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			successor := successorPath(request)
			if query := request.URL.Query().Encode(); query != "" {
				successor += "?" + query
			}
			writer.Header().Set("Deprecation", "true")
			writer.Header().Set("Link", "<"+successor+">; rel=\"successor-version\"")
			next.ServeHTTP(writer, request)
		})
	}
}
