import { beforeEach, describe, expect, it } from 'vitest'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import {
  resetSupportForTesting,
  useFaqArticles,
  useLostAndFound,
  useReviewModeration,
  useSupportTickets,
} from '@/features/support'

describe('support feature stores', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetSupportForTesting()
  })

  it('tracks live open ticket count, rejects empty replies, and logs ticket updates', () => {
    const { tickets, openTicketCount, replyToTicket } = useSupportTickets()
    const { logs } = useAuditLogs()

    expect(openTicketCount.value).toBe(3)

    const rejected = replyToTicket('TCK-7016-204', { status: 'Resolved', reply: '   ' })
    expect(rejected.ok).toBe(false)
    expect(openTicketCount.value).toBe(3)

    const updated = replyToTicket('TCK-7016-204', {
      status: 'Resolved',
      reply: 'Approved deposit reference QR-8829104 and unlocked driver dispatch.',
    })
    expect(updated.ok).toBe(true)
    expect(openTicketCount.value).toBe(2)
    expect(tickets.value[0]!.status).toBe('Resolved')
    expect(logs.value[0]!.action).toBe('SUPPORT_TICKET_UPDATED')
  })

  it('moderates reviews only with mandatory rationale and records audit entries', () => {
    const { reviews, moderateReview } = useReviewModeration()
    const { logs } = useAuditLogs()

    const rejected = moderateReview('REV-7016-900', 'approve', '  ')
    expect(rejected.ok).toBe(false)

    const approved = moderateReview(
      'REV-7016-900',
      'approve',
      'Coaching session verified with Pagadian dispatch supervisor.',
    )
    expect(approved.ok).toBe(true)
    expect(reviews.value.find((r) => r.id === 'REV-7016-900')!.moderationState).toBe('Published')
    expect(logs.value[0]!.action).toBe('REVIEW_MODERATED')
  })

  it('binds lost-and-found reports to the selected driver phone and guards recovery closure', () => {
    const { lostItems, createLostItem, confirmReturn } = useLostAndFound()
    const { logs } = useAuditLogs()

    const badCreate = createLostItem({
      itemDescription: '',
      reportedBy: 'Maria Santos',
      contactPhone: '+63 917 000 1122',
      tripId: 'TRP-7016-8999',
      driver: 'Danilo Mendoza (ZDS-3019)',
    })
    expect(badCreate.ok).toBe(false)

    const created = createLostItem({
      itemDescription: 'Black powerbank in side pocket',
      reportedBy: 'Maria Santos',
      contactPhone: '+63 917 000 1122',
      tripId: 'TRP-7016-8999',
      driver: 'Danilo Mendoza (ZDS-3019)',
    })
    expect(created.ok).toBe(true)
    expect(lostItems.value[0]!.driverPhone).toBe('+63 918 654 2219')
    expect(logs.value[0]!.action).toBe('LOST_ITEM_LOGGED')

    const missingNote = confirmReturn(lostItems.value[0]!.id, ' ')
    expect(missingNote.ok).toBe(false)

    const returned = confirmReturn(lostItems.value[0]!.id, 'Claimed with valid student ID.')
    expect(returned.ok).toBe(true)
    expect(lostItems.value[0]!.status).toBe('Returned to Owner')
    expect(logs.value[0]!.action).toBe('LOST_ITEM_RETURNED')
  })

  it('creates, updates, and toggles FAQ articles with unique IDs and audit trails', () => {
    const { faqs, saveFaq, togglePublished } = useFaqArticles()
    const { logs } = useAuditLogs()

    const created = saveFaq({
      category: 'Safety & SOS',
      audience: 'Driver',
      question: 'How should drivers respond to SOS escalations?',
      answer: 'Stop safely at the nearest lighted curb and await Pagadian Emergency Desk contact.',
    })
    expect(created.ok).toBe(true)
    expect(faqs.value[0]!.id).toBe('FAQ-05')
    expect(logs.value[0]!.action).toBe('FAQ_CREATED')

    const edited = saveFaq({
      id: 'FAQ-05',
      category: 'Safety & SOS',
      audience: 'Driver',
      question: 'How should drivers respond during SOS activation?',
      answer: 'Pull over safely and keep dispatch line open for CDRRMO verification.',
    })
    expect(edited.ok).toBe(true)
    expect(faqs.value[0]!.question).toContain('SOS activation')
    expect(logs.value[0]!.action).toBe('FAQ_UPDATED')

    const toggled = togglePublished('FAQ-05')
    expect(toggled.ok).toBe(true)
    expect(faqs.value[0]!.isPublished).toBe(false)
    expect(logs.value[0]!.action).toBe('FAQ_VISIBILITY_TOGGLED')
  })
})
