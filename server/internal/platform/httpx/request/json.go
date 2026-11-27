package request

import (
	jsonv2 "encoding/json/v2"
	"fmt"
	"io"
	"net/http"
)

const DefaultJSONBodyLimit int64 = 16 << 10

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
