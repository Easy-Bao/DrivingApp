import { beforeEach, describe, expect, it, vi } from 'vitest'
import { loginOperator } from '@/core'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import {
  buildDocumentPreviewSvg,
  escapeXml,
  isDocumentExpired,
  resetDocumentsForTesting,
  useExpiringDocuments,
  useRejectedDocuments,
  useVerificationDocuments,
} from '@/features/documents'

describe('features/documents domain & composables', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetDocumentsForTesting()
  })

  it('escapes XML special characters before building SVG document preview data URIs', () => {
    const escaped = escapeXml(`<script>"Alert" & 'Quote'</script>`)
    expect(escaped).toBe('&lt;script&gt;&quot;Alert&quot; &amp; &apos;Quote&apos;&lt;/script&gt;')

    const dataUri = buildDocumentPreviewSvg({
      docId: 'DOC-901<x>',
      title: 'LTO & MTOP',
      holder: 'Rodelio "Del" Cruz',
      authority: "Pagadian <City> 'Board'",
      plateOrRef: '1284-ND',
      side: 'Front',
    })

    expect(dataUri.startsWith('data:image/svg+xml;charset=utf-8,')).toBe(true)
    const decoded = decodeURIComponent(dataUri.slice('data:image/svg+xml;charset=utf-8,'.length))
    expect(decoded).not.toContain('<x>')
    expect(decoded).toContain('&lt;x&gt;')
    expect(decoded).toContain('LTO &amp; MTOP')
    expect(decoded).toContain('Rodelio &quot;Del&quot; Cruz')
    expect(decoded).toContain('Pagadian &lt;City&gt; &apos;Board&apos;')
  })

  it('evaluates document expiration accurately against reference clock', () => {
    const refDate = new Date('2026-11-13T10:00:00Z')
    expect(isDocumentExpired('2026-10-14', refDate)).toBe(true)
    expect(isDocumentExpired('2026-11-12', refDate)).toBe(true)
    expect(isDocumentExpired('2026-11-13', refDate)).toBe(false)
    expect(isDocumentExpired('2026-11-14', refDate)).toBe(false)
    expect(isDocumentExpired('2028-05-19', refDate)).toBe(false)
  })

  it('enforces state guards, updates rejected queue on rejection, and logs audit events', () => {
    loginOperator('fleet', '7016')
    const { pendingDocs, verifyDocument, rejectDocument } = useVerificationDocuments()
    const { rejectedDocs } = useRejectedDocuments()
    const { logs } = useAuditLogs()

    const initialPending = pendingDocs.value.length
    const initialRejected = rejectedDocs.value.length
    const initialLogs = logs.value.length

    const approveResult = verifyDocument('DOC-901')
    expect(approveResult.ok).toBe(true)
    expect(pendingDocs.value).toHaveLength(initialPending - 1)
    expect(logs.value).toHaveLength(initialLogs + 1)
    expect(logs.value[0]?.action).toBe('DOCUMENT_APPROVED')
    expect(logs.value[0]?.actor).toBe('Ramon Villanueva')

    const duplicateApprove = verifyDocument('DOC-901')
    expect(duplicateApprove.ok).toBe(false)

    const blankReject = rejectDocument('DOC-902', '   ')
    expect(blankReject.ok).toBe(false)

    const rejectResult = rejectDocument('DOC-902', 'Image blurred or unreadable official seal')
    expect(rejectResult.ok).toBe(true)
    expect(pendingDocs.value.some((d) => d.id === 'DOC-902')).toBe(false)
    expect(rejectedDocs.value).toHaveLength(initialRejected + 1)
    expect(rejectedDocs.value[0]?.rejectionReason).toBe('Image blurred or unreadable official seal')
    expect(rejectedDocs.value[0]?.resubmitted).toBe(false)
    expect(logs.value[0]?.action).toBe('DOCUMENT_REJECTED')
  })

  it('moves reopened rejected documents back into the active verification queue with audit trail', () => {
    const { pendingDocs } = useVerificationDocuments()
    const { rejectedDocs, queueForReReview } = useRejectedDocuments()
    const { logs } = useAuditLogs()

    const targetId = rejectedDocs.value[0]!.id
    const pendingBefore = pendingDocs.value.length
    const rejectedBefore = rejectedDocs.value.length

    const result = queueForReReview(targetId)
    expect(result.ok).toBe(true)
    expect(rejectedDocs.value).toHaveLength(rejectedBefore - 1)
    expect(pendingDocs.value).toHaveLength(pendingBefore + 1)
    expect(pendingDocs.value[0]?.id).toBe(targetId)
    expect(logs.value[0]?.action).toBe('DOCUMENT_REOPENED')

    const secondAttempt = queueForReReview(targetId)
    expect(secondAttempt.ok).toBe(false)
  })

  it('tracks SMS renewal reminders and critical broadcasts with audit logs', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-11-13T10:00:00Z'))
    const { expiringDocs, sendUrgentReminder, broadcastCriticalReminders } = useExpiringDocuments()
    const { logs } = useAuditLogs()

    const firstId = expiringDocs.value[0]!.id
    const singleResult = sendUrgentReminder(firstId)
    expect(singleResult.ok).toBe(true)
    expect(expiringDocs.value.find((item) => item.id === firstId)?.reminded).toBe(true)
    expect(logs.value[0]?.action).toBe('EXPIRY_REMINDER_SENT')

    const broadcastResult = broadcastCriticalReminders()
    expect(broadcastResult.count).toBeGreaterThanOrEqual(0)
    expect(logs.value[0]?.action).toBe('EXPIRY_REMINDER_BROADCAST')
  })

  it('resets all document queues cleanly for isolated tests', () => {
    const { pendingDocs, verifyDocument } = useVerificationDocuments()
    const baseline = pendingDocs.value.length

    verifyDocument('DOC-901')
    expect(pendingDocs.value).toHaveLength(baseline - 1)

    resetDocumentsForTesting()
    expect(pendingDocs.value).toHaveLength(baseline)
  })
})
