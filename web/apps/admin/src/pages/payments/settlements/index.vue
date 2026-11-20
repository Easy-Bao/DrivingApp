<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import {
  BaseSelect,
  EmptyTableRow,
  exportToCsv,
  formatBpsAsPercent,
  formatCentavos,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  useDataTable,
} from '@/shared'
import { useCommissionTiers, useSettlements } from '@/features/payments'
import type { CashOutcome, SettlementResolutionState } from '@/features/payments'

const router = useRouter()
const { settlements, getPlatformFeeCentavos, getShortfallCentavos } = useSettlements()
const { defaultStandardRateBps } = useCommissionTiers()

const searchQuery = ref('')
const outcomeFilter = ref<'all' | CashOutcome>('all')
const stateFilter = ref<'all' | SettlementResolutionState>('all')

const filteredSettlements = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return settlements.value.filter((record) => {
    const matchesQuery =
      !query ||
      record.id.toLowerCase().includes(query) ||
      record.rideId.toLowerCase().includes(query) ||
      record.driverName.toLowerCase().includes(query) ||
      record.passengerName.toLowerCase().includes(query) ||
      record.plateNumber.toLowerCase().includes(query)
    const matchesOutcome =
      outcomeFilter.value === 'all' || record.cashOutcome === outcomeFilter.value
    const matchesState = stateFilter.value === 'all' || record.resolutionState === stateFilter.value
    return matchesQuery && matchesOutcome && matchesState
  })
})

const hasActiveFilters = computed(
  () =>
    searchQuery.value.trim().length > 0 ||
    outcomeFilter.value !== 'all' ||
    stateFilter.value !== 'all',
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredSettlements, {
  initialPageSize: 10,
  resetDeps: [searchQuery, outcomeFilter, stateFilter],
})

const totalGrossCentavos = computed(() =>
  settlements.value.reduce((sum, item) => sum + item.grossFareCentavos, 0),
)
const totalShortfallCentavos = computed(() =>
  settlements.value
    .filter((item) => item.resolutionState === 'pending_review')
    .reduce((sum, item) => sum + getShortfallCentavos(item), 0),
)
const totalFeeCentavos = computed(() =>
  settlements.value.reduce((sum, item) => sum + getPlatformFeeCentavos(item), 0),
)

function resetFilters() {
  searchQuery.value = ''
  outcomeFilter.value = 'all'
  stateFilter.value = 'all'
}

function outcomeTone(outcome: CashOutcome) {
  if (outcome === 'paid') return 'success'
  if (outcome === 'partial') return 'warning'
  return 'danger'
}

function resolutionTone(state: SettlementResolutionState) {
  if (state === 'reconciled') return 'success'
  if (state === 'pending_review') return 'warning'
  return 'neutral'
}

function exportCsv() {
  exportToCsv(
    'easyride-cash-settlements',
    [
      'Settlement ID',
      'Ride ID',
      'Driver',
      'Passenger',
      'Gross Fare PHP',
      'Cash Received PHP',
      'Shortfall PHP',
      'Platform Fee PHP',
      'Resolution State',
    ],
    filteredSettlements.value.map((record) => [
      record.id,
      record.rideId,
      record.driverName,
      record.passengerName,
      (record.grossFareCentavos / 100).toFixed(2),
      (record.cashReceivedCentavos / 100).toFixed(2),
      (getShortfallCentavos(record) / 100).toFixed(2),
      (getPlatformFeeCentavos(record) / 100).toFixed(2),
      record.resolutionState,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Cash Ride Settlements"
      :description="`Reconcile driver-collected Bao-Bao cash fares, exact change discrepancies, and ${formatBpsAsPercent(defaultStandardRateBps)} prepaid commission deductions.`"
    />

    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <div class="bg-white border border-neutral-200 p-4">
        <span class="text-xs font-medium text-neutral-500">Tracked Ride Fares</span>
        <div class="text-xl font-bold font-mono tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalGrossCentavos) }}
        </div>
      </div>
      <div class="bg-white border border-neutral-200 p-4">
        <span class="text-xs font-medium text-neutral-500">Pending Uncollected Shortfalls</span>
        <div class="text-xl font-bold font-mono tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalShortfallCentavos) }}
        </div>
      </div>
      <div class="bg-white border border-neutral-200 p-4">
        <span class="text-xs font-medium text-neutral-500">
          Platform Commission ({{ formatBpsAsPercent(defaultStandardRateBps) }} std)
        </span>
        <div class="text-xl font-bold font-mono tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalFeeCentavos) }}
        </div>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search settlement ID, ride, driver, passenger..."
          aria-label="Search cash settlement records"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="outcomeFilter"
            aria-label="Filter by cash outcome"
            :options="[
              { label: 'All Cash Outcomes', value: 'all' },
              { label: 'Paid in Full', value: 'paid' },
              { label: 'Partial Cash', value: 'partial' },
              { label: 'Refused Cash', value: 'refused' },
              { label: 'Unpaid', value: 'unpaid' },
              { label: 'Disputed Change', value: 'disputed' },
            ]"
          />
          <BaseSelect
            v-model="stateFilter"
            aria-label="Filter by resolution state"
            :options="[
              { label: 'All Resolution States', value: 'all' },
              { label: 'Pending Review', value: 'pending_review' },
              { label: 'Reconciled', value: 'reconciled' },
              { label: 'Waived', value: 'waived' },
            ]"
          />
          <button
            v-if="hasActiveFilters"
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-700 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
            @click="resetFilters"
          >
            Reset
          </button>
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-700 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
            @click="exportCsv"
          >
            Export CSV
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[920px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Settlement &amp; Ride</th>
              <th class="py-3 px-4">Driver &amp; Passenger</th>
              <th class="py-3 px-4">Gross Fare</th>
              <th class="py-3 px-4">Shortfall</th>
              <th class="py-3 px-4">Platform Fee</th>
              <th class="py-3 px-4">Cash Outcome</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="record in paginatedItems"
              :key="record.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ record.id }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ record.rideId }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ record.driverName }}</div>
                <div class="text-[11px] text-neutral-500">
                  Passenger: {{ record.passengerName }}
                </div>
              </td>
              <td class="py-3 px-4 font-mono font-bold tabular-nums text-neutral-900">
                {{ formatCentavos(record.grossFareCentavos) }}
              </td>
              <td class="py-3 px-4 font-mono tabular-nums text-neutral-900">
                {{ formatCentavos(getShortfallCentavos(record)) }}
              </td>
              <td class="py-3 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatCentavos(getPlatformFeeCentavos(record)) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="record.cashOutcome" :tone="outcomeTone(record.cashOutcome)" />
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="record.resolutionState.replace('_', ' ')"
                  :tone="resolutionTone(record.resolutionState)"
                />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white font-semibold text-xs cursor-pointer"
                  @click="router.push(`/payments/settlements/${record.id}`)"
                >
                  Review Record
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="8"
              title="No matching settlement records"
              description="Adjust filters or search criteria to inspect cash settlement entries."
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
