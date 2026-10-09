package minio

import "testing"

func TestConfigFromEnvDefaultsToInsecureLocalMinIO(t *testing.T) {
	values := map[string]string{
		"MINIO_ENDPOINT":   "minio:9000",
		"MINIO_ACCESS_KEY": "driveapp",
		"MINIO_SECRET_KEY": "local-secret",
		"MINIO_BUCKET":     "private-objects",
	}
	config, err := ConfigFromEnv(func(key string) string { return values[key] })
	if err != nil {
		t.Fatalf("ConfigFromEnv() error = %v", err)
	}
	if config.Secure {
		t.Fatalf("MinIO secure default = %t, want false", config.Secure)
	}
}

func TestConfigFromEnvReadsMinIOTLSSetting(t *testing.T) {
	values := map[string]string{
		"MINIO_ENDPOINT":   "storage.example.test:9000",
		"MINIO_ACCESS_KEY": "driveapp",
		"MINIO_SECRET_KEY": "local-secret",
		"MINIO_BUCKET":     "private-objects",
		"MINIO_USE_SSL":    "true",
	}
	config, err := ConfigFromEnv(func(key string) string { return values[key] })
	if err != nil {
		t.Fatalf("ConfigFromEnv() error = %v", err)
	}
	if !config.Secure {
		t.Fatalf("MinIO secure setting = %t, want true", config.Secure)
	}
}

func TestConfigFromEnvRejectsMissingCredentialsAndInvalidSettings(t *testing.T) {
	base := map[string]string{
		"MINIO_ENDPOINT":   "minio:9000",
		"MINIO_ACCESS_KEY": "driveapp",
		"MINIO_SECRET_KEY": "local-secret",
		"MINIO_BUCKET":     "private-objects",
	}
	for name, change := range map[string]func(map[string]string){
		"missing bucket":      func(values map[string]string) { delete(values, "MINIO_BUCKET") },
		"missing secret":      func(values map[string]string) { delete(values, "MINIO_SECRET_KEY") },
		"endpoint URL":        func(values map[string]string) { values["MINIO_ENDPOINT"] = "http://minio:9000" },
		"invalid TLS boolean": func(values map[string]string) { values["MINIO_USE_SSL"] = "sometimes" },
	} {
		t.Run(name, func(t *testing.T) {
			values := make(map[string]string, len(base)+1)
			for key, value := range base {
				values[key] = value
			}
			change(values)
			if _, err := ConfigFromEnv(func(key string) string { return values[key] }); err == nil {
				t.Fatal("ConfigFromEnv() accepted invalid MinIO settings")
			}
		})
	}
}
