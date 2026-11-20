<script setup lang="ts">
import { computed, ref } from 'vue'
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
import {
  computeDriverTakeHomeCentavos,
  computePlatformCommissionCentavos,
  useDriverEarnings,
} from '@/features/payments'
import type { DriverWalletStanding } from '@/features/payments'

const { earnings } = useDriverEarnings()

const searchQuery = ref('')
const standingFilter = ref<'All' | DriverWalletStanding>('All')

const filteredEarnings = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return earnings.value.filter((row) => {
    const matchesQuery =
      !query ||
      row.id.toLowerCase().includes(query) ||
      row.driver.toLowerCase().includes(query) ||
      row.plateNumber.toLowerCase().includes(query)
    const matchesStanding =
      standingFilter.value === 'All' || row.walletStatus === standingFilter.value
    return matchesQuery && matchesStanding
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || standingFilter.value !== 'All',
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredEarnings, {
  initialPageSize: 10,
  resetDeps: [searchQuery, standingFilter],
})

const totalGrossCentavos = computed(() =>
  filteredEarnings.value.reduce((sum, row) => sum + row.cashGrossCentavos, 0),
)
const totalCommissionCentavos = computed(() =>
  filteredEarnings.value.reduce((sum, row) => sum + computePlatformCommissionCentavos(row), 0),
)
const totalDriverTakeHomeCentavos = computed(() =>
  filteredEarnings.value.reduce((sum, row) => sum + computeDriverTakeHomeCentavos(row), 0),
)

function resetFilters() {
  searchQuery.value = ''
  standingFilter.value = 'All'
}

function exportEarningsCsv() {
  exportToCsv(
    'easyride-driver-earnings',
    [
      'ID',
      'Driver',
      'Plate / TODA',
      'Trips',
      'Cash Gross PHP',
      'Commission Rate',
      'Platform Commission PHP',
      'Driver Take-Home PHP',
      'Wallet Standing',
    ],
    filteredEarnings.value.map((row) => [
      row.id,
      row.driver,
      row.plateNumber,
      String(row.trips),
      (row.cashGrossCentavos / 100).toFixed(2),
      formatBpsAsPercent(row.commissionBps),
      (computePlatformCommissionCentavos(row) / 100).toFixed(2),
      (computeDriverTakeHomeCentavos(row) / 100).toFixed(2),
      row.walletStatus,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Driver Earnings & Take-Home"
      description="Track driver-retained cash fares versus prepaid platform commission deductions by TODA tier."
    />

    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <div class="bg-white border border-neutral-200 p-4">
        <span class="text-xs font-medium text-neutral-500">Cash Gross Collected</span>
        <div class="text-xl font-bold font-mono tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalGrossCentavos) }}
        </div>
      </div>
      <div class="bg-white border border-neutral-200 p-4">
        <span class="text-xs font-medium text-neutral-500">Platform Commission Deducted</span>
        <div class="text-xl font-bold font-mono tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalCommissionCentavos) }}
        </div>
      </div>
      <div class="bg-white border border-neutral-200 p-4">
        <span class="text-xs font-medium text-neutral-500">Net Driver Cash Retained</span>
        <div class="text-xl font-bold font-mono tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalDriverTakeHomeCentavos) }}
        </div>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search driver, ID, or plate..."
          aria-label="Search driver earnings"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="standingFilter"
            aria-label="Filter by wallet standing"
            :options="[
              { label: 'All Wallet Standings', value: 'All' },
              { label: 'Prepaid Credit Active', value: 'Prepaid Credit Active' },
              { label: 'Low Prepaid Wallet', value: 'Low Prepaid Wallet' },
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
            @click="exportEarningsCsv"
          >
            Export CSV
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[840px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Driver &amp; Unit</th>
              <th class="py-3 px-4">Trips</th>
              <th class="py-3 px-4">Cash Gross Collected</th>
              <th class="py-3 px-4">Platform Commission</th>
              <th class="py-3 px-4">Driver Net Take-Home</th>
              <th class="py-3 px-4">Wallet Standing</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="row in paginatedItems"
              :key="row.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ row.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-500">
                  {{ row.id }} · {{ row.plateNumber }}
                </div>
              </td>
              <td class="py-3 px-4 font-mono tabular-nums text-neutral-800">{{ row.trips }}</td>
              <td class="py-3 px-4 font-mono font-bold tabular-nums text-neutral-900">
                {{ formatCentavos(row.cashGrossCentavos) }}
              </td>
              <td class="py-3 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatCentavos(computePlatformCommissionCentavos(row)) }}
                <span class="text-neutral-500">({{ formatBpsAsPercent(row.commissionBps) }})</span>
              </td>
              <td class="py-3 px-4 font-mono font-bold tabular-nums text-neutral-900">
                {{ formatCentavos(computeDriverTakeHomeCentavos(row)) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="row.walletStatus"
                  :tone="row.walletStatus === 'Prepaid Credit Active' ? 'success' : 'warning'"
                />
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="6"
              title="No matching earnings summaries"
              description="No driver earnings records match the current search or wallet status."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredEarnings.length"
        :items-per-page="itemsPerPage"
      />
    </div>
  </div>
</template>
