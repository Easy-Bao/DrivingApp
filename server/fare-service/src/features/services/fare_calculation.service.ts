import { db } from '../../shared/drizzle.ts';
import { servicePricingRules, fareTransactions } from '../../db/schema.ts';
import { eq } from 'drizzle-orm';
import { PricingConfigService } from './pricing_config.service.ts';

export interface ServiceEstimate {
  serviceType: string;
  service_type?: string;
  baseFare: number;
  base_fare?: number;
  perKmRate: number;
  per_km_rate?: number;
  perMinuteRate: number;
  per_minute_rate?: number;
  distanceKm: number;
  distance_km?: number;
  durationMinutes: number;
  duration_minutes?: number;
  surgeMultiplier: number;
  surge_multiplier?: number;
  totalFare: number;
  total_fare?: number;
}

export interface FinalFareResult {
  rideId: string;
  ride_id?: string;
  serviceType: string;
  service_type?: string;
  distanceKm: number;
  distance_km?: number;
  durationMinutes: number;
  duration_minutes?: number;
  baseFare: number;
  base_fare?: number;
  distanceCharge: number;
  distance_charge?: number;
  timeCharge: number;
  time_charge?: number;
  surgeCharge: number;
  surge_charge?: number;
  totalFare: number;
  total_fare?: number;
  driverEarnings: number;
  driver_earnings?: number;
  platformFee: number;
  platform_fee?: number;
  paymentMethod: string;
  payment_method?: string;
}

export class FareCalculationService {
  private pricingConfigService = new PricingConfigService();

  private roundToHalfUnit(amount: number): number {
    return Math.round(amount * 2) / 2;
  }

  private roundCurrency(amount: number): number {
    return Math.round((amount + Number.EPSILON) * 100) / 100;
  }

  async estimateFares(
    distanceKm: number,
    durationMinutes: number = 0.0,
  ): Promise<{ currency: string; estimates: ServiceEstimate[] }> {
    const rules = await this.pricingConfigService.getPricingConfigs();

    const estimates: ServiceEstimate[] = rules.map((rule) => {
      const base = rule.baseFare ?? 20.0;
      const perKm = rule.perKmRate ?? 10.0;
      const perMin = rule.perMinuteRate ?? 1.5;
      const minFare = rule.minimumFare ?? 25.0;
      const surge = rule.surgeMultiplier ?? 1.0;

      const rawSubtotal = (base + distanceKm * perKm + durationMinutes * perMin) * surge;
      const clampedTotal = Math.max(rawSubtotal, minFare);
      const totalFare = this.roundToHalfUnit(clampedTotal);

      return {
        serviceType: rule.serviceType,
        service_type: rule.serviceType,
        baseFare: base,
        base_fare: base,
        perKmRate: perKm,
        per_km_rate: perKm,
        perMinuteRate: perMin,
        per_minute_rate: perMin,
        distanceKm,
        distance_km: distanceKm,
        durationMinutes,
        duration_minutes: durationMinutes,
        surgeMultiplier: surge,
        surge_multiplier: surge,
        totalFare,
        total_fare: totalFare,
      };
    });

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
    let rule: any = null;
    try {
      const rules = await db
        .select()
        .from(servicePricingRules)
        .where(eq(servicePricingRules.serviceType, rideType))
        .limit(1);
      rule = rules[0];
    } catch (_) {}

    if (!rule) {
      const fallbackRules = await this.pricingConfigService.getPricingConfigs();
      rule = fallbackRules.find((r) => r.serviceType === rideType) || fallbackRules[0];
    }

    const baseFare = rule.baseFare ?? 20.0;
    const distanceCharge = distanceKm * (rule.perKmRate ?? 10.0);
    const timeCharge = durationMinutes * (rule.perMinuteRate ?? 1.5);
    const rawSubtotal = baseFare + distanceCharge + timeCharge;
    const surgeCharge = rawSubtotal * (surgeMultiplier - 1.0);
    const rawTotal = rawSubtotal + surgeCharge;
    const minimumFare = rule.minimumFare ?? 25.0;

    const totalFare = this.roundToHalfUnit(Math.max(rawTotal, minimumFare));
    const driverEarnings = this.roundCurrency(totalFare * 0.8);
    const platformFee = this.roundCurrency(totalFare - driverEarnings);

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
    } catch (error) {
      console.error(`[FareCalculationService] Database write error for ride ${rideId}:`, error);
    }

    return {
      rideId,
      ride_id: rideId,
      serviceType: rideType,
      service_type: rideType,
      distanceKm,
      distance_km: distanceKm,
      durationMinutes,
      duration_minutes: durationMinutes,
      baseFare,
      base_fare: baseFare,
      distanceCharge,
      distance_charge: distanceCharge,
      timeCharge,
      time_charge: timeCharge,
      surgeCharge,
      surge_charge: surgeCharge,
      totalFare,
      total_fare: totalFare,
      driverEarnings,
      driver_earnings: driverEarnings,
      platformFee,
      platform_fee: platformFee,
      paymentMethod: 'Cash on Hand',
      payment_method: 'Cash on Hand',
    };
  }
}
