import { isIsoDateExpired } from '@/shared'

export function isDocumentExpired(expiryDate: string, referenceDate = new Date()): boolean {
  return isIsoDateExpired(expiryDate, referenceDate)
}
