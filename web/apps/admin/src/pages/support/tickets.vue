<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import TablePagination from '@/shared/table/TablePagination.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'

interface SupportTicket {
  id: string
  user: string
  phone: string
  role: 'Passenger' | 'Driver'
  subject: string
  category: 'QRPh Top-Up' | 'Fare Dispute' | 'App Account' | 'Safety Escalation'
  priority: 'High' | 'Normal'
  status: 'Open' | 'In Review' | 'Resolved'
  lastMessage: string
  operatorReply?: string
  updatedAt: string
}

const tickets = ref<SupportTicket[]>([
  {
    id: 'TCK-7016-204',
    user: 'Rodelio Cruz',
    phone: '+63 917 482 1903',
    role: 'Driver',
    subject: 'Uploaded GCash QRPh receipt for ₱200 awaiting dispatch unlock',
    category: 'QRPh Top-Up',
    priority: 'High',
    status: 'Open',
    lastMessage: 'Submitted screenshot QR-8829104 12 minutes ago; wallet balance is ₱18.50.',
    updatedAt: '12 mins ago',
  },
  {
    id: 'TCK-7016-203',
    user: 'Kristine Joy Navarro',
    phone: '+63 918 220 3944',
    role: 'Passenger',
    subject: 'Cancellation fee charged during rainy delay at Agora Market',
    category: 'Fare Dispute',
    priority: 'Normal',
    status: 'In Review',
    lastMessage: 'Driver could not enter flooded side street near stall row B.',
    operatorReply: 'Checking dispatch telemetry timestamps before waiving ₱15.00 fee.',
    updatedAt: '48 mins ago',
  },
  {
    id: 'TCK-7016-202',
    user: 'Danilo Mendoza',
    phone: '+63 918 654 2219',
    role: 'Driver',
    subject: 'Renewed Pagadian TODA MTOP permit ready for review',
    category: 'App Account',
    priority: 'Normal',
    status: 'Open',
    lastMessage: 'Uploaded front photo of new municipal permit sticker.',
    updatedAt: '2 hours ago',
  },
  {
    id: 'TCK-7016-201',
    user: 'Althea Mae Villanueva',
    phone: '+63 917 842 9103',
    role: 'Passenger',
    subject: 'Receipt confirmation for morning bid trip TRP-7016-8921',
    category: 'Fare Dispute',
    priority: 'Normal',
    status: 'Resolved',
    lastMessage: 'Needed digital trip summary for school reimbursement.',
    operatorReply: 'Sent verified PHP trip receipt to passenger registered email.',
    updatedAt: 'Yesterday',
  },
])

const searchQuery = ref('')
const statusFilter = ref<'All' | SupportTicket['status']>('All')
const currentPage = ref(1)
const itemsPerPage = 8

const inspectedTicket = ref<SupportTicket | null>(null)
const draftStatus = ref<SupportTicket['status']>('Resolved')
const draftReply = ref('')
const modalError = ref<string | null>(null)
const toastMessage = ref<string | null>(null)

const filteredTickets = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return tickets.value.filter((ticket) => {
    const matchesStatus = statusFilter.value === 'All' || ticket.status === statusFilter.value
    const matchesSearch =
      !query ||
      ticket.id.toLowerCase().includes(query) ||
      ticket.user.toLowerCase().includes(query) ||
      ticket.subject.toLowerCase().includes(query) ||
      ticket.category.toLowerCase().includes(query)
    return matchesStatus && matchesSearch
  })
})

const activeInquiryCount = computed(
  () => tickets.value.filter((ticket) => ticket.status !== 'Resolved').length,
)

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || statusFilter.value !== 'All',
)

const resetFilters = () => {
  searchQuery.value = ''
  statusFilter.value = 'All'
}

watch([searchQuery, statusFilter], () => {
  currentPage.value = 1
})

const paginatedTickets = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredTickets.value.slice(start, start + itemsPerPage)
})

const openTicketModal = (ticket: SupportTicket) => {
  inspectedTicket.value = ticket
  draftStatus.value = ticket.status === 'Open' ? 'Resolved' : ticket.status
  draftReply.value = ticket.operatorReply ?? ''
  modalError.value = null
}

const closeTicketModal = () => {
  inspectedTicket.value = null
  modalError.value = null
}

