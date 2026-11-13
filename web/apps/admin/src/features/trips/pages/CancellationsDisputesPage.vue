<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import TablePagination from '@/app/components/TablePagination.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import { formatPhp } from '@/shared/utils/format'

type CancellationResponsibility =
  | 'passenger_fault'
  | 'driver_fault'
  | 'system_fault'
  | 'no_fault'
  | 'safety_related'
  | 'pending_review'
  | 'admin_override'

interface CancellationCase {
  id: string
  tripId: string
  cancelledBy: string
  route: string
  reason: string
  responsibility: CancellationResponsibility
  cancellationFee: number
  feeChargedTo: string
  disputeStatus:
    | 'Under Admin Review'
    | 'Resolved (Fee Upheld)'
    | 'Fee Waived & Overridden'
    | 'Closed'
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
    disputeStatus: 'Under Admin Review',
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
const statusFilter = ref<'ALL' | 'Under Admin Review' | 'RESOLVED'>('ALL')
const currentPage = ref(1)
const itemsPerPage = 10
const toastMessage = ref<string | null>(null)

const reviewingCase = ref<CancellationCase | null>(null)
const overrideResponsibility = ref<CancellationResponsibility>('admin_override')
const shouldWaiveFee = ref(true)
const auditNote = ref('')

const responsibilityLabels: Record<CancellationResponsibility, string> = {
  passenger_fault: 'Passenger Fault',
  driver_fault: 'Driver Fault',
  system_fault: 'System Fault',
  no_fault: 'No Fault (Mutual)',
  safety_related: 'Safety Related',
  pending_review: 'Pending Review',
  admin_override: 'Admin Override',
}

const filteredCases = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return cancellations.value.filter((item) => {
    if (
      statusFilter.value === 'Under Admin Review' &&
      item.disputeStatus !== 'Under Admin Review'
    ) {
      return false
    }
    if (statusFilter.value === 'RESOLVED' && item.disputeStatus === 'Under Admin Review') {
      return false
    }
    if (!q) return true
    return (
      item.id.toLowerCase().includes(q) ||
      item.tripId.toLowerCase().includes(q) ||
      item.cancelledBy.toLowerCase().includes(q) ||
      item.route.toLowerCase().includes(q)
    )
  })
})

watch([searchQuery, statusFilter], () => {
  currentPage.value = 1
})

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
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Cancellations &amp; Dispute Audits
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Assess Pagadian ride cancellations, override fault responsibility, and waive contested
          penalty fees.
        </p>
      </div>
      <span class="px-3 py-1.5 bg-neutral-100 rounded-md text-neutral-800 text-xs font-semibold">
        Cancellation Rate: 3.6%
      </span>
    </div>

    <ToastBanner :message="toastMessage" tone="success" @dismiss="toastMessage = null" />

    <div class="bg-white rounded-lg border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="relative w-full sm:w-64">
            <Icon
              icon="lucide:search"
              class="w-3.5 h-3.5 text-neutral-400 absolute left-3 top-1/2 -translate-y-1/2"
            />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search trip ID, initiated by, route..."
              class="w-full pl-8 pr-3 py-1.5 bg-white border border-neutral-200 rounded-md text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter disputes by status"
            :options="[
              { label: 'All Disputes', value: 'ALL' },
              { label: 'Under Admin Review', value: 'Under Admin Review' },
              { label: 'Resolved Cases', value: 'RESOLVED' },
            ]"
          />
        </div>
        <span class="text-xs text-neutral-400">2-minute post-dispatch grace period active</span>
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
              v-for="c in paginatedCases"
              :key="c.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono">
                <div class="font-bold text-neutral-900">{{ c.id }}</div>
                <div class="text-[11px] text-neutral-500">{{ c.tripId }}</div>
              </td>
              <td class="py-3 px-4 font-medium text-neutral-900">{{ c.cancelledBy }}</td>
              <td class="py-3 px-4 text-neutral-600 max-w-xs">
                <div>{{ c.reason }}</div>
                <div class="text-[11px] text-neutral-400 mt-0.5">{{ c.route }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="responsibilityLabels[c.responsibility]"
                  :tone="
                    c.responsibility === 'pending_review'
                      ? 'warning'
                      : c.responsibility === 'safety_related'
                        ? 'danger'
                        : 'neutral'
                  "
                />
              </td>
              <td class="py-3 px-4">
                <span class="font-mono font-bold text-neutral-900">
                  {{ formatPhp(c.cancellationFee) }}
                </span>
                <div class="text-[11px] text-neutral-400">{{ c.feeChargedTo }}</div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="c.disputeStatus"
                  :tone="
                    c.disputeStatus === 'Under Admin Review'
                      ? 'warning'
                      : c.disputeStatus.includes('Waived')
                        ? 'info'
                        : 'success'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  @click="openResolutionModal(c)"
                  class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-md text-xs font-semibold transition-colors cursor-pointer"
                >
                  {{ c.disputeStatus === 'Under Admin Review' ? 'Review & Override' : 'Re-Audit' }}
                </button>
              </td>
            </tr>
            <tr v-if="paginatedCases.length === 0">
              <td colspan="7" class="py-8 text-center text-xs text-neutral-500">
                No cancellation records match the active filter.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredCases.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <Teleport to="body">
      <div
        v-if="reviewingCase"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/50 backdrop-blur-[1px] p-4"
        role="dialog"
        aria-modal="true"
        @click.self="reviewingCase = null"
      >
        <form
          class="bg-white rounded-lg border border-neutral-200 shadow-2xl w-full max-w-md p-6 space-y-4"
          @submit.prevent="applyResolution"
        >
          <div class="flex items-center justify-between border-b border-neutral-100 pb-3">
            <h3 class="text-sm font-bold text-neutral-900">
              Responsibility Override · {{ reviewingCase.tripId }}
            </h3>
            <button
              type="button"
              aria-label="Close modal"
              @click="reviewingCase = null"
              class="text-neutral-400 hover:text-neutral-700 cursor-pointer"
            >
              <Icon icon="lucide:x" class="w-4 h-4" />
            </button>
          </div>

          <div class="space-y-3 text-xs">
            <div>
              <label class="block font-semibold text-neutral-700 mb-1">
                Fault Classification (server enum)
              </label>
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
                  { label: 'Admin Override', value: 'admin_override' },
                ]"
              />
            </div>
            <label class="flex items-center space-x-2 text-neutral-800 cursor-pointer">
              <input v-model="shouldWaiveFee" type="checkbox" class="accent-neutral-900" />
              <span>Waive cancellation fee ({{ formatPhp(reviewingCase.cancellationFee) }})</span>
            </label>
            <div>
              <label class="block font-semibold text-neutral-700 mb-1">
                Audit Rationale (mandatory)
              </label>
              <textarea
                v-model="auditNote"
                rows="3"
                required
                placeholder="Explain GPS evidence or operator call verification..."
                class="w-full px-3 py-2 border border-neutral-200 rounded-md focus:outline-none focus:border-neutral-900"
              />
            </div>
          </div>

          <div class="flex items-center justify-end gap-2 pt-2 border-t border-neutral-100">
            <button
              type="button"
              @click="reviewingCase = null"
              class="px-4 py-2 bg-white border border-neutral-200 rounded-md text-xs font-semibold text-neutral-700 cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="!auditNote.trim()"
              class="px-4 py-2 bg-neutral-900 text-white rounded-md text-xs font-semibold hover:bg-neutral-800 disabled:opacity-40 cursor-pointer"
            >
              Save Determination
            </button>
          </div>
        </form>
      </div>
    </Teleport>
  </div>
</template>
