<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  useCancellationDisputes,
  type CancellationCase,
  type CancellationResponsibility,
} from '@/features/trips'
import {
  BaseSelect,
  EmptyTableRow,
  ModalDialog,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  ToastBanner,
  formatCentavos,
  useDataTable,
} from '@/shared'

const { disputes, responsibilityLabels, resolveDispute } = useCancellationDisputes()

const searchQuery = ref('')
const statusFilter = ref<'ALL' | 'Under Review' | 'RESOLVED'>('ALL')
const toastMessage = ref<string | null>(null)

const reviewingCase = ref<CancellationCase | null>(null)
const overrideResponsibility = ref<CancellationResponsibility>('operator_override')
const shouldWaiveFee = ref(true)
const auditNote = ref('')

const openReviewCount = computed(
  () => disputes.value.filter((item) => item.disputeStatus === 'Under Review').length,
)

const filteredCases = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return disputes.value.filter((item) => {
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

const hasActiveFilters = computed(() => searchQuery.value !== '' || statusFilter.value !== 'ALL')

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'ALL'
}

const {
  currentPage,
  itemsPerPage,
  paginatedItems: paginatedCases,
} = useDataTable(filteredCases, {
  initialPageSize: 10,
  resetDeps: [searchQuery, statusFilter],
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
  if (!target) return
  const result = resolveDispute(target.id, {
    responsibility: overrideResponsibility.value,
    waiveFee: shouldWaiveFee.value,
    auditNote: auditNote.value,
  })
  if (!result.ok) {
    toastMessage.value = result.error
    return
  }

  toastMessage.value = `${target.tripId} responsibility set to ${responsibilityLabels[overrideResponsibility.value]}.`
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
          Open: {{ openReviewCount }} · Total: {{ disputes.length }}
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
                  {{ formatCentavos(dispute.cancellationFeeCentavos) }}
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
      close-label="Close"
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
            <span>
              Waive cancellation fee ({{ formatCentavos(reviewingCase.cancellationFeeCentavos) }})
            </span>
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
