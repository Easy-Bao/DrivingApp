<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import TablePagination from '@/shared/components/TablePagination.vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import { exportToCsv, formatPhp } from '@/shared/utils/format'

type LedgerEntryType =
  | 'Commission Deduction'
  | 'QRPh Wallet Top-Up'
  | 'Bank Top-Up'
  | 'Settlement Fee Waiver'

interface WalletLedgerEntry {
  id: string
  referenceId: string
  driver: string
  type: LedgerEntryType
  method: string
  amountPhp: number
  direction: 'credit' | 'debit'
  status: 'Settled' | 'Pending Review'
  timestamp: string
}

const transactions = ref<WalletLedgerEntry[]>([
  {
    id: 'TXN-7016-9401',
    referenceId: 'TRP-7016-8921',
    driver: 'Rodelio Cruz',
    type: 'Commission Deduction',
    method: 'Prepaid Wallet · 1500 bps',
    amountPhp: 12.75,
    direction: 'debit',
    status: 'Settled',
    timestamp: 'Today, 09:42 AM',
  },
  {
    id: 'TXN-7016-9400',
    referenceId: 'TOP-8921',
    driver: 'Rodelio Cruz',
    type: 'QRPh Wallet Top-Up',
    method: 'GCash QRPh · QR-8829104',
    amountPhp: 200.0,
    direction: 'credit',
    status: 'Pending Review',
    timestamp: 'Today, 09:34 AM',
  },
  {
    id: 'TXN-7016-9399',
    referenceId: 'TRP-7016-8920',
    driver: 'Danilo Mendoza',
    type: 'Commission Deduction',
    method: 'Prepaid Wallet · 1500 bps',
    amountPhp: 18.0,
    direction: 'debit',
    status: 'Settled',
    timestamp: 'Today, 09:15 AM',
  },
  {
    id: 'TXN-7016-9398',
    referenceId: 'TOP-8920',
    driver: 'Ernesto Villafuerte',
    type: 'Bank Top-Up',
    method: 'BDO InstaPay · BDO-9921873',
    amountPhp: 500.0,
    direction: 'credit',
    status: 'Pending Review',
    timestamp: 'Today, 08:40 AM',
  },
  {
    id: 'TXN-7016-9397',
    referenceId: 'CAN-7016-302',
    driver: 'Reynaldo Bautista',
    type: 'Settlement Fee Waiver',
    method: 'Operator Override · Credit Back',
    amountPhp: 15.0,
    direction: 'credit',
    status: 'Settled',
    timestamp: 'Yesterday, 06:10 PM',
  },
])

const searchQuery = ref('')
const typeFilter = ref<'All' | LedgerEntryType>('All')
const currentPage = ref(1)
const itemsPerPage = 10

const filteredTransactions = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return transactions.value.filter((txn) => {
    const matchesType = typeFilter.value === 'All' || txn.type === typeFilter.value
    const matchesSearch =
      !q ||
      txn.id.toLowerCase().includes(q) ||
      txn.referenceId.toLowerCase().includes(q) ||
      txn.driver.toLowerCase().includes(q) ||
      txn.method.toLowerCase().includes(q)
    return matchesType && matchesSearch
  })
})

watch([searchQuery, typeFilter], () => {
  currentPage.value = 1
})

const paginatedTransactions = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredTransactions.value.slice(start, start + itemsPerPage)
})

const exportLedger = () => {
  exportToCsv(
    'pagadian-wallet-ledger.csv',
    ['Transaction ID', 'Reference', 'Driver', 'Type', 'Channel', 'Amount (PHP)', 'Status', 'Time'],
    filteredTransactions.value.map((t) => [
      t.id,
      t.referenceId,
      t.driver,
      t.type,
      t.method,
      `${t.direction === 'debit' ? '-' : '+'}${t.amountPhp.toFixed(2)}`,
      t.status,
      t.timestamp,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <div
      class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white border border-neutral-200 p-4"
    >
      <div>
        <h2 class="text-sm font-semibold text-neutral-900">
          Prepaid Commission &amp; Top-Up Ledger
        </h2>
        <p class="text-xs text-neutral-500 mt-0.5">
          Immutable journal of prepaid credit top-ups, per-trip basis-point deductions, and fee
          waivers in PHP.
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
          placeholder="Search TXN ID, reference, driver, or rail..."
          class="w-full md:w-80 px-3 py-1.5 border border-neutral-300 rounded-none text-xs bg-white text-neutral-900 focus:outline-none focus:border-neutral-900"
        />

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="typeFilter"
            aria-label="Filter by ledger entry type"
            :options="[
              { label: 'All Ledger Entries', value: 'All' },
              { label: 'Commission Deduction', value: 'Commission Deduction' },
              { label: 'QRPh Wallet Top-Up', value: 'QRPh Wallet Top-Up' },
              { label: 'Bank Top-Up', value: 'Bank Top-Up' },
              { label: 'Settlement Fee Waiver', value: 'Settlement Fee Waiver' },
            ]"
          />
          <button
            type="button"
            class="px-3 py-1.5 bg-white border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer shrink-0"
            @click="exportLedger"
          >
            Export CSV
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[800px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Transaction ID</th>
              <th class="py-3 px-4">Driver &amp; Reference</th>
              <th class="py-3 px-4">Entry Type &amp; Rail</th>
              <th class="py-3 px-4">Amount (PHP)</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Timestamp</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="txn in paginatedTransactions"
              :key="txn.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ txn.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ txn.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-500">Ref: {{ txn.referenceId }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-900">{{ txn.type }}</div>
                <div class="text-[11px] text-neutral-500">{{ txn.method }}</div>
              </td>
              <td class="py-3 px-4 font-mono font-bold tabular-nums text-neutral-900">
                {{ txn.direction === 'credit' ? '+' : '-' }}{{ formatPhp(txn.amountPhp) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="txn.status"
                  :tone="txn.status === 'Settled' ? 'success' : 'warning'"
                />
              </td>
              <td class="py-3 px-4 text-right text-neutral-500 font-mono text-[11px]">
                {{ txn.timestamp }}
              </td>
            </tr>
            <tr v-if="paginatedTransactions.length === 0">
              <td colspan="6" class="py-10 px-4 text-center text-xs text-neutral-500">
                No ledger entries match the active filters.
              </td>
            </tr>
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
