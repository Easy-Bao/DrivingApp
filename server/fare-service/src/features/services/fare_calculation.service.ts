import { db } from '../../shared/drizzle.ts';
import { servicePricingRules, fareTransactions } from '../../db/schema.ts';
import { and, eq, inArray, type InferSelectModel } from 'drizzle-orm';
import { PricingConfigService } from './pricing_config.service.ts';
import { calculateCommissionCentavos } from './commission.ts';

type ServicePricingRule = InferSelectModel<typeof servicePricingRules>;

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

  private async getCommissionRateBasisPoints(): Promise<number> {
    const adminServiceUrl = process.env.ADMIN_SERVICE_URL;
    const internalToken = process.env.INTERNAL_SERVICE_TOKEN;
    if (!adminServiceUrl || !internalToken) return 1000;

    const response = await fetch(
      new URL('/admin/internal/pricing/commission', adminServiceUrl),
      { headers: { 'X-Internal-Service-Token': internalToken } },
    );
    if (!response.ok) {
      throw new Error('Failed to obtain the current commission policy.');
    }
    const body = await response.json() as { rate_basis_points?: number };
    return body.rate_basis_points ?? 1000;
  }

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
    const rules = await this.pricingConfigService.getActivePricingConfigs();

    if (!rules || rules.length === 0) {
      throw new Error('No active service pricing rules found in database authority.');
    }

    const estimates: ServiceEstimate[] = rules.map((rule: ServicePricingRule) => {
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
    driverId?: string,
  ): Promise<FinalFareResult> {
    const rules = await db
      .select()
      .from(servicePricingRules)
      .where(and(
        eq(servicePricingRules.serviceType, rideType),
        eq(servicePricingRules.isActive, true),
      ))
      .limit(1);

    const rule = rules[0];
    if (!rule) {
      throw new Error(`Pricing rule for service type '${rideType}' not found in database.`);
    }

    const baseFare = rule.baseFare ?? 20.0;
    const distanceCharge = distanceKm * (rule.perKmRate ?? 10.0);
    const timeCharge = durationMinutes * (rule.perMinuteRate ?? 1.5);
    const rawSubtotal = baseFare + distanceCharge + timeCharge;
    const surgeCharge = rawSubtotal * (surgeMultiplier - 1.0);
    const rawTotal = rawSubtotal + surgeCharge;
    const minimumFare = rule.minimumFare ?? 25.0;

    const totalFare = this.roundToHalfUnit(Math.max(rawTotal, minimumFare));
    const commissionRateBasisPoints = await this.getCommissionRateBasisPoints();
    const totalFareCentavos = Math.round(totalFare * 100);
    const platformFeeCentavos = calculateCommissionCentavos(
      totalFareCentavos,
      commissionRateBasisPoints,
    );
    const driverEarningsCentavos = totalFareCentavos - platformFeeCentavos;
    const driverEarnings = driverEarningsCentavos / 100;
    const platformFee = platformFeeCentavos / 100;

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
        driverId,
        totalFareCentavos,
        driverEarningsCentavos,
        platformFeeCentavos,
        commissionRateBasisPoints,
      });
    } catch (error) {
      console.error(`[FareCalculationService] Database write error for ride ${rideId}:`, error);
      throw new Error('Failed to record fare transaction into database.');
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

  /**
   * Persists the exact fare and commission selected when a ride is assigned.
   * A ride ID cannot later be reused with different monetary values.
   */
  async recordFareSnapshot(input: {
    rideId: string;
    driverId: string;
    serviceType: string;
    totalFareCentavos: number;
    commissionRateBasisPoints: number;
    commissionCentavos: number;
    assignmentSource: 'driver_offer' | 'admin';
  }) {
    const expectedCommissionCentavos = calculateCommissionCentavos(
      input.totalFareCentavos,
      input.commissionRateBasisPoints,
    );
    if (input.commissionCentavos !== expectedCommissionCentavos) {
      throw new Error('INVALID_COMMISSION_SNAPSHOT');
    }
    const driverEarningsCentavos = input.totalFareCentavos - input.commissionCentavos;
    const [created] = await db.insert(fareTransactions)
      .values({
        rideId: input.rideId,
        driverId: input.driverId,
        serviceType: input.serviceType,
        distanceKm: 0,
        durationMinutes: 0,
        baseFare: input.totalFareCentavos / 100,
        distanceCharge: 0,
        timeCharge: 0,
        surgeCharge: 0,
        totalFare: input.totalFareCentavos / 100,
        driverEarnings: driverEarningsCentavos / 100,
        platformFee: input.commissionCentavos / 100,
        totalFareCentavos: input.totalFareCentavos,
        driverEarningsCentavos,
        platformFeeCentavos: input.commissionCentavos,
        commissionRateBasisPoints: input.commissionRateBasisPoints,
        assignmentSource: input.assignmentSource,
      })
      .onConflictDoNothing({ target: fareTransactions.rideId })
      .returning();
    if (created) return created;

    const [existing] = await db.select()
      .from(fareTransactions)
      .where(eq(fareTransactions.rideId, input.rideId))
      .limit(1);
    if (
      !existing
      || existing.driverId !== input.driverId
      || existing.serviceType !== input.serviceType
      || existing.totalFareCentavos !== input.totalFareCentavos
      || existing.platformFeeCentavos !== input.commissionCentavos
      || existing.commissionRateBasisPoints !== input.commissionRateBasisPoints
      || existing.assignmentSource !== input.assignmentSource
    ) {
      throw new Error('IDEMPOTENCY_KEY_REUSED');
    }
    return existing;
  }

  async updatePaymentStatus(rideId: string, paymentStatus: string) {
    const allowedPreviousStatuses: Record<string, string[]> = {
      cash_pending: [],
      cash_received: ['cash_pending', 'cash_disputed'],
      cash_disputed: ['cash_pending'],
      canceled: ['cash_pending', 'cash_disputed'],
    };
    const allowedPrevious = allowedPreviousStatuses[paymentStatus];
    if (!allowedPrevious) throw new Error('INVALID_FARE_PAYMENT_STATUS');

    if (allowedPrevious.length > 0) {
      const [updated] = await db.update(fareTransactions)
        .set({ paymentStatus, updatedAt: new Date() })
        .where(and(
          eq(fareTransactions.rideId, rideId),
          inArray(fareTransactions.paymentStatus, allowedPrevious),
        ))
        .returning();
      if (updated) return updated;
    }

    const [existing] = await db.select()
      .from(fareTransactions)
      .where(eq(fareTransactions.rideId, rideId))
      .limit(1);
    if (!existing) throw new Error('FARE_SNAPSHOT_NOT_FOUND');
    if (existing.paymentStatus === paymentStatus) return existing;
    throw new Error('FARE_STATUS_CONFLICT');
  }
}
