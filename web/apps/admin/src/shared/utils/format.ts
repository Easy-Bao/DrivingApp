const FORMULA_PREFIX_RE = /^[=+\-@\t\r]/
const XML_ESCAPE_MAP: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&apos;',
}

export function escapeXml(value: string): string {
  return value.replace(/[&<>"']/g, (ch) => XML_ESCAPE_MAP[ch] ?? ch)
}

export function formatPhp(amount: number): string {
  const safe = Number.isFinite(amount) ? amount : 0
  return `₱${safe.toLocaleString('en-PH', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`
}

export function formatBookingReference(id: string): string {
  const trimmed = id.trim()
  if (trimmed.length <= 11) return trimmed
  return `${trimmed.slice(0, 4)}…${trimmed.slice(-5)}`
}

export function formatCentavos(centavos: number): string {
  if (!Number.isFinite(centavos)) return formatPhp(0)
  return formatPhp(centavos / 100)
}

export function formatBpsAsPercent(bps: number): string {
  if (!Number.isFinite(bps)) return '0%'
  const percent = bps / 100
  return Number.isInteger(percent) ? `${percent}%` : `${percent.toFixed(2)}%`
}

export function escapeCsvCell(value: string | number | boolean | null | undefined): string {
  const raw = value === null || value === undefined ? '' : String(value)
  const neutralized = FORMULA_PREFIX_RE.test(raw) ? `'${raw}` : raw
  if (/[",\r\n]/.test(neutralized)) {
    return `"${neutralized.replace(/"/g, '""')}"`
  }
  return neutralized
}

export function buildCsvContent(
  headers: readonly string[],
  rows: readonly (readonly (string | number | boolean | null | undefined)[])[],
): string {
  const headerLine = headers.map((header) => escapeCsvCell(header)).join(',')
  const bodyLines = rows.map((row) => row.map((cell) => escapeCsvCell(cell)).join(','))
  return [headerLine, ...bodyLines].join('\r\n')
}

export function exportToCsv(
  filename: string,
  headers: readonly string[],
  rows: readonly (readonly (string | number | boolean | null | undefined)[])[],
): boolean {
  const csv = buildCsvContent(headers, rows)
  if (typeof document === 'undefined' || typeof URL.createObjectURL !== 'function') {
    return false
  }

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const objectUrl = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = objectUrl
  link.download = filename.endsWith('.csv') ? filename : `${filename}.csv`
  link.style.display = 'none'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(objectUrl)
  return true
}