const submitReply = () => {
  if (!inspectedTicket.value) return
  if (!draftReply.value.trim()) {
    modalError.value = 'Enter an operator response before updating this ticket.'
    return
  }
  inspectedTicket.value.operatorReply = draftReply.value.trim()
  inspectedTicket.value.status = draftStatus.value
  inspectedTicket.value.updatedAt = 'Just now'
  toastMessage.value = `${inspectedTicket.value.id} updated (${draftStatus.value}) with operator reply.`
  closeTicketModal()
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner
      v-if="toastMessage"
      :message="toastMessage"
      tone="success"
      @dismiss="toastMessage = null"
    />

    <PageHeader
      title="Tickets"
      description="Respond to passenger and driver inquiries and account escalations."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search ticket ID, user, category, or subject..."
          aria-label="Search support tickets"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
          <StatusBadge :label="`${activeInquiryCount} Active Inquiries`" tone="neutral" />
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter by ticket status"
            :options="[
              { label: 'All Ticket Statuses', value: 'All' },
              { label: 'Open', value: 'Open' },
              { label: 'In Review', value: 'In Review' },
              { label: 'Resolved', value: 'Resolved' },
            ]"
          />
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[820px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Ticket ID</th>
              <th class="py-3 px-4">Reporter</th>
              <th class="py-3 px-4">Subject</th>
              <th class="py-3 px-4">Category</th>
              <th class="py-3 px-4">Priority</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="ticket in paginatedTickets"
              :key="ticket.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ ticket.id }}</div>
                <div class="text-[11px] text-neutral-400">{{ ticket.updatedAt }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ ticket.user }}</div>
                <div class="text-[11px] text-neutral-500 font-mono">
                  {{ ticket.role }} · {{ ticket.phone }}
                </div>
              </td>
              <td class="py-3 px-4 text-neutral-800 font-medium max-w-xs">{{ ticket.subject }}</td>
              <td class="py-3 px-4 text-neutral-600">{{ ticket.category }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="ticket.priority"
                  :tone="ticket.priority === 'High' ? 'danger' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="ticket.status"
                  :tone="
                    ticket.status === 'Resolved'
                      ? 'success'
                      : ticket.status === 'In Review'
                        ? 'warning'
                        : 'info'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold transition-colors"
                  @click="openTicketModal(ticket)"
                >
                  {{ ticket.status === 'Resolved' ? 'View Thread' : 'Inspect & Reply' }}
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedTickets.length === 0"
              :colspan="7"
              title="No matching support tickets"
              description="No support tickets match your active filters."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredTickets.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="Boolean(inspectedTicket)"
      :title="inspectedTicket ? `Support Ticket Thread · ${inspectedTicket.id}` : ''"
      :subtitle="
        inspectedTicket
          ? `${inspectedTicket.user} (${inspectedTicket.role}) · ${inspectedTicket.phone}`
          : ''
      "
      size="lg"
      @update:open="(open) => !open && closeTicketModal()"
    >
      <template #header-meta>
        <StatusBadge
          v-if="inspectedTicket"
          :label="inspectedTicket.category"
          :tone="inspectedTicket.priority === 'High' ? 'danger' : 'neutral'"
        />
      </template>

      <div v-if="inspectedTicket" class="space-y-3 text-xs">
        <div class="bg-neutral-50 border border-neutral-200 p-3">
          <div class="font-semibold text-neutral-900">{{ inspectedTicket.subject }}</div>
          <p class="text-neutral-600 mt-1">{{ inspectedTicket.lastMessage }}</p>
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Next Ticket Status</label>
          <BaseSelect
            v-model="draftStatus"
            :full-width="true"
            aria-label="Updated ticket status"
            :options="['Open', 'In Review', 'Resolved']"
          />
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">
            Operator Reply &amp; Resolution Message
          </label>
          <textarea
            v-model="draftReply"
            rows="3"
            placeholder="Write a clear response sent to the driver or passenger..."
            class="w-full px-3 py-2 border border-neutral-300 rounded-none text-xs bg-white text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>

        <p v-if="modalError" class="text-xs font-medium text-rose-700">{{ modalError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
            @click="closeTicketModal"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
            @click="submitReply"
          >
            Send Reply &amp; Save
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
