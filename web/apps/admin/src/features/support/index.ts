import { resetSupportCommunityForTesting } from '@/features/support/composables/use-support-community'
import { resetTicketsForTesting } from '@/features/support/composables/use-tickets'

export type {
  CreateLostFoundInput,
  FaqArticle,
  FaqAudience,
  FaqCategory,
  LostFoundDriverOption,
  LostFoundRecord,
  LostFoundStatus,
  ReplyToTicketInput,
  ReviewDirection,
  ReviewEntry,
  ReviewModerationState,
  SaveFaqInput,
  SupportActionResult,
  SupportTicket,
  TicketCategory,
  TicketPriority,
  TicketRole,
  TicketStatus,
} from '@/features/support/types'

export { useSupportTickets } from '@/features/support/composables/use-tickets'
export {
  useFaqArticles,
  useLostAndFound,
  useReviewModeration,
} from '@/features/support/composables/use-support-community'

export function resetSupportForTesting(): void {
  resetTicketsForTesting()
  resetSupportCommunityForTesting()
}
