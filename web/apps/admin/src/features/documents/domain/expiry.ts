import { isIsoDateExpired } from '@/shared'

/**
 * Returns true if the document ISO expiry date is strictly before the reference UTC date.
 */
export function isDocumentExpired(expiryDate: string, referenceDate = new Date()): boolean {
  return isIsoDateExpired(expiryDate, referenceDate)
}
