import { db } from '../../shared/drizzle.ts';
import { servicePricingRules } from '../../db/schema.ts';

export interface RatingPricingConfig {
  minimumRatingThreshold: number;
  highRatingBonusMultiplier: number;
  lowRatingSurgePenaltyMultiplier: number;
  baseSurgeCap: number;
}

export class PricingConfigService {
  private static readonly RATING_CONFIG: RatingPricingConfig = {
    minimumRatingThreshold: 4.5,
    highRatingBonusMultiplier: 1.05,
    lowRatingSurgePenaltyMultiplier: 1.0,
    baseSurgeCap: 2.5,
  };

  async getPricingConfigs() {
    return await db.select().from(servicePricingRules);
  }

  async getRatingConfig(): Promise<RatingPricingConfig> {
    return PricingConfigService.RATING_CONFIG;
  }
}
