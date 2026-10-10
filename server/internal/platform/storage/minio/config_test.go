package minio

import "testing"

func TestConfigValidateAcceptsDockerServiceEndpoint(t *testing.T) {
	config := Config{
		Endpoint:  "minio:9000",
		AccessKey: "driveapp",
		SecretKey: "test-secret",
		Bucket:    "private-objects",
	}
	if err := config.Validate(); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
}

func TestConfigValidateRejectsInvalidSettings(t *testing.T) {
	base := Config{
		Endpoint:  "minio:9000",
		AccessKey: "driveapp",
		SecretKey: "test-secret",
		Bucket:    "private-objects",
	}
	tests := map[string]func(*Config){
		"missing endpoint": func(config *Config) { config.Endpoint = "" },
		"URL endpoint":     func(config *Config) { config.Endpoint = "http://minio:9000" },
		"missing access key": func(config *Config) {
			config.AccessKey = ""
		},
		"missing secret key": func(config *Config) {
			config.SecretKey = ""
		},
		"invalid bucket": func(config *Config) { config.Bucket = "Private-Objects" },
	}
	for name, change := range tests {
		t.Run(name, func(t *testing.T) {
			config := base
			change(&config)
			if err := config.Validate(); err == nil {
				t.Fatal("Validate() accepted invalid configuration")
			}
		})
	}
}
