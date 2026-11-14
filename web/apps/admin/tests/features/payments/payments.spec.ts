import { beforeEach, describe, expect, it } from 'vitest'
import { resetSettingsForTesting, useAuditLogs, usePlatformConfig } from '@/features/settings'
import {
  buildQrSvg,
  buildReceiptPreviewSvg,
  getPlatformFeeCentavos,
  getShortfallCentavos,
  resetPaymentsForTesting,
  useFarePricing,
  useSettlements,
  useTopups,
  useWalletAccounts,
  useWalletTransactions,
  validateQrUploadFile,
} from '@/features/payments'

describe('features/payments domain & stores', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetPaymentsForTesting()
  })

  it('escapes XML special characters inside SVG receipts and QR codes', () => {
    const receiptUrl = buildReceiptPreviewSvg({
      provider: 'GCash <Script>&"Test"',
      amountCentavos: 50000,
      reference: 'REF<&1>',
      recipient: 'EasyRide <Corp>',
      sender: 'Driver & Co',
      timestamp: '2026-11-14',
      accent: '#007dfe',
    })
    const decoded = decodeURIComponent(receiptUrl)
    expect(decoded).not.toContain('<Script>')
    expect(decoded).toContain('&lt;Script&gt;&amp;&quot;Test&quot;')
    expect(decoded).toContain('PHP 500.00')

    const qrUrl = buildQrSvg('QR<test>&1', '#171717')
    const decodedQr = decodeURIComponent(qrUrl)
    expect(decodedQr).not.toContain('<test>')
    expect(decodedQr).toContain('QR&lt;test&gt;&amp;1')
  })

  it('prevents double-crediting top-up requests and syncs ledger, wallet, and audit logs', () => {
    const { topUpRequests, getRequestById, verifyAndCredit, rejectRequest } = useTopups()
    const { transactions } = useWalletTransactions()
    const { wallets } = useWalletAccounts()
    const { logs } = useAuditLogs()

    const initialLogCount = logs.value.length
    const req = getRequestById('TOP-8921')!
    expect(req.amountCentavos).toBe(50000)

    const driverWalletBefore = wallets.value.find((w) => w.driver === 'Rodelio Cruz')!
    const startingBalance = driverWalletBefore.balanceCentavos

    expect(verifyAndCredit('TOP-8921')).toBe(true)
    expect(req.status).toBe('Verified')
    expect(req.currentBalanceCentavos).toBe(4250 + 50000)
    expect(driverWalletBefore.balanceCentavos).toBe(startingBalance + 50000)

    const ledgerEntry = transactions.value.find((t) => t.referenceId === 'TOP-8921')
    expect(ledgerEntry?.amountCentavos).toBe(50000)
    expect(ledgerEntry?.status).toBe('Settled')

    expect(logs.value).toHaveLength(initialLogCount + 1)
    expect(logs.value[0]?.action).toBe('WALLET_TOPUP_VERIFIED')

    expect(verifyAndCredit('TOP-8921')).toBe(false)
    expect(req.currentBalanceCentavos).toBe(4250 + 50000)
    expect(driverWalletBefore.balanceCentavos).toBe(startingBalance + 50000)

    expect(rejectRequest('TOP-8920', '   ')).toBe(false)
    expect(rejectRequest('TOP-8920', 'Unreadable deposit slip')).toBe(true)
    expect(getRequestById('TOP-8920')?.status).toBe('Rejected')

    resetPaymentsForTesting()
    expect(topUpRequests.value.find((r) => r.id === 'TOP-8921')?.status).toBe('Pending')
  })

  it('computes settlement fees and tip/change-aware cash shortfalls accurately', () => {
    const { reconcileSettlement, waiveShortfall, getSettlementById } = useSettlements()

    expect(
      getPlatformFeeCentavos({
        grossFareCentavos: 6000,
        commissionBps: 1500,
      }),
    ).toBe(900)

    expect(
      getShortfallCentavos({
        grossFareCentavos: 5500,
        tipCentavos: 1000,
        cashReceivedCentavos: 10000,
        cashChangeCentavos: 3500,
      }),
    ).toBe(0)

    expect(
      getShortfallCentavos({
        grossFareCentavos: 5500,
        tipCentavos: 1000,
        cashReceivedCentavos: 5000,
        cashChangeCentavos: 0,
      }),
    ).toBe(1500)

    expect(waiveShortfall('STL-9401', '   ')).toBe(false)
    expect(reconcileSettlement('STL-9401', 'Confirmed cash collection at TODA booth')).toBe(true)
    expect(getSettlementById('STL-9401')?.resolutionState).toBe('reconciled')
    expect(reconcileSettlement('STL-9401', 'Duplicate')).toBe(false)
  })

  it('persists validated tariff configuration rules with audit logs and validates QR uploads', () => {
    const { rules, saveFareRule } = useFarePricing()
    const { config } = usePlatformConfig()
    const { logs } = useAuditLogs()

    const standard = rules.value[0]!
    expect(standard.baseFareCentavos).toBe(config.value.baseFareCentavos)

    const invalid = saveFareRule({ ...standard, baseFareCentavos: 0 })
    expect(invalid.ok).toBe(false)

    const saved = saveFareRule({ ...standard, baseFareCentavos: 3000 })
    expect(saved.ok).toBe(true)
    expect(rules.value[0]?.baseFareCentavos).toBe(3000)
    expect(logs.value[0]?.action).toBe('TARIFF_MATRIX_UPDATED')

    expect(validateQrUploadFile({ name: 'qr.png', type: 'image/png', size: 1024 })).toBeNull()
    expect(
      validateQrUploadFile({ name: 'payload.exe', type: 'application/x-msdownload', size: 1024 }),
    ).toBeTruthy()
    expect(
      validateQrUploadFile({ name: 'huge.png', type: 'image/png', size: 5 * 1024 * 1024 }),
    ).toBeTruthy()
  })
})
