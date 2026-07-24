import { z } from 'zod';

const ServiceRegistrySchema = z.object({
  AUTH_SERVICE_URL: z.string().url('AUTH_SERVICE_URL must be a valid absolute URI'),
  PASSENGER_SERVICE_URL: z.string().url('PASSENGER_SERVICE_URL must be a valid absolute URI'),
  TRIP_SERVICE_URL: z.string().url('TRIP_SERVICE_URL must be a valid absolute URI'),
  DRIVER_SERVICE_URL: z.string().url('DRIVER_SERVICE_URL must be a valid absolute URI'),
  TELEMETRY_SERVICE_URL: z.string().url('TELEMETRY_SERVICE_URL must be a valid absolute URI'),
  BIDDING_SERVICE_URL: z.string().url('BIDDING_SERVICE_URL must be a valid absolute URI'),
  CHAT_SERVICE_URL: z.string().url('CHAT_SERVICE_URL must be a valid absolute URI'),
  FARE_SERVICE_URL: z.string().url('FARE_SERVICE_URL must be a valid absolute URI'),
});

function validateServiceRegistry() {
  const result = ServiceRegistrySchema.safeParse(process.env);
  if (!result.success) {
    const formattedErrors = result.error.errors
      .map((e) => `  - ${e.path.join('.')}: ${e.message}`)
      .join('\n');
    throw new Error(
      `Gateway Configuration Error: Service environment URLs failed validation:\n${formattedErrors}`,
    );
  }
  return {
    auth: result.data.AUTH_SERVICE_URL,
    passengers: result.data.PASSENGER_SERVICE_URL,
    rides: result.data.TRIP_SERVICE_URL,
    drivers: result.data.DRIVER_SERVICE_URL,
    telemetry: result.data.TELEMETRY_SERVICE_URL,
    bidding: result.data.BIDDING_SERVICE_URL,
    chat: result.data.CHAT_SERVICE_URL,
    fares: result.data.FARE_SERVICE_URL,
  } as const;
}

export const SERVICE_REGISTRY = validateServiceRegistry();
