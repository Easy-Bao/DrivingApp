import type {
  CreateCommissionTierInput,
  CreateCompanyAccountInput,
  CreateFareTierRuleInput,
  FareTierRule,
  SaveCommissionTierInput,
  UpdateCompanyAccountInput,
} from '@/features/payments/types'

const ALLOWED_QR_MIME_TYPES = new Set(['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml'])

export const MAX_QR_FILE_BYTES = 2 * 1024 * 1024

export function validateQrUploadFile(file: {
  name: string
  type: string
  size: number
}): string | null {
  if (!ALLOWED_QR_MIME_TYPES.has(file.type)) {
    return 'Upload a valid PNG, JPEG, WebP, or SVG QR image.'
  }
  if (!Number.isFinite(file.size) || file.size <= 0 || file.size > MAX_QR_FILE_BYTES) {
    return 'QR image size must be non-empty and under 2 MB.'
  }
  return null
}

export function validateCommissionTierInput(
  input: SaveCommissionTierInput | CreateCommissionTierInput,
): string | null {
  if ('category' in input && !input.category.trim()) {
    return 'Provide a commission tier title.'
  }
  if (!Number.isFinite(input.rateBps) || input.rateBps < 100 || input.rateBps > 3500) {
    return 'Commission rate must stay between 100 bps (1.0%) and 3500 bps (35.0%).'
  }
  if (
    !Number.isFinite(input.minWalletBalanceCentavos) ||
    input.minWalletBalanceCentavos < 0 ||
    !Number.isFinite(input.fixedBookingFeeCentavos) ||
    input.fixedBookingFeeCentavos < 0
  ) {
    return 'Fee and wallet threshold values cannot be negative.'
  }
  return null
}

export function validateFareRuleInput(
  rule: FareTierRule | CreateFareTierRuleInput,
  maxSurgeCeiling = 2.5,
): string | null {
  const ceiling = Number.isFinite(maxSurgeCeiling) ? Math.max(1, maxSurgeCeiling) : 2.5
  if (!rule.tier.trim() || !rule.corridorScope.trim()) {
    return 'Provide both a tariff tier name and corridor scope.'
  }
  if (
    !Number.isFinite(rule.baseFareCentavos) ||
    rule.baseFareCentavos <= 0 ||
    !Number.isFinite(rule.perKmCentavos) ||
    rule.perKmCentavos <= 0 ||
    !Number.isFinite(rule.perMinuteCentavos) ||
    rule.perMinuteCentavos < 0 ||
    !Number.isFinite(rule.minimumFareCentavos) ||
    rule.minimumFareCentavos <= 0 ||
    !Number.isFinite(rule.cancellationFeeCentavos) ||
    rule.cancellationFeeCentavos < 0 ||
    !Number.isFinite(rule.maxBiddingSurgeCap) ||
    rule.maxBiddingSurgeCap < 1 ||
    rule.maxBiddingSurgeCap > ceiling ||
    !Number.isFinite(rule.highRatingDriverBonus) ||
    rule.highRatingDriverBonus < 1 ||
    rule.highRatingDriverBonus > 1.2
  ) {
    return `Verify PHP tariff rates are positive, VIP rating bonus is 1.0x–1.2x, and bidding surge cap remains within 1.0x–${ceiling.toFixed(1)}x.`
  }
  return null
}

export function validateCompanyAccountInput(
  input: CreateCompanyAccountInput | UpdateCompanyAccountInput,
): string | null {
  if (
    !input.label.trim() ||
    !input.institution.trim() ||
    !input.accountNumber.trim() ||
    !input.accountHolder.trim()
  ) {
    return 'Fill in account label, institution, account number, and holder name.'
  }
  return null
}

export function validateMerchantReference(reference: string): string | null {
  if (!reference.trim()) {
    return 'QRPh Merchant Reference is required.'
  }
  return null
}

export function validateWalletAdjustment(amountCentavos: number, reason: string): string | null {
  if (!Number.isFinite(amountCentavos) || amountCentavos <= 0) {
    return 'Adjustment amount must be greater than zero.'
  }
  if (!reason.trim()) {
    return 'Provide a mandatory ledger audit note before applying adjustment.'
  }
  return null
}
