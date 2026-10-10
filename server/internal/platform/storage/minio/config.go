package minio

import (
	"fmt"
	"strings"
)

type Config struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	Bucket    string
	Secure    bool
}

func (config Config) Validate() error {
	if config.Endpoint == "" || strings.Contains(config.Endpoint, "://") || strings.ContainsAny(config.Endpoint, "/?#@ \t\n") {
		return fmt.Errorf("MINIO_ENDPOINT must be a host and optional port")
	}
	if config.AccessKey == "" || config.SecretKey == "" {
		return fmt.Errorf("MinIO access and secret keys are required")
	}
	if len(config.Bucket) < 3 || len(config.Bucket) > 63 ||
		config.Bucket != strings.ToLower(config.Bucket) ||
		strings.ContainsAny(config.Bucket, "/\\ :\t\n") {
		return fmt.Errorf("MINIO_BUCKET must be a lowercase bucket name between 3 and 63 characters")
	}
	return nil
}
