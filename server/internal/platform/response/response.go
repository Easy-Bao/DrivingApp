package response

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

type Violation struct {
	Field  string `json:"field"`
	Reason string `json:"reason"`
}

type Problem struct {
	Type       string      `json:"type"`
	Title      string      `json:"title"`
	Status     int         `json:"status"`
	Code       string      `json:"code"`
	Detail     string      `json:"detail"`
	Error      string      `json:"error"`
	Message    string      `json:"message"`
	RequestID  string      `json:"request_id,omitempty"`
	Violations []Violation `json:"violations,omitempty"`
}

func JSON(writer http.ResponseWriter, status int, value any) {
	payload, err := json.Marshal(value)
	if err != nil {
		slog.Error("encode json response failed", "error", err, "status", status)
		WriteProblem(writer, Problem{
			Status:  http.StatusInternalServerError,
			Title:   "Something went wrong on our end",
			Detail:  "We encountered an unexpected issue while processing your request. Please try again in a few moments.",
			Message: "We encountered an unexpected issue while processing your request. Please try again in a few moments.",
		})
		return
	}
	writer.Header().Set("Content-Type", "application/json; charset=utf-8")
	writeJSON(writer, status, payload)
}

func Error(writer http.ResponseWriter, status int, message string) {
	WriteProblem(writer, Problem{
		Type:    "about:blank",
		Title:   http.StatusText(status),
		Status:  status,
		Code:    ProblemCode(status),
		Detail:  message,
		Error:   message,
		Message: message,
	})
}

func WriteProblem(writer http.ResponseWriter, problem Problem) {
	if problem.Status == 0 {
		problem.Status = http.StatusInternalServerError
	}
	if problem.Status < 100 || problem.Status > 999 {
		problem.Status = http.StatusInternalServerError
	}
	if problem.Type == "" {
		problem.Type = "about:blank"
	}
	if problem.Title == "" {
		problem.Title = http.StatusText(problem.Status)
	}
	if problem.Code == "" {
		problem.Code = ProblemCode(problem.Status)
	}
	if problem.Detail == "" {
		problem.Detail = problem.Message
	}
	if problem.Message == "" {
		problem.Message = problem.Detail
	}
	if problem.Error == "" {
		problem.Error = problem.Detail
	}
	if problem.RequestID == "" {
		problem.RequestID = writer.Header().Get("X-Request-ID")
	}
	payload, err := json.Marshal(problem)
	if err != nil {
		slog.Error("encode problem response failed", "error", err, "status", problem.Status)
		return
	}
	writer.Header().Set("Content-Type", "application/problem+json")
	writeJSON(writer, problem.Status, payload)
}

func writeJSON(writer http.ResponseWriter, status int, payload []byte) {
	writer.WriteHeader(status)
	payload = append(payload, '\n')
	if _, err := writer.Write(payload); err != nil {
		slog.Debug("write json response failed", "error", err, "status", status)
	}
}

func ProblemCode(status int) string {
	switch status {
	case http.StatusBadRequest, http.StatusUnprocessableEntity:
		return "validation_error"
	case http.StatusUnauthorized:
		return "unauthorized"
	case http.StatusForbidden:
		return "forbidden"
	case http.StatusNotFound:
		return "not_found"
	case http.StatusConflict, http.StatusLocked:
		return "conflict"
	case http.StatusRequestEntityTooLarge:
		return "payload_too_large"
	case http.StatusTooManyRequests:
		return "rate_limited"
	case http.StatusServiceUnavailable:
		return "service_unavailable"
	case http.StatusInternalServerError:
		return "internal_error"
	default:
		return "request_failed"
	}
}
