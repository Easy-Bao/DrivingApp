import { describe, expect, it, vi } from 'vitest'
import {
  buildCsvContent,
  escapeCsvCell,
  exportToCsv,
  formatBookingReference,
  formatBpsAsPercent,
  formatCentavos,
  formatPhp,
} from '@/shared/utils/format'

describe('format utilities', () => {
  it('formats PHP currency, booking references, and integer centavos cleanly', () => {
    expect(formatPhp(1250.5)).toBe('₱1,250.50')
    expect(formatCentavos(2500)).toBe('₱25.00')
    expect(formatCentavos(0)).toBe('₱0.00')
    expect(formatBpsAsPercent(1500)).toBe('15%')
    expect(formatBpsAsPercent(1250)).toBe('12.50%')
    expect(formatBookingReference('701629644618921')).toBe('7016…18921')
    expect(formatBookingReference('TRP-18921')).toBe('TRP-18921')
  })

  it('escapes quotes, commas, and spreadsheet formulas in CSV cells', () => {
    expect(escapeCsvCell('Pagadian, ZDS')).toBe('"Pagadian, ZDS"')
    expect(escapeCsvCell('Driver "Lito" Cruz')).toBe('"Driver ""Lito"" Cruz"')
    expect(escapeCsvCell('=CMD()')).toBe("'=CMD()")
    expect(escapeCsvCell('+SUM(A1:A2)')).toBe("'+SUM(A1:A2)")
    expect(escapeCsvCell(null)).toBe('')
  })

  it('builds CSV documents and triggers browser download safely', () => {
    const csv = buildCsvContent(['Booking Ref', 'Fare'], [['7016001', '₱45.00']])
    expect(csv).toBe('Booking Ref,Fare\r\n7016001,₱45.00')

    const createObjectUrl = vi.fn(() => 'blob:mock-url')
    const revokeObjectUrl = vi.fn()
    vi.stubGlobal('URL', {
      createObjectURL: createObjectUrl,
      revokeObjectURL: revokeObjectUrl,
    })

    const downloaded = exportToCsv('pagadian-trips', ['ID'], [['7016001']])
    expect(downloaded).toBe(true)
    expect(createObjectUrl).toHaveBeenCalledOnce()
    expect(revokeObjectUrl).toHaveBeenCalledWith('blob:mock-url')

    vi.unstubAllGlobals()
  })
})
