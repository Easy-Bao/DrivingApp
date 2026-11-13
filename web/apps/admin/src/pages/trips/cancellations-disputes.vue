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
import { formatPhp } from '@/shared/utils/format'

type CancellationResponsibility =
  | 'passenger_fault'
  | 'driver_fault'
  | 'system_fault'
  | 'no_fault'
  | 'safety_related'
  | 'pending_review'
  | 'operator_override'

interface CancellationCase {
  id: string
  tripId: string
  cancelledBy: string
  route: string
  reason: string
  responsibility: CancellationResponsibility
  cancellationFee: number
  feeChargedTo: string
  disputeStatus: 'Under Review' | 'Resolved (Fee Upheld)' | 'Fee Waived & Overridden' | 'Closed'
  timestamp: string
}

const cancellations = ref<CancellationCase[]>([
  {
    id: 'CAN-7016-301',
    tripId: 'TRP-7016-8917',
    cancelledBy: 'Passenger (Kristine Joy Navarro)',
    route: 'Brgy. Santa Lucia -> Pagadian Rotunda',
    reason: 'Driver delayed at Agora traffic junction beyond 6 mins',
    responsibility: 'pending_review',
    cancellationFee: 15.0,
    feeChargedTo: 'Passenger',
    disputeStatus: 'Under Review',
    timestamp: '2 hours ago',
  },
  {
    id: 'CAN-7016-302',
    tripId: 'TRP-7016-8894',
    cancelledBy: 'Driver (Javier Santos · 5519-NB)',
    route: 'Pagadian Pier Port -> Brgy. Gatas',
    reason: 'Passenger did not appear at pickup point after 5-min timer',
    responsibility: 'passenger_fault',
    cancellationFee: 15.0,
    feeChargedTo: 'Passenger (Credited Driver)',
    disputeStatus: 'Resolved (Fee Upheld)',
    timestamp: '5 hours ago',
  },
  {
    id: 'CAN-7016-303',
    tripId: 'TRP-7016-8871',
    cancelledBy: 'System Timeout',
    route: 'Brgy. Tuburan -> ZDS Medical Center',
    reason: 'No bidding acceptance within 90-second dispatch window',
    responsibility: 'system_fault',
    cancellationFee: 0.0,
    feeChargedTo: 'None (System Waived)',
    disputeStatus: 'Closed',
    timestamp: 'Yesterday',
  },
])

const searchQuery = ref('')
const statusFilter = ref<'ALL' | 'Under Review' | 'RESOLVED'>('ALL')
const currentPage = ref(1)
const itemsPerPage = 10
const toastMessage = ref<string | null>(null)

const reviewingCase = ref<CancellationCase | null>(null)
const overrideResponsibility = ref<CancellationResponsibility>('operator_override')
const shouldWaiveFee = ref(true)
const auditNote = ref('')

const responsibilityLabels: Record<CancellationResponsibility, string> = {
  passenger_fault: 'Passenger Fault',
  driver_fault: 'Driver Fault',
  system_fault: 'System Fault',
  no_fault: 'No Fault (Mutual)',
  safety_related: 'Safety Related',
  pending_review: 'Pending Review',
  operator_override: 'Operator Override',
}

const filteredCases = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return cancellations.value.filter((item) => {
    if (statusFilter.value === 'Under Review' && item.disputeStatus !== 'Under Review') {
      return false
    }
    if (statusFilter.value === 'RESOLVED' && item.disputeStatus === 'Under Review') {
      return false
    }
    if (!query) return true
    return (
      item.id.toLowerCase().includes(query) ||
      item.tripId.toLowerCase().includes(query) ||
      item.cancelledBy.toLowerCase().includes(query) ||
      item.route.toLowerCase().includes(query)
    )
  })
})

watch([searchQuery, statusFilter], () => {
  currentPage.value = 1
})

const hasActiveFilters = computed(() => searchQuery.value !== '' || statusFilter.value !== 'ALL')

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'ALL'
  currentPage.value = 1
}

const paginatedCases = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredCases.value.slice(start, start + itemsPerPage)
})

const openResolutionModal = (item: CancellationCase) => {
  reviewingCase.value = item
  overrideResponsibility.value =
    item.responsibility === 'pending_review' ? 'no_fault' : item.responsibility
  shouldWaiveFee.value = true
  auditNote.value = ''
}

