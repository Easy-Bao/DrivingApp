export interface IsoDateParts {
  readonly year: number
  readonly month: number
  readonly day: number
}

const ISO_DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/
const MS_PER_DAY = 86_400_000

export function parseIsoDateParts(isoDate: string): IsoDateParts | null {
  const match = ISO_DATE_RE.exec(isoDate.trim())
  if (!match) return null

  const year = Number(match[1])
  const month = Number(match[2])
  const day = Number(match[3])

  const utc = new Date(Date.UTC(year, month - 1, day))
  if (
    utc.getUTCFullYear() !== year ||
    utc.getUTCMonth() !== month - 1 ||
    utc.getUTCDate() !== day
  ) {
    return null
  }

  return { year, month, day }
}

export function getDaysUntilIsoDate(isoDate: string, now = new Date()): number | null {
  const parts = parseIsoDateParts(isoDate)
  if (!parts) return null

  const targetMidnightUtc = Date.UTC(parts.year, parts.month - 1, parts.day)
  const todayMidnightUtc = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())
  return Math.round((targetMidnightUtc - todayMidnightUtc) / MS_PER_DAY)
}

export function isIsoDateExpired(isoDate: string, now = new Date()): boolean {
  const daysRemaining = getDaysUntilIsoDate(isoDate, now)
  return daysRemaining !== null && daysRemaining < 0
}
