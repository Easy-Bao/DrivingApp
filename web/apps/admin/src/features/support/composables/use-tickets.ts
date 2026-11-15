import { computed, ref } from 'vue'
import { useAuditLogs } from '@/features/settings'
import { SEED_SUPPORT_TICKETS } from '@/features/support/data/support.seed'
import type {
  ReplyToTicketInput,
  SupportActionResult,
  SupportTicket,
} from '@/features/support/types'

function cloneTickets(source: readonly SupportTicket[]): SupportTicket[] {
  return source.map((ticket) => ({ ...ticket }))
}

const ticketsRef = ref<SupportTicket[]>(cloneTickets(SEED_SUPPORT_TICKETS))

export function resetTicketsForTesting(): void {
  ticketsRef.value = cloneTickets(SEED_SUPPORT_TICKETS)
}

export function useSupportTickets() {
  const { appendAuditLog } = useAuditLogs()

  const openTicketCount = computed(
    () => ticketsRef.value.filter((ticket) => ticket.status !== 'Resolved').length,
  )

  function replyToTicket(ticketId: string, input: ReplyToTicketInput): SupportActionResult {
    const trimmedReply = input.reply.trim()
    if (!trimmedReply) {
      return { ok: false, error: 'Enter an operator response before updating this ticket.' }
    }

    const target = ticketsRef.value.find((ticket) => ticket.id === ticketId)
    if (!target) {
      return { ok: false, error: `Ticket ${ticketId} not found.` }
    }

    target.operatorReply = trimmedReply
    target.status = input.status
    target.updatedAt = 'Just now'

    appendAuditLog({
      action: 'SUPPORT_TICKET_UPDATED',
      targetEntity: target.id,
      severity: 'Info',
      payload: { status: input.status, user: target.user, category: target.category },
    })

    return { ok: true }
  }

  return {
    tickets: ticketsRef,
    openTicketCount,
    replyToTicket,
  }
}
