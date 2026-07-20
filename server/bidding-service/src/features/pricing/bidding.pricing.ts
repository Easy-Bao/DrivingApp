/**
 * Fare calculation engine isolated from orchestration logic, making it independently unit-testable
 * without database or HTTP dependencies. All ride-type configs live here as the single source of truth.
 */

export type FareConfig = {
  base: number;
  perKm: number;
  perMin: number;
  minFare: number;
};

export type FareBreakdown = {
  base_fare: number;
  distance_charge: number;
  time_charge: number;
  surge_charge: number;
  total_fare: number;
};

export const FARE_CONFIGS: Record<string, FareConfig> = {
  'Solo Ride':  { base: 20, perKm: 10, perMin: 1.5, minFare: 25 },
  'Share-Bao':  { base: 15, perKm: 7,  perMin: 1.0, minFare: 18 },
  'Bao Premium':{ base: 35, perKm: 15, perMin: 2.0, minFare: 40 },
};

export function computeFareAmount(
  rideType: string,
  distanceKm: number,
  durationMinutes: number
): FareBreakdown {
  const cfg = FARE_CONFIGS[rideType] ?? FARE_CONFIGS['Solo Ride'];
  const distanceCharge = distanceKm * cfg.perKm;
  const timeCharge = durationMinutes * cfg.perMin;
  const subtotal = cfg.base + distanceCharge + timeCharge;
  const rawTotal = Math.max(subtotal, cfg.minFare);

  return {
    base_fare: cfg.base,
    distance_charge: parseFloat(distanceCharge.toFixed(2)),
    time_charge: parseFloat(timeCharge.toFixed(2)),
    surge_charge: 0,
    total_fare: Math.round(rawTotal * 2) / 2,
  };
}
