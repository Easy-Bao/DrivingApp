<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import TablePagination from '@/app/components/TablePagination.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import { exportToCsv, formatBpsAsPercent, formatCentavos } from '@/shared/utils/format'
import {
  getPlatformFeeCentavos,
  getShortfallCentavos,
  useSettlements,
  type CashOutcome,
} from '../composables/useSettlements'

const { settlementRecords, pendingReviewCount } = useSettlements()

const searchQuery = ref('')
const outcomeFilter = ref<'ALL' | CashOutcome>('ALL')
const currentPage = ref(1)
const itemsPerPage = 10
const toastMessage = ref<string | null>(null)

const filteredSettlements = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return settlementRecords.value.filter((record) => {
    if (outcomeFilter.value !== 'ALL' && record.cashOutcome !== outcomeFilter.value) {
      return false
    }
    if (!q) return true
    return (
      record.id.toLowerCase().includes(q) ||
      record.rideId.toLowerCase().includes(q) ||
      record.driverName.toLowerCase().includes(q) ||
      record.passengerName.toLowerCase().includes(q) ||
      record.plateNumber.toLowerCase().includes(q)
    )
  })
})

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
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Cash Settlements
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Reconcile cash-in-hand trip outcomes, driver change records, and prepaid commission fees.
        </p>
      </div>
      <button
        type="button"
        @click="handleExport"
        class="inline-flex items-center justify-center space-x-2 px-4 py-2 bg-white border border-neutral-200 rounded-md text-xs font-semibold text-neutral-700 hover:bg-neutral-50 transition-colors cursor-pointer"
      >
        <Icon icon="lucide:download" class="w-4 h-4" />
        <span>Export Ledger CSV</span>
      </button>
    </div>

    <ToastBanner :message="toastMessage" tone="success" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="bg-white rounded-lg border border-neutral-200 p-4">
        <div class="text-xs font-semibold text-neutral-500 uppercase tracking-wider">
          Pending Settlement Reviews
        </div>
        <div class="text-2xl font-bold tabular-nums text-amber-600 mt-1">
          {{ pendingReviewCount }}
        </div>
        <p class="text-xs text-neutral-500 mt-1">
          Partial, refused, or disputed cash collections requiring ops sign-off
        </p>
      </div>
      <div class="bg-white rounded-lg border border-neutral-200 p-4">
        <div class="text-xs font-semibold text-neutral-500 uppercase tracking-wider">
          Uncollected Fare Shortfall
        </div>
        <div class="text-2xl font-bold tabular-nums text-rose-600 mt-1">
          {{ formatCentavos(totalShortfallCentavos) }}
        </div>
        <p class="text-xs text-neutral-500 mt-1">Open cash discrepancies across active cases</p>
      </div>
      <div class="bg-white rounded-lg border border-neutral-200 p-4">
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

    <div class="bg-white rounded-lg border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="flex flex-wrap items-center gap-2">
          <h2 class="font-semibold text-sm text-neutral-900">Trip Settlement Queue</h2>
          <StatusBadge :label="`${filteredSettlements.length} Records`" tone="neutral" />
        </div>
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="relative">
            <Icon
              icon="lucide:search"
              class="w-3.5 h-3.5 text-neutral-400 absolute left-3 top-1/2 -translate-y-1/2"
            />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search ride ID, driver, plate..."
              class="w-full sm:w-56 pl-8 pr-3 py-1.5 bg-white border border-neutral-200 rounded-md text-xs text-neutral-900 placeholder:text-neutral-400 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <select
            v-model="outcomeFilter"
            aria-label="Filter by cash outcome"
            class="px-3 py-1.5 bg-white border border-neutral-200 rounded-md text-xs font-medium text-neutral-700 focus:outline-none focus:border-neutral-900 cursor-pointer"
          >
            <option value="ALL">All Cash Outcomes</option>
            <option value="partial">Partial</option>
            <option value="disputed">Disputed</option>
            <option value="refused">Refused</option>
            <option value="unpaid">Unpaid</option>
            <option value="paid">Paid</option>
          </select>
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
                      ? 'text-rose-600 font-semibold'
                      : 'text-emerald-600'
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
                  class="inline-flex items-center px-3 py-1.5 bg-neutral-900 text-white rounded-md text-xs font-medium hover:bg-neutral-800 transition-colors"
                >
                  Inspect
                </RouterLink>
              </td>
            </tr>
            <tr v-if="paginatedSettlements.length === 0">
              <td colspan="7" class="px-4 py-8 text-center text-xs text-neutral-500">
                No cash settlement records match the current filters.
              </td>
            </tr>
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
