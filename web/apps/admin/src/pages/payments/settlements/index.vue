<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import TablePagination from '@/shared/table/TablePagination.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
import { exportToCsv, formatBpsAsPercent, formatCentavos } from '@/shared/utils/format'
import {
  getPlatformFeeCentavos,
  getShortfallCentavos,
  useSettlements,
  type CashOutcome,
} from '@/features/payments/composables/use-settlements'

const { settlementRecords, pendingReviewCount } = useSettlements()

const searchQuery = ref('')
const outcomeFilter = ref<'ALL' | CashOutcome>('ALL')
const currentPage = ref(1)
const itemsPerPage = 10
const toastMessage = ref<string | null>(null)

const filteredSettlements = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return settlementRecords.value.filter((record) => {
    if (outcomeFilter.value !== 'ALL' && record.cashOutcome !== outcomeFilter.value) {
      return false
    }
    if (!query) return true
    return (
      record.id.toLowerCase().includes(query) ||
      record.rideId.toLowerCase().includes(query) ||
      record.driverName.toLowerCase().includes(query) ||
      record.passengerName.toLowerCase().includes(query) ||
      record.plateNumber.toLowerCase().includes(query)
    )
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || outcomeFilter.value !== 'ALL',
)

const resetFilters = () => {
  searchQuery.value = ''
  outcomeFilter.value = 'ALL'
}

watch([searchQuery, outcomeFilter], () => {
  currentPage.value = 1
})

const paginatedSettlements = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredSettlements.value.slice(start, start + itemsPerPage)
})

const totalShortfallCentavos = computed(() =>
  settlementRecords.value
    .filter((item) => item.resolutionState === 'pending_review')
    .reduce((sum, item) => sum + getShortfallCentavos(item), 0),
)

const totalCommissionCentavos = computed(() =>
  settlementRecords.value.reduce((sum, item) => sum + getPlatformFeeCentavos(item), 0),
)

const getOutcomeTone = (outcome: CashOutcome) => {
  if (outcome === 'paid') return 'success'
  if (outcome === 'partial') return 'warning'
  if (outcome === 'disputed' || outcome === 'refused') return 'danger'
  return 'neutral'
}

const getOutcomeLabel = (outcome: CashOutcome) => {
  if (outcome === 'paid') return 'Paid'
  if (outcome === 'partial') return 'Partial'
  if (outcome === 'disputed') return 'Disputed'
  if (outcome === 'refused') return 'Refused'
  return 'Unpaid'
}

const getResolutionTone = (state: 'reconciled' | 'pending_review' | 'waived') => {
  if (state === 'reconciled') return 'success'
  if (state === 'waived') return 'info'
  return 'warning'
}

const getResolutionLabel = (state: 'reconciled' | 'pending_review' | 'waived') => {
  if (state === 'reconciled') return 'Reconciled'
  if (state === 'waived') return 'Fee Waived'
  return 'Needs Review'
}

