export const MINIMUM_TOPUP_CENTAVOS = 10_000;
export const MAXIMUM_CREDIT_BALANCE_CENTAVOS = 100_000;
export const DEFAULT_COMMISSION_BASIS_POINTS = 1_000;
export const LOW_BALANCE_WARNING_CENTAVOS = 5_000;

export type DriverErrorCode =
  | 'ACCOUNT_RESTRICTED'
  | 'DOCUMENT_REQUIREMENT_NOT_FOUND'
  | 'DRIVER_DOCUMENTS_INCOMPLETE'
  | 'DRIVER_NOT_APPROVED'
  | 'DRIVER_NOT_FOUND'
  | 'DUPLICATE_TOPUP_REFERENCE'
  | 'FORBIDDEN'
  | 'IDEMPOTENCY_KEY_REUSED'
  | 'INVALID_ACTOR'
  | 'INSUFFICIENT_CREDIT'
  | 'INVALID_CREDIT_AMOUNT'
  | 'INVALID_EXPIRY'
  | 'INVALID_IDEMPOTENCY_KEY'
  | 'DOCUMENT_REQUIREMENT_EXISTS'
  | 'MAX_CREDIT_BALANCE'
  | 'RESERVATION_STATE_CONFLICT'
  | 'RESTRICTION_NOT_FOUND'
  | 'TOPUP_ALREADY_REVIEWED'
  | 'TOPUP_CHANNEL_NOT_FOUND'
  | 'TOPUP_REQUEST_NOT_FOUND';

export class DriverDomainError extends Error {
  constructor(
    public readonly status: 400 | 401 | 403 | 404 | 409 | 422,
    public readonly code: DriverErrorCode,
    message: string,
  ) {
    super(message);
    this.name = 'DriverDomainError';
  }
}

export interface Page<T> {
  items: T[];
  page: number;
  limit: number;
  total: number;
}

export interface DriverEligibility {
  eligible: boolean;
  code: DriverErrorCode | null;
  message: string | null;
  availableBalanceCentavos: number;
  requiredCommissionCentavos: number;
}

export function calculateCommissionCentavos(
  fareCentavos: number,
  commissionBasisPoints = DEFAULT_COMMISSION_BASIS_POINTS,
): number {
  if (
    !Number.isSafeInteger(fareCentavos)
    || fareCentavos < 0
    || !Number.isInteger(commissionBasisPoints)
    || commissionBasisPoints < 0
    || commissionBasisPoints > 10_000
  ) {
    throw new DriverDomainError(
      422,
      'INVALID_CREDIT_AMOUNT',
      'Fare and commission must be valid integer values',
    );
  }

  return Math.round((fareCentavos * commissionBasisPoints) / 10_000);
}

export function normalizePaymentReference(reference: string): string {
  return reference.trim().replace(/\s+/g, '').toLowerCase();
}

export async function hashIdempotencyPayload(payload: unknown): Promise<string> {
  const bytes = new TextEncoder().encode(JSON.stringify(payload));
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}
