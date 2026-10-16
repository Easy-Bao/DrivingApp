package domain

import "testing"

func TestNormalizeGenderKeepsTheProfileContractCanonical(t *testing.T) {
	tests := map[string]string{
		"female":            "Female",
		" Male ":            "Male",
		"non_binary":        "Non-binary",
		"prefer_not_to_say": DefaultGender,
		"":                  DefaultGender,
	}
	for input, expected := range tests {
		actual, valid := NormalizeGender(input)
		if !valid || actual != expected {
			t.Fatalf("NormalizeGender(%q) = %q, %t; want %q, true", input, actual, valid, expected)
		}
	}
	if _, valid := NormalizeGender("unknown"); valid {
		t.Fatal("unknown gender was accepted")
	}
}