const handleExport = () => {
  const exported = exportToCsv(
    'easyride-cash-settlements-pagadian.csv',
    [
      'Settlement ID',
      'Ride ID',
      'Driver',
      'Passenger',
      'Gross Fare',
      'Platform Fee',
      'Cash Received',
      'Change Given',
      'Shortfall',
      'Cash Outcome',
      'Resolution Status',
    ],
    filteredSettlements.value.map((record) => [
      record.id,
      record.rideId,
      `${record.driverName} (${record.plateNumber})`,
      record.passengerName,
      formatCentavos(record.grossFareCentavos),
      formatCentavos(getPlatformFeeCentavos(record)),
      formatCentavos(record.cashReceivedCentavos),
      formatCentavos(record.cashChangeCentavos),
      formatCentavos(getShortfallCentavos(record)),
      getOutcomeLabel(record.cashOutcome),
      getResolutionLabel(record.resolutionState),
    ]),
  )
  toastMessage.value = exported
    ? 'Cash settlement ledger exported to CSV.'
    : 'No matching rows available to export.'
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Settlements"
      description="Reconcile cash trip outcomes and prepaid commission fees."
    />

    <ToastBanner :message="toastMessage" tone="success" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <div class="bg-white border border-neutral-200 p-4">
        <div class="text-xs font-semibold text-neutral-500 uppercase tracking-wider">
          Pending Settlement Reviews
        </div>
        <div class="text-2xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ pendingReviewCount }}
        </div>
        <p class="text-xs text-neutral-500 mt-1">
          Partial, refused, or disputed cash collections requiring ops sign-off
        </p>
      </div>
      <div class="bg-white border border-neutral-200 p-4">
        <div class="text-xs font-semibold text-neutral-500 uppercase tracking-wider">
          Uncollected Fare Shortfall
        </div>
        <div class="text-2xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalShortfallCentavos) }}
        </div>
        <p class="text-xs text-neutral-500 mt-1">Open cash discrepancies across active cases</p>
      </div>
      <div class="bg-white border border-neutral-200 p-4">
        <div class="text-xs font-semibold text-neutral-500 uppercase tracking-wider">
          Commission Ledger Total
        </div>
        <div class="text-2xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalCommissionCentavos) }}
        </div>
        <p class="text-xs text-neutral-500 mt-1">
          Standard 15% deducted from prepaid driver balances
        </p>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="flex flex-wrap items-center gap-2">
          <h2 class="font-semibold text-sm text-neutral-900">Trip Settlement Queue</h2>
          <StatusBadge :label="`${filteredSettlements.length} Records`" tone="neutral" />
        </div>
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <SearchField
            v-model="searchQuery"
            placeholder="Search ride ID, driver, plate..."
            aria-label="Search cash settlement records"
            class="sm:w-56"
          />
          <BaseSelect
            v-model="outcomeFilter"
            aria-label="Filter by cash outcome"
            :options="[
              { label: 'All Cash Outcomes', value: 'ALL' },
              { label: 'Partial', value: 'partial' },
              { label: 'Disputed', value: 'disputed' },
              { label: 'Refused', value: 'refused' },
              { label: 'Unpaid', value: 'unpaid' },
              { label: 'Paid', value: 'paid' },
            ]"
          />
          <button
            type="button"
            @click="handleExport"
            class="inline-flex items-center justify-center space-x-1.5 px-3 py-1.5 bg-white border border-neutral-200 text-xs font-semibold text-neutral-700 hover:bg-neutral-50 transition-colors cursor-pointer shrink-0"
          >
            <Icon icon="lucide:download" class="w-3.5 h-3.5" aria-hidden="true" />
            <span>Export</span>
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[860px] text-left border-collapse">
          <thead>
            <tr
              class="border-b border-neutral-200 text-[11px] font-semibold text-neutral-500 uppercase tracking-wider bg-neutral-50/70"
            >
              <th class="px-4 py-3">Settlement / Ride</th>
              <th class="px-4 py-3">Driver &amp; Passenger</th>
              <th class="px-4 py-3">Gross &amp; Fee</th>
              <th class="px-4 py-3">Cash / Shortfall</th>
              <th class="px-4 py-3">Cash Outcome</th>
              <th class="px-4 py-3">Status</th>
              <th class="px-4 py-3 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-200 text-xs">
            <tr
              v-for="record in paginatedSettlements"
              :key="record.id"
              class="hover:bg-neutral-50/60 transition-colors"
            >
              <td class="px-4 py-3.5 font-mono">
                <div class="font-bold text-neutral-900">{{ record.id }}</div>
                <div class="text-[11px] text-neutral-500">{{ record.rideId }}</div>
              </td>
              <td class="px-4 py-3.5">
                <div class="font-semibold text-neutral-900">
                  {{ record.driverName }}
                  <span class="font-mono text-[11px] text-neutral-500"
                    >({{ record.plateNumber }})</span
                  >
                </div>
                <div class="text-[11px] text-neutral-500">
                  Passenger: {{ record.passengerName }}
                </div>
              </td>
              <td class="px-4 py-3.5 font-mono">
                <div class="font-bold text-neutral-900">
                  {{ formatCentavos(record.grossFareCentavos) }}
                </div>
                <div class="text-[11px] text-neutral-500">
                  Fee ({{ formatBpsAsPercent(record.commissionBps) }}):
                  {{ formatCentavos(getPlatformFeeCentavos(record)) }}
                </div>
              </td>
              <td class="px-4 py-3.5 font-mono">
                <div class="font-medium text-neutral-900">
                  Paid: {{ formatCentavos(record.cashReceivedCentavos) }}
                </div>
                <div
                  class="text-[11px]"
                  :class="
                    getShortfallCentavos(record) > 0
                      ? 'text-neutral-900 font-semibold'
                      : 'text-neutral-600'
                  "
                >
                  Shortfall: {{ formatCentavos(getShortfallCentavos(record)) }}
                </div>
              </td>
              <td class="px-4 py-3.5">
                <StatusBadge
                  :label="getOutcomeLabel(record.cashOutcome)"
                  :tone="getOutcomeTone(record.cashOutcome)"
                />
              </td>
              <td class="px-4 py-3.5">
                <StatusBadge
                  :label="getResolutionLabel(record.resolutionState)"
                  :tone="getResolutionTone(record.resolutionState)"
                />
              </td>
              <td class="px-4 py-3.5 text-right">
                <RouterLink
                  :to="`/payments/settlements/${record.id}`"
                  class="inline-flex items-center px-3 py-1.5 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800 transition-colors"
                >
                  Inspect
                </RouterLink>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedSettlements.length === 0"
              :colspan="7"
              title="No matching settlement records"
              description="No cash settlement records match the current filters."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredSettlements.length"
        :items-per-page="itemsPerPage"
      />
    </div>
  </div>
</template>