const applyResolution = () => {
  const target = reviewingCase.value
  if (!target || !auditNote.value.trim()) return

  target.responsibility = overrideResponsibility.value
  if (shouldWaiveFee.value) {
    target.cancellationFee = 0
    target.feeChargedTo = `Waived (${auditNote.value.trim()})`
    target.disputeStatus = 'Fee Waived & Overridden'
  } else {
    target.disputeStatus = 'Resolved (Fee Upheld)'
  }

  toastMessage.value = `${target.tripId} responsibility set to ${responsibilityLabels[target.responsibility]}.`
  reviewingCase.value = null
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Disputes"
      description="Review ride cancellations, fault responsibility, and penalty fees."
    />

    <ToastBanner :message="toastMessage" tone="success" @dismiss="toastMessage = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="w-full sm:w-64">
            <SearchField
              v-model="searchQuery"
              placeholder="Search trip ID, initiated by, route..."
              aria-label="Search cancellations and disputes"
            />
          </div>
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter disputes by status"
            :options="[
              { label: 'All Disputes', value: 'ALL' },
              { label: 'Under Review', value: 'Under Review' },
              { label: 'Resolved Cases', value: 'RESOLVED' },
            ]"
          />
        </div>
        <span
          class="px-2.5 py-1 bg-neutral-50 border border-neutral-300 text-[11px] font-semibold text-neutral-800 tabular-nums self-start sm:self-auto"
        >
          Rate: 3.6% · 2m grace
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[880px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Dispute / Trip</th>
              <th class="py-3 px-4">Initiated By</th>
              <th class="py-3 px-4">Reason &amp; Route</th>
              <th class="py-3 px-4">Responsibility</th>
              <th class="py-3 px-4">Fee Policy</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="dispute in paginatedCases"
              :key="dispute.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono">
                <div class="font-bold text-neutral-900">{{ dispute.id }}</div>
                <div class="text-[11px] text-neutral-500">{{ dispute.tripId }}</div>
              </td>
              <td class="py-3 px-4 font-medium text-neutral-900">{{ dispute.cancelledBy }}</td>
              <td class="py-3 px-4 text-neutral-600 max-w-xs">
                <div>{{ dispute.reason }}</div>
                <div class="text-[11px] text-neutral-400 mt-0.5">{{ dispute.route }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="responsibilityLabels[dispute.responsibility]"
                  :tone="
                    dispute.responsibility === 'pending_review'
                      ? 'warning'
                      : dispute.responsibility === 'safety_related'
                        ? 'danger'
                        : 'neutral'
                  "
                />
              </td>
              <td class="py-3 px-4">
                <span class="font-mono font-bold text-neutral-900">
                  {{ formatPhp(dispute.cancellationFee) }}
                </span>
                <div class="text-[11px] text-neutral-400">{{ dispute.feeChargedTo }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="dispute.disputeStatus"
                  :tone="
                    dispute.disputeStatus === 'Under Review'
                      ? 'warning'
                      : dispute.disputeStatus.includes('Waived')
                        ? 'info'
                        : 'success'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
                  @click="openResolutionModal(dispute)"
                >
                  {{ dispute.disputeStatus === 'Under Review' ? 'Review' : 'Edit' }}
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedCases.length === 0"
              :colspan="7"
              title="No cancellation records match the active filter"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredCases.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="Boolean(reviewingCase)"
      :title="reviewingCase ? `Responsibility Override · ${reviewingCase.tripId}` : ''"
      size="md"
      close-label="Close modal"
      @update:open="(open) => !open && (reviewingCase = null)"
    >
      <form v-if="reviewingCase" class="space-y-4 text-xs" @submit.prevent="applyResolution">
        <div class="space-y-3">
          <div>
            <label class="block font-semibold text-neutral-700 mb-1"> Fault Classification </label>
            <BaseSelect
              v-model="overrideResponsibility"
              aria-label="Select fault classification"
              :full-width="true"
              :options="[
                { label: 'No Fault (Mutual / Traffic)', value: 'no_fault' },
                { label: 'Driver Fault', value: 'driver_fault' },
                { label: 'Passenger Fault', value: 'passenger_fault' },
                { label: 'System Fault', value: 'system_fault' },
                { label: 'Safety Related', value: 'safety_related' },
                { label: 'Operator Override', value: 'operator_override' },
              ]"
            />
          </div>
          <label class="flex items-center space-x-2 text-neutral-800 cursor-pointer">
            <input v-model="shouldWaiveFee" type="checkbox" class="accent-neutral-900" />
            <span>Waive cancellation fee ({{ formatPhp(reviewingCase.cancellationFee) }})</span>
          </label>
          <div>
            <label class="block font-semibold text-neutral-700 mb-1"> Reason </label>
            <textarea
              v-model="auditNote"
              rows="3"
              required
              placeholder="Explain GPS evidence or operator call verification..."
              class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
            />
          </div>
        </div>

        <div class="flex items-center justify-end gap-2 pt-3 border-t border-neutral-100">
          <button
            type="button"
            class="px-4 py-2 bg-white border border-neutral-200 text-xs font-semibold text-neutral-700 cursor-pointer"
            @click="reviewingCase = null"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="!auditNote.trim()"
            class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 disabled:opacity-40 cursor-pointer"
          >
            Save Determination
          </button>
        </div>
      </form>
    </ModalDialog>
  </div>
</template>
