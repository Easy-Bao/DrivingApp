package minio

import (
	"fmt"
	"strconv"
	"strings"
)

type Config struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	Bucket    string
	Secure    bool
}

func ConfigFromEnv(getenv func(string) string) (Config, error) {
	if getenv == nil {
		return Config{}, fmt.Errorf("MinIO environment reader is required")
	}

	endpoint, err := requiredEnv(getenv, "MINIO_ENDPOINT")
	if err != nil {
		return Config{}, err
	}
	accessKey, err := requiredEnv(getenv, "MINIO_ACCESS_KEY")
	if err != nil {
		return Config{}, err
	}
	secretKey, err := requiredEnv(getenv, "MINIO_SECRET_KEY")
	if err != nil {
		return Config{}, err
	}
	bucket, err := requiredEnv(getenv, "MINIO_BUCKET")
	if err != nil {
		return Config{}, err
	}

	secure, err := optionalBoolEnv(getenv, "MINIO_USE_SSL")
	if err != nil {
		return Config{}, err
	}
	config := Config{
		Endpoint:  endpoint,
		AccessKey: accessKey,
		SecretKey: secretKey,
		Bucket:    bucket,
		Secure:    secure,
	}
	if err := config.validate(); err != nil {
		return Config{}, err
	}
	return config, nil
}

func (config Config) validate() error {
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

func requiredEnv(getenv func(string) string, key string) (string, error) {
	value := strings.TrimSpace(getenv(key))
	if value == "" {
		return "", fmt.Errorf("%s is required", key)
	}
	return value, nil
}

func optionalBoolEnv(getenv func(string) string, key string) (bool, error) {
	value := strings.TrimSpace(getenv(key))
	if value == "" {
		return false, nil
	}
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return false, fmt.Errorf("%s must be a boolean", key)
	}
	return parsed, nil
}
