import { db } from '../../shared/drizzle.ts';
import { servicePricingRules } from '../../db/schema.ts';

export interface RatingPricingConfig {
  minimumRatingThreshold: number;
  highRatingBonusMultiplier: number;
  lowRatingSurgePenaltyMultiplier: number;
  baseSurgeCap: number;
}

export class PricingConfigService {
  private static readonly DEFAULT_RATING_CONFIG: RatingPricingConfig = {
    minimumRatingThreshold: 4.5,
    highRatingBonusMultiplier: 1.05,
    lowRatingSurgePenaltyMultiplier: 1.0,
    baseSurgeCap: 2.5,
  };

  private static readonly DEFAULT_PRICING_RULES = [
    { id: '1', serviceType: 'Solo Ride', baseFare: 20.0, perKmRate: 10.0, perMinuteRate: 1.5, minimumFare: 25.0, surgeMultiplier: 1.0, isActive: true },
    { id: '2', serviceType: 'Share-Bao', baseFare: 15.0, perKmRate: 7.0, perMinuteRate: 1.0, minimumFare: 20.0, surgeMultiplier: 1.0, isActive: true },
    { id: '3', serviceType: 'Bao Premium', baseFare: 35.0, perKmRate: 15.0, perMinuteRate: 2.0, minimumFare: 40.0, surgeMultiplier: 1.0, isActive: true },
  ];

  async getPricingConfigs() {
    try {
      const rules = await db.select().from(servicePricingRules);
      if (rules.length > 0) return rules;
      return PricingConfigService.DEFAULT_PRICING_RULES;
    } catch (_) {
      return PricingConfigService.DEFAULT_PRICING_RULES;
    }
  }

  async getRatingConfig(): Promise<RatingPricingConfig> {
    return PricingConfigService.DEFAULT_RATING_CONFIG;
  }
}
