<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import TablePagination from '@/app/components/TablePagination.vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

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
    lastMessage: 'Uploaded front photo of new municipal tricycle permit sticker.',
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
  const q = searchQuery.value.trim().toLowerCase()
  return tickets.value.filter((t) => {
    const matchesStatus = statusFilter.value === 'All' || t.status === statusFilter.value
    const matchesSearch =
      !q ||
      t.id.toLowerCase().includes(q) ||
      t.user.toLowerCase().includes(q) ||
      t.subject.toLowerCase().includes(q) ||
      t.category.toLowerCase().includes(q)
    return matchesStatus && matchesSearch
  })
})

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

    <div
      class="bg-white border border-neutral-200 p-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
    >
      <div>
        <h2 class="text-sm font-semibold text-neutral-900">Help Desk &amp; Support Inbox</h2>
        <p class="text-xs text-neutral-500 mt-0.5">
          Respond to Pagadian City passenger and taxicle driver inquiries, wallet escalations, and
          trip inquiries.
        </p>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search ticket ID, user, category, or subject..."
          class="w-full md:w-80 px-3 py-1.5 border border-neutral-300 rounded-none text-xs bg-white text-neutral-900 focus:outline-none focus:border-neutral-900"
        />

        <div class="flex flex-wrap items-center gap-2">
          <StatusBadge
            :label="`${tickets.filter((t) => t.status !== 'Resolved').length} Active Inquiries`"
            tone="neutral"
          />
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
              v-for="t in paginatedTickets"
              :key="t.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ t.id }}</div>
                <div class="text-[11px] text-neutral-400">{{ t.updatedAt }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ t.user }}</div>
                <div class="text-[11px] text-neutral-500 font-mono">
                  {{ t.role }} · {{ t.phone }}
                </div>
              </td>
              <td class="py-3 px-4 text-neutral-800 font-medium max-w-xs">{{ t.subject }}</td>
              <td class="py-3 px-4 text-neutral-600">{{ t.category }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="t.priority"
                  :tone="t.priority === 'High' ? 'danger' : 'neutral'"
                />
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="t.status"
                  :tone="
                    t.status === 'Resolved'
                      ? 'success'
                      : t.status === 'In Review'
                        ? 'warning'
                        : 'info'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold transition-colors"
                  @click="openTicketModal(t)"
                >
                  {{ t.status === 'Resolved' ? 'View Thread' : 'Inspect & Reply' }}
                </button>
              </td>
            </tr>
            <tr v-if="paginatedTickets.length === 0">
              <td colspan="7" class="py-10 px-4 text-center text-xs text-neutral-500">
                No support tickets match your active filters.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredTickets.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <Teleport to="body">
      <div
        v-if="inspectedTicket"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/60 p-4"
        @click.self="closeTicketModal"
      >
        <div
          role="dialog"
          aria-modal="true"
          class="w-full max-w-lg bg-white border border-neutral-200 rounded-none p-5 space-y-4 shadow-xl"
        >
          <div class="flex items-start justify-between border-b border-neutral-100 pb-3">
            <div>
              <h3 class="text-sm font-bold text-neutral-900">
                Support Ticket Thread · {{ inspectedTicket.id }}
              </h3>
              <p class="text-xs text-neutral-500 mt-0.5">
                {{ inspectedTicket.user }} ({{ inspectedTicket.role }}) ·
                {{ inspectedTicket.phone }}
              </p>
            </div>
            <StatusBadge
              :label="inspectedTicket.category"
              :tone="inspectedTicket.priority === 'High' ? 'danger' : 'neutral'"
            />
          </div>

          <div class="space-y-3 text-xs">
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

          <div class="flex items-center justify-end gap-2 border-t border-neutral-100 pt-3">
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
        </div>
      </div>
    </Teleport>
  </div>
</template>
