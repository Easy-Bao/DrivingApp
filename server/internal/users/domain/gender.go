package domain

import "strings"

const DefaultGender = "Prefer not to say"

func NormalizeGender(value string) (string, bool) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "":
		return DefaultGender, true
	case "female":
		return "Female", true
	case "male":
		return "Male", true
	case "non-binary", "non_binary":
		return "Non-binary", true
	case "prefer not to say", "prefer_not_to_say":
		return DefaultGender, true
	default:
		return "", false
	}
}
