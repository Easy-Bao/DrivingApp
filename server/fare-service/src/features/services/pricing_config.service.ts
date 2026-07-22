import { db } from '../../shared/drizzle.ts';
import { servicePricingRules, ratingPricingConfigs } from '../../db/schema.ts';

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
}
