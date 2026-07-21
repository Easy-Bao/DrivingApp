import { db } from '../../shared/drizzle.ts';
import { servicePricingRules, fareTransactions } from '../../db/schema.ts';
import { eq } from 'drizzle-orm';

export interface ServiceEstimate {
  service_type: string;
  base_fare: number;
  per_km_rate: number;
  per_minute_rate: number;
  distance_km: number;
  duration_minutes: number;
  surge_multiplier: number;
  total_fare: number;
}

export interface FinalFareResult {
  ride_id: string;
  service_type: string;
  distance_km: number;
  duration_minutes: number;
  base_fare: number;
  distance_charge: number;
  time_charge: number;
  surge_charge: number;
  total_fare: number;
  driver_earnings: number;
  platform_fee: number;
  payment_method: string;
}

export class FareService {
  private static readonly DEFAULT_RULES = [
    { serviceType: 'Solo Ride', baseFare: 20.0, perKmRate: 10.0, perMinuteRate: 1.5, minimumFare: 25.0 },
    { serviceType: 'Share-Bao', baseFare: 15.0, perKmRate: 7.0, perMinuteRate: 1.0, minimumFare: 20.0 },
    { serviceType: 'Bao Premium', baseFare: 35.0, perKmRate: 15.0, perMinuteRate: 2.0, minimumFare: 40.0 },
  ];

  private async ensureRulesSeeded(): Promise<any[]> {
    try {
      const existing = await db.select().from(servicePricingRules);
      if (existing.length > 0) return existing;

      for (const rule of FareService.DEFAULT_RULES) {
        await db.insert(servicePricingRules).values(rule).onConflictDoNothing();
      }
      return await db.select().from(servicePricingRules);
    } catch (_) {
      return FareService.DEFAULT_RULES.map((r) => ({
        ...r,
        surgeMultiplier: 1.0,
        isActive: true,
      }));
    }
  }

  async estimateFares(distanceKm: number, durationMinutes: number = 0.0): Promise<{ currency: string; estimates: ServiceEstimate[] }> {
    const rules = await this.ensureRulesSeeded();
    const estimates: ServiceEstimate[] = [];

    for (const rule of rules) {
      const base = rule.baseFare ?? 20.0;
      const perKm = rule.perKmRate ?? 10.0;
      const perMin = rule.perMinuteRate ?? 1.5;
      const minFare = rule.minimumFare ?? 25.0;
      const surge = rule.surgeMultiplier ?? 1.0;

      const rawSubtotal = (base + (distanceKm * perKm) + (durationMinutes * perMin)) * surge;
      const clampedTotal = rawSubtotal < minFare ? minFare : rawSubtotal;
      const totalFare = Math.round(clampedTotal * 2) / 2; // Round to nearest 0.50

      estimates.push({
        service_type: rule.serviceType,
        base_fare: base,
        per_km_rate: perKm,
        per_minute_rate: perMin,
        distance_km: distanceKm,
        duration_minutes: durationMinutes,
        surge_multiplier: surge,
        total_fare: totalFare,
      });
    }

    return {
      currency: 'PHP',
      estimates,
    };
  }

  async calculateFinalFare(
    rideId: string,
    distanceKm: number,
    durationMinutes: number,
    rideType: string = 'Solo Ride',
    surgeMultiplier: number = 1.0,
  ): Promise<FinalFareResult> {
    const rules = await this.ensureRulesSeeded();
    const rule = rules.find((r) => r.serviceType === rideType) || rules[0];

    const baseFare = rule.baseFare ?? 20.0;
    const distanceCharge = distanceKm * (rule.perKmRate ?? 10.0);
    const timeCharge = durationMinutes * (rule.perMinuteRate ?? 1.5);
    const rawSubtotal = baseFare + distanceCharge + timeCharge;
    const surgeCharge = rawSubtotal * (surgeMultiplier - 1.0);
    const rawTotal = rawSubtotal + surgeCharge;
    const minimumFare = rule.minimumFare ?? 25.0;
    const totalFare = Math.round((rawTotal < minimumFare ? minimumFare : rawTotal) * 2) / 2;

    const driverEarnings = Math.round(totalFare * 0.8 * 100) / 100; // 80% to driver
    const platformFee = Math.round((totalFare - driverEarnings) * 100) / 100; // 20% platform fee

    try {
      await db.insert(fareTransactions).values({
        rideId,
        serviceType: rideType,
        distanceKm,
        durationMinutes,
        baseFare,
        distanceCharge,
        timeCharge,
        surgeCharge,
        totalFare,
        driverEarnings,
        platformFee,
      });
    } catch (_) {}

    return {
      ride_id: rideId,
      service_type: rideType,
      distance_km: distanceKm,
      duration_minutes: durationMinutes,
      base_fare: baseFare,
      distance_charge: distanceCharge,
      time_charge: timeCharge,
      surge_charge: surgeCharge,
      total_fare: totalFare,
      driver_earnings: driverEarnings,
      platform_fee: platformFee,
      payment_method: 'Cash on Hand',
    };
  }
}
