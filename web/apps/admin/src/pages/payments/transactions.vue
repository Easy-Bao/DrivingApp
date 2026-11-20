<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  BaseSelect,
  EmptyTableRow,
  exportToCsv,
  formatCentavos,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  useDataTable,
} from '@/shared'
import { useWalletTransactions } from '@/features/payments'
import type { LedgerEntryType } from '@/features/payments'

const { transactions } = useWalletTransactions()

const searchQuery = ref('')
const typeFilter = ref<'All' | LedgerEntryType>('All')

const filteredTransactions = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return transactions.value.filter((entry) => {
    const matchesQuery =
      !query ||
      entry.id.toLowerCase().includes(query) ||
      entry.referenceId.toLowerCase().includes(query) ||
      entry.driver.toLowerCase().includes(query) ||
      entry.method.toLowerCase().includes(query)
    const matchesType = typeFilter.value === 'All' || entry.type === typeFilter.value
    return matchesQuery && matchesType
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || typeFilter.value !== 'All',
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredTransactions, {
  initialPageSize: 10,
  resetDeps: [searchQuery, typeFilter],
})

function resetFilters() {
  searchQuery.value = ''
  typeFilter.value = 'All'
}

function formatSignedCentavos(direction: 'credit' | 'debit', amountCentavos: number): string {
  return `${direction === 'credit' ? '+' : '-'}${formatCentavos(amountCentavos)}`
}

function exportTransactionsCsv() {
  exportToCsv(
    'easyride-wallet-ledger-transactions',
    ['Entry ID', 'Reference ID', 'Driver', 'Type', 'Method', 'Signed PHP', 'Status', 'Timestamp'],
    filteredTransactions.value.map((entry) => [
      entry.id,
      entry.referenceId,
      entry.driver,
      entry.type,
      entry.method,
      `${entry.direction === 'credit' ? '+' : '-'}${(entry.amountCentavos / 100).toFixed(2)}`,
      entry.status,
      entry.timestamp,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Transactions Ledger"
      description="Inspect every prepaid driver commission deduction, QRPh top-up settlement, and operator override."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search entry ID, reference, driver, or rail..."
          aria-label="Search wallet ledger transactions"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="typeFilter"
            aria-label="Filter by ledger entry type"
            :options="[
              { label: 'All Ledger Types', value: 'All' },
              { label: 'Commission Deduction', value: 'Commission Deduction' },
              { label: 'QRPh Wallet Top-Up', value: 'QRPh Wallet Top-Up' },
              { label: 'Bank Top-Up', value: 'Bank Top-Up' },
              { label: 'Settlement Fee Waiver', value: 'Settlement Fee Waiver' },
              { label: 'Operator Wallet Adjustment', value: 'Operator Wallet Adjustment' },
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
            @click="exportTransactionsCsv"
          >
            Export CSV
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[880px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Ledger ID</th>
              <th class="py-3 px-4">Reference</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Type &amp; Rail</th>
              <th class="py-3 px-4">Amount</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4">Timestamp</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="entry in paginatedItems"
              :key="entry.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ entry.id }}</td>
              <td class="py-3 px-4 font-mono text-neutral-700">{{ entry.referenceId }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-900">{{ entry.driver }}</td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-900">{{ entry.type }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ entry.method }}</div>
              </td>
              <td
                class="py-3 px-4 font-mono font-bold tabular-nums"
                :class="entry.direction === 'credit' ? 'text-emerald-700' : 'text-neutral-900'"
              >
                {{ formatSignedCentavos(entry.direction, entry.amountCentavos) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="entry.status"
                  :tone="entry.status === 'Settled' ? 'success' : 'warning'"
                />
              </td>
              <td class="py-3 px-4 text-neutral-500">{{ entry.timestamp }}</td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="7"
              title="No matching ledger transactions"
              description="No ledger entries match the current search or transaction filter."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredTransactions.length"
        :items-per-page="itemsPerPage"
      />
    </div>
  </div>
</template>
