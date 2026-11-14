import { ref, type Ref } from 'vue'
import { getAuthSession } from '@/core'
import { useAuditLogs } from '@/features/settings'
import {
  SEED_EXPIRING_DOCUMENTS,
  SEED_PENDING_DOCUMENTS,
  SEED_REJECTED_DOCUMENTS,
} from '@/features/documents/data/documents.seed'
import type {
  DocumentActionResult,
  ExpiringDocument,
  PendingDocument,
  RejectedDocument,
} from '@/features/documents/types'

function clonePending(source: readonly PendingDocument[]): PendingDocument[] {
  return source.map((item) => ({ ...item }))
}

function cloneExpiring(source: readonly ExpiringDocument[]): ExpiringDocument[] {
  return source.map((item) => ({ ...item }))
}

function cloneRejected(source: readonly RejectedDocument[]): RejectedDocument[] {
  return source.map((item) => ({ ...item }))
}

const pendingDocs: Ref<PendingDocument[]> = ref(clonePending(SEED_PENDING_DOCUMENTS))
const expiringDocs: Ref<ExpiringDocument[]> = ref(cloneExpiring(SEED_EXPIRING_DOCUMENTS))
const rejectedDocs: Ref<RejectedDocument[]> = ref(cloneRejected(SEED_REJECTED_DOCUMENTS))

/**
 * Resets all reactive document compliance queues to canonical seed state for tests.
 */
export function resetDocumentsForTesting(): void {
  pendingDocs.value = clonePending(SEED_PENDING_DOCUMENTS)
  expiringDocs.value = cloneExpiring(SEED_EXPIRING_DOCUMENTS)
  rejectedDocs.value = cloneRejected(SEED_REJECTED_DOCUMENTS)
}

/**
 * Manages the active driver compliance verification queue and cross-queue rejections.
 */
export function useVerificationDocuments() {
  const { appendAuditLog } = useAuditLogs()

  function verifyDocument(id: string): DocumentActionResult {
    const idx = pendingDocs.value.findIndex((item) => item.id === id)
    if (idx === -1) {
      return { ok: false, error: `Pending document ${id} was not found.` }
    }

    const doc = pendingDocs.value[idx]!
    if (doc.status !== 'Pending Review') {
      return { ok: false, error: `Document ${doc.id} has already been processed.` }
    }

    pendingDocs.value.splice(idx, 1)

    appendAuditLog({
      action: 'DOCUMENT_APPROVED',
      targetEntity: `${doc.id} · ${doc.driver}`,
      payload: { summary: `Verified "${doc.docType}" issued by ${doc.issuingAgency}.` },
      severity: 'Info',
    })

    return { ok: true, message: `${doc.id} approved for ${doc.driver}.` }
  }

  function rejectDocument(id: string, reason: string): DocumentActionResult {
    const trimmedReason = reason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'Rejection reason is required.' }
    }

    const idx = pendingDocs.value.findIndex((item) => item.id === id)
    if (idx === -1) {
      return { ok: false, error: `Pending document ${id} was not found.` }
    }

    const doc = pendingDocs.value[idx]!
    if (doc.status !== 'Pending Review') {
      return { ok: false, error: `Document ${doc.id} has already been processed.` }
    }

    pendingDocs.value.splice(idx, 1)
    const session = getAuthSession()

    const rejectedEntry: RejectedDocument = {
      id: doc.id,
      driver: doc.driver,
      driverPhone: doc.driverPhone,
      city: doc.city,
      docType: doc.docType,
      rejectionReason: trimmedReason,
      rejectedBy: session.operatorName || 'Operations Control Lead',
      rejectedAt: 'Just now',
      resubmitted: false,
    }
    rejectedDocs.value.unshift(rejectedEntry)

    appendAuditLog({
      action: 'DOCUMENT_REJECTED',
      targetEntity: `${doc.id} · ${doc.driver}`,
      payload: { docType: doc.docType, reason: trimmedReason },
      severity: 'Warning',
    })

    return { ok: true, message: `${doc.id} rejected (${trimmedReason}).` }
  }

  return {
    pendingDocs,
    verifyDocument,
    rejectDocument,
  }
}

/**
 * Manages expiring compliance documents and SMS reminder broadcasts.
 */
export function useExpiringDocuments() {
  const { appendAuditLog } = useAuditLogs()

  function sendUrgentReminder(id: string): DocumentActionResult {
    const target = expiringDocs.value.find((item) => item.id === id)
    if (!target) {
      return { ok: false, error: `Expiring document ${id} was not found.` }
    }

    target.reminded = true
    if (target.status === 'Action Required') {
      target.status = 'Notice Sent'
    }

    appendAuditLog({
      action: 'EXPIRY_REMINDER_SENT',
      targetEntity: `${target.id} · ${target.driver}`,
      payload: { docType: target.docType, expiryDate: target.expiryDate },
      severity: 'Info',
    })

    return { ok: true, message: `Renewal SMS sent to ${target.driver} (${target.driverPhone}).` }
  }

  function broadcastCriticalReminders(): { ok: true; count: number; message: string } {
    const eligible = expiringDocs.value.filter(
      (item) => (item.daysLeft <= 14 || item.status === 'Action Required') && !item.reminded,
    )
    for (const item of eligible) {
      item.reminded = true
      if (item.status === 'Action Required') {
        item.status = 'Notice Sent'
      }
    }

    appendAuditLog({
      action: 'EXPIRY_REMINDER_BROADCAST',
      targetEntity: `Critical Expiry Queue (${eligible.length} drivers)`,
      payload: { notifiedCount: eligible.length },
      severity: 'Info',
    })

    return {
      ok: true,
      count: eligible.length,
      message: `Renewal SMS sent to ${eligible.length} drivers.`,
    }
  }

  return {
    expiringDocs,
    sendUrgentReminder,
    broadcastCriticalReminders,
  }
}

/**
 * Manages previously rejected documents and re-opening items back into active review.
 */
export function useRejectedDocuments() {
  const { appendAuditLog } = useAuditLogs()

  function queueForReReview(id: string): DocumentActionResult {
    const idx = rejectedDocs.value.findIndex((item) => item.id === id)
    if (idx === -1) {
      return { ok: false, error: `Rejected document ${id} was not found.` }
    }

    const target = rejectedDocs.value[idx]!
    rejectedDocs.value.splice(idx, 1)

    const existingPending = pendingDocs.value.some((item) => item.id === target.id)
    if (!existingPending) {
      pendingDocs.value.unshift({
        id: target.id,
        driver: target.driver,
        driverPhone: target.driverPhone,
        city: target.city,
        docType: target.docType,
        issuingAgency: 'Re-submitted for Compliance Review',
        expiryDate: '2027-12-31',
        submittedAt: 'Re-opened now',
        docImageUrl: `${target.id.toLowerCase()}_resubmitted_scan.png`,
        status: 'Pending Review',
      })
    }

    appendAuditLog({
      action: 'DOCUMENT_REOPENED',
      targetEntity: `${target.id} · ${target.driver}`,
      payload: { docType: target.docType, status: 'Pending Review' },
      severity: 'Info',
    })

    return {
      ok: true,
      message: `${target.id} (${target.driver}) moved back to active verification queue.`,
    }
  }

  return {
    rejectedDocs,
    queueForReReview,
  }
}
