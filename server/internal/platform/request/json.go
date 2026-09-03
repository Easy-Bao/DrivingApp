package request

import (
	"encoding/json"
	jsonv2 "encoding/json/v2"
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

// DecodeJSONV2 accepts exactly one object using the strict streaming decoder.
// Case-insensitive field matching is retained for existing clients while
// duplicate members, unknown fields, invalid UTF-8, and trailing documents are
// rejected by the v2 contract.
func DecodeJSONV2(writer http.ResponseWriter, request *http.Request, target any, maxBytes int64) error {
	if request == nil || request.Body == nil {
		return io.EOF
	}
	if maxBytes <= 0 {
		maxBytes = DefaultJSONBodyLimit
	}

	decoderInput := http.MaxBytesReader(writer, request.Body, maxBytes)
	if err := jsonv2.UnmarshalRead(
		decoderInput,
		target,
		jsonv2.RejectUnknownMembers(true),
		jsonv2.MatchCaseInsensitiveNames(true),
	); err != nil {
		return fmt.Errorf("decode request body: %w", err)
	}
	return nil
}
