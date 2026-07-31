import { db } from '../../shared/drizzle.ts';
import { and, desc, eq, gte, lte } from 'drizzle-orm';
import { servicePricingRules, ratingPricingConfigs, fareTransactions } from '../../db/schema.ts';

export interface RatingPricingConfig {
  minimumRatingThreshold: number;
  highRatingBonusMultiplier: number;
  lowRatingSurgePenaltyMultiplier: number;
  baseSurgeCap: number;
}

export class PricingConfigService {
  async getPricingConfigs() {
    return await db.select().from(servicePricingRules);
  }

  async getActivePricingConfigs() {
    return await db.select()
      .from(servicePricingRules)
      .where(eq(servicePricingRules.isActive, true));
  }

  async getRatingConfig(): Promise<RatingPricingConfig> {
    const configs = await db.select().from(ratingPricingConfigs).limit(1);
    const config = configs[0];

    if (!config) {
      throw new Error('No rating pricing configuration found in database authority.');
    }

    return {
      minimumRatingThreshold: config.minimumRatingThreshold,
      highRatingBonusMultiplier: config.highRatingBonusMultiplier,
      lowRatingSurgePenaltyMultiplier: config.lowRatingSurgePenaltyMultiplier,
      baseSurgeCap: config.baseSurgeCap,
    };
  }

  async updatePricingConfig(serviceType: string, input: {
    baseFare: number;
    perKmRate: number;
    perMinuteRate: number;
    minimumFare: number;
    surgeMultiplier: number;
    isActive: boolean;
  }) {
    const [updated] = await db.update(servicePricingRules)
      .set({
        ...input,
        updatedAt: new Date(),
      })
      .where(eq(servicePricingRules.serviceType, serviceType))
      .returning();
    if (!updated) {
      throw new Error(`Pricing rule '${serviceType}' was not found.`);
    }
    return updated;
  }

  async getTransactions(input: {
    status?: string;
    from?: string;
    to?: string;
    page: number;
    limit: number;
  }) {
    const conditions = [
      input.status ? eq(fareTransactions.paymentStatus, input.status) : undefined,
      input.from ? gte(fareTransactions.createdAt, new Date(input.from)) : undefined,
      input.to ? lte(fareTransactions.createdAt, new Date(input.to)) : undefined,
    ].filter(Boolean);
    const limit = Math.min(10_000, Math.max(1, input.limit));
    return await db.select()
      .from(fareTransactions)
      .where(conditions.length > 0 ? and(...conditions as any[]) : undefined)
      .orderBy(desc(fareTransactions.createdAt))
      .limit(limit)
      .offset((Math.max(1, input.page) - 1) * limit);
  }
}
