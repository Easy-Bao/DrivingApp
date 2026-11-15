import { ref } from 'vue'
import { useAuditLogs } from '@/features/settings'
import {
  LOST_FOUND_DRIVER_ROSTER,
  SEED_FAQS,
  SEED_LOST_ITEMS,
  SEED_REVIEWS,
} from '@/features/support/data/support.seed'
import type {
  CreateLostFoundInput,
  FaqArticle,
  LostFoundRecord,
  ReviewEntry,
  SaveFaqInput,
  SupportActionResult,
} from '@/features/support/types'
import { useDrivers } from '@/features/users'

function cloneReviews(source: readonly ReviewEntry[]): ReviewEntry[] {
  return source.map((item) => ({ ...item, tags: [...item.tags] }))
}

function cloneLostItems(source: readonly LostFoundRecord[]): LostFoundRecord[] {
  return source.map((item) => ({ ...item }))
}

function cloneFaqs(source: readonly FaqArticle[]): FaqArticle[] {
  return source.map((item) => ({ ...item }))
}

const reviewsRef = ref<ReviewEntry[]>(cloneReviews(SEED_REVIEWS))
const lostItemsRef = ref<LostFoundRecord[]>(cloneLostItems(SEED_LOST_ITEMS))
const faqsRef = ref<FaqArticle[]>(cloneFaqs(SEED_FAQS))

let nextLostItemSeq = 803
let nextFaqSeq = SEED_FAQS.length + 1

export function resetSupportCommunityForTesting(): void {
  reviewsRef.value = cloneReviews(SEED_REVIEWS)
  lostItemsRef.value = cloneLostItems(SEED_LOST_ITEMS)
  faqsRef.value = cloneFaqs(SEED_FAQS)
  nextLostItemSeq = 803
  nextFaqSeq = SEED_FAQS.length + 1
}

export function useReviewModeration() {
  const { appendAuditLog } = useAuditLogs()

  function moderateReview(
    reviewId: string,
    action: 'hide' | 'approve',
    reason: string,
  ): SupportActionResult {
    const trimmedReason = reason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'A moderation rationale is required.' }
    }

    const target = reviewsRef.value.find((review) => review.id === reviewId)
    if (!target) {
      return { ok: false, error: `Review ${reviewId} not found.` }
    }

    target.moderationState = action === 'hide' ? 'Hidden by Moderator' : 'Published'
    target.moderationReason = trimmedReason

    appendAuditLog({
      action: 'REVIEW_MODERATED',
      targetEntity: target.id,
      severity: action === 'hide' ? 'Warning' : 'Info',
      payload: {
        tripId: target.tripId,
        moderationState: target.moderationState,
        reason: trimmedReason,
      },
    })

    return { ok: true }
  }

  return {
    reviews: reviewsRef,
    moderateReview,
  }
}

export function useLostAndFound() {
  const { appendAuditLog } = useAuditLogs()
  const { drivers } = useDrivers()

  function resolveDriverPhone(driverLabel: string): string {
    const rosterMatch = LOST_FOUND_DRIVER_ROSTER.find((entry) => entry.label === driverLabel)
    if (rosterMatch) return rosterMatch.phone

    const normalizedName = driverLabel.split('(')[0]?.trim().toLowerCase() ?? ''
    const liveMatch = drivers.value.find((driver) => driver.name.toLowerCase() === normalizedName)
    return liveMatch?.phone ?? '+63 917 482 1903'
  }

  function createLostItem(input: CreateLostFoundInput): SupportActionResult {
    const itemDescription = input.itemDescription.trim()
    const reportedBy = input.reportedBy.trim()
    const contactPhone = input.contactPhone.trim()
    const tripId = input.tripId.trim()
    const driver = input.driver.trim()

    if (!itemDescription || !reportedBy || !contactPhone) {
      return {
        ok: false,
        error: 'Provide item description, claimant name, and +63 phone number.',
      }
    }

    const id = `LF-7016-${nextLostItemSeq}`
    nextLostItemSeq += 1

    const driverPhone = resolveDriverPhone(driver)

    lostItemsRef.value.unshift({
      id,
      itemDescription,
      reportedBy,
      contactPhone,
      driver,
      driverPhone,
      tripId: tripId || 'TRP-UNSPECIFIED',
      corridor: 'Pagadian City Service Zone',
      status: 'Searching Driver',
    })

    appendAuditLog({
      action: 'LOST_ITEM_LOGGED',
      targetEntity: id,
      severity: 'Info',
      payload: { itemDescription, reportedBy, driver, driverPhone },
    })

    return { ok: true }
  }

  function confirmReturn(itemId: string, handoffNote: string): SupportActionResult {
    const trimmedNote = handoffNote.trim()
    if (!trimmedNote) {
      return { ok: false, error: 'Record claimant verification details before closing recovery.' }
    }

    const target = lostItemsRef.value.find((item) => item.id === itemId)
    if (!target) {
      return { ok: false, error: `Lost & Found case ${itemId} not found.` }
    }

    target.status = 'Returned to Owner'
    target.handoffNote = trimmedNote

    appendAuditLog({
      action: 'LOST_ITEM_RETURNED',
      targetEntity: target.id,
      severity: 'Info',
      payload: { tripId: target.tripId, handoffNote: trimmedNote },
    })

    return { ok: true }
  }

  return {
    lostItems: lostItemsRef,
    driverRosterOptions: LOST_FOUND_DRIVER_ROSTER.map((entry) => entry.label),
    createLostItem,
    confirmReturn,
  }
}

export function useFaqArticles() {
  const { appendAuditLog } = useAuditLogs()

  function saveFaq(input: SaveFaqInput): SupportActionResult {
    const question = input.question.trim()
    const answer = input.answer.trim()
    if (!question || !answer) {
      return { ok: false, error: 'Enter both a question heading and helpful answer text.' }
    }

    if (input.id) {
      const target = faqsRef.value.find((faq) => faq.id === input.id)
      if (!target) {
        return { ok: false, error: `FAQ article ${input.id} not found.` }
      }
      target.category = input.category
      target.audience = input.audience
      target.question = question
      target.answer = answer

      appendAuditLog({
        action: 'FAQ_UPDATED',
        targetEntity: target.id,
        severity: 'Info',
        payload: { category: input.category, audience: input.audience, question },
      })
      return { ok: true }
    }

    const nextId = `FAQ-${String(nextFaqSeq).padStart(2, '0')}`
    nextFaqSeq += 1

    faqsRef.value.unshift({
      id: nextId,
      category: input.category,
      audience: input.audience,
      question,
      answer,
      views: 0,
      isPublished: true,
    })

    appendAuditLog({
      action: 'FAQ_CREATED',
      targetEntity: nextId,
      severity: 'Info',
      payload: { category: input.category, audience: input.audience, question },
    })

    return { ok: true }
  }

  function togglePublished(faqId: string): SupportActionResult {
    const target = faqsRef.value.find((faq) => faq.id === faqId)
    if (!target) {
      return { ok: false, error: `FAQ article ${faqId} not found.` }
    }

    target.isPublished = !target.isPublished
    appendAuditLog({
      action: 'FAQ_VISIBILITY_TOGGLED',
      targetEntity: target.id,
      severity: 'Info',
      payload: { isPublished: target.isPublished },
    })
    return { ok: true }
  }

  return {
    faqs: faqsRef,
    saveFaq,
    togglePublished,
  }
}
