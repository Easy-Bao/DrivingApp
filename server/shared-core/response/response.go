package response

import (
	"encoding/json"
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
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(value)
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
	writer.Header().Set("Content-Type", "application/problem+json")
	writer.WriteHeader(problem.Status)
	_ = json.NewEncoder(writer).Encode(problem)
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
