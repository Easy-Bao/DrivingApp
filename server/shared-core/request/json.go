package request

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
)

const DefaultJSONBodyLimit int64 = 16 << 10

var ErrMultipleJSONValues = errors.New("request body must contain one JSON value")

// DecodeJSON accepts exactly one object whose fields match the target contract.
func DecodeJSON(writer http.ResponseWriter, request *http.Request, target any, maxBytes int64) error {
	if request == nil || request.Body == nil {
		return io.EOF
	}
	if maxBytes <= 0 {
		maxBytes = DefaultJSONBodyLimit
	}

	decoder := json.NewDecoder(http.MaxBytesReader(writer, request.Body, maxBytes))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return fmt.Errorf("decode request body: %w", err)
	}

	var trailing any
	if err := decoder.Decode(&trailing); !errors.Is(err, io.EOF) {
		if err == nil {
			return ErrMultipleJSONValues
		}
		return fmt.Errorf("decode trailing request body: %w", err)
	}
	return nil
}
