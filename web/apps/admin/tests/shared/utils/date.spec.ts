import { describe, expect, it } from 'vitest'
import { getDaysUntilIsoDate, isIsoDateExpired, parseIsoDateParts } from '@/shared/utils/date'

describe('date utilities', () => {
  const referenceNow = new Date('2026-11-13T10:00:00Z')

  it('parses valid ISO calendar dates and rejects malformed or impossible dates', () => {
    expect(parseIsoDateParts('2026-11-13')).toEqual({ year: 2026, month: 11, day: 13 })
    expect(parseIsoDateParts('2026-02-30')).toBeNull()
    expect(parseIsoDateParts('not-a-date')).toBeNull()
  })

  it('computes remaining days and detects past expiration accurately', () => {
    expect(getDaysUntilIsoDate('2026-11-13', referenceNow)).toBe(0)
    expect(getDaysUntilIsoDate('2026-11-18', referenceNow)).toBe(5)
    expect(getDaysUntilIsoDate('2026-10-14', referenceNow)).toBeLessThan(0)

    expect(isIsoDateExpired('2026-10-14', referenceNow)).toBe(true)
    expect(isIsoDateExpired('2026-11-13', referenceNow)).toBe(false)
    expect(isIsoDateExpired('2026-12-01', referenceNow)).toBe(false)
    expect(isIsoDateExpired('invalid', referenceNow)).toBe(false)
  })
})
