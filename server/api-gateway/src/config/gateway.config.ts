function requireEnvVar(variableName: string): string {
  const value = process.env[variableName];
  if (!value) {
    throw new Error(`Configuration Error: '${variableName}' is required but not set.`);
  }
  return value;
}

export const SERVICE_REGISTRY = {
  passengers: requireEnvVar('PASSENGER_SERVICE_URL'),
  rides:      requireEnvVar('TRIP_SERVICE_URL'),
  drivers:    requireEnvVar('DRIVER_SERVICE_URL'),
  telemetry:  requireEnvVar('TELEMETRY_SERVICE_URL'),
  bidding:    requireEnvVar('BIDDING_SERVICE_URL'),
  chat:       requireEnvVar('CHAT_SERVICE_URL'),
} as const;
