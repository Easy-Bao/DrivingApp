<script setup lang="ts">
import { computed, ref } from 'vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import { exportToCsv, formatPhp } from '@/shared/utils/format'

interface DriverEarningSummary {
  id: string
  driver: string
  plateNumber: string
  trips: number
  cashGrossPhp: number
  commissionBps: number
  walletStatus: 'Prepaid Credit Active' | 'Low Prepaid Wallet'
}

const earnings = ref<DriverEarningSummary[]>([
  {
    id: 'ERN-7016-101',
    driver: 'Rodelio Cruz',
    plateNumber: 'ZDS-4821 · TODA-0412',
    trips: 48,
    cashGrossPhp: 4680.0,
    commissionBps: 1500,
    walletStatus: 'Low Prepaid Wallet',
  },
  {
    id: 'ERN-7016-102',
    driver: 'Danilo Mendoza',
    plateNumber: 'ZDS-3019 · TODA-0194',
    trips: 64,
    cashGrossPhp: 6840.0,
    commissionBps: 1500,
    walletStatus: 'Prepaid Credit Active',
  },
  {
    id: 'ERN-7016-103',
    driver: 'Reynaldo Bautista',
    plateNumber: 'ZDS-1944 · TODA-0277',
    trips: 53,
    cashGrossPhp: 5420.0,
    commissionBps: 1200,
    walletStatus: 'Low Prepaid Wallet',
  },
  {
    id: 'ERN-7016-104',
    driver: 'Ernesto Villafuerte',
    plateNumber: 'ZDS-6120 · TODA-0318',
    trips: 71,
    cashGrossPhp: 7950.0,
    commissionBps: 1500,
    walletStatus: 'Prepaid Credit Active',
  },
])

const searchQuery = ref('')
const walletFilter = ref<'All' | DriverEarningSummary['walletStatus']>('All')

const platformCommission = (row: DriverEarningSummary) =>
  Number(((row.cashGrossPhp * row.commissionBps) / 10000).toFixed(2))

const driverTakeHome = (row: DriverEarningSummary) =>
  Number((row.cashGrossPhp - platformCommission(row)).toFixed(2))

const filteredEarnings = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return earnings.value.filter((row) => {
    const matchesStatus = walletFilter.value === 'All' || row.walletStatus === walletFilter.value
    const matchesSearch =
      !q || row.driver.toLowerCase().includes(q) || row.plateNumber.toLowerCase().includes(q)
    return matchesStatus && matchesSearch
  })
})

const exportEarningsCsv = () => {
  exportToCsv(
    'pagadian-driver-cash-earnings.csv',
    [
      'Driver',
      'Plate & TODA',
      'Trips',
      'Cash Fares Collected (PHP)',
      'Platform Commission (PHP)',
      'Net Take-Home (PHP)',
      'Prepaid Wallet Status',
    ],
    filteredEarnings.value.map((r) => [
      r.driver,
      r.plateNumber,
      String(r.trips),
      r.cashGrossPhp.toFixed(2),
      platformCommission(r).toFixed(2),
      driverTakeHome(r).toFixed(2),
      r.walletStatus,
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
          Driver Cash Collections &amp; Net Earnings Summary
        </h2>
        <p class="text-xs text-neutral-500 mt-0.5">
          Direct cash fares retained by Pagadian taxicle drivers alongside prepaid commission fees
          debited at settlement (15% standard / 12% top-rated).
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
          placeholder="Search driver or TODA plate..."
          class="w-full md:w-72 px-3 py-1.5 border border-neutral-300 rounded-none text-xs bg-white text-neutral-900 focus:outline-none focus:border-neutral-900"
        />

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="walletFilter"
            aria-label="Filter by prepaid wallet state"
            :options="[
              { label: 'All Wallet States', value: 'All' },
              { label: 'Prepaid Credit Active', value: 'Prepaid Credit Active' },
              { label: 'Low Prepaid Wallet', value: 'Low Prepaid Wallet' },
            ]"
          />
          <button
            type="button"
            class="px-3 py-1.5 bg-white border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer shrink-0"
            @click="exportEarningsCsv"
          >
            Export CSV
          </button>
          <RouterLink
            to="/payments/settlements"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800 shrink-0"
          >
            Settlement Ledger
          </RouterLink>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[820px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Driver &amp; TODA Unit</th>
              <th class="py-3 px-4">Completed Trips</th>
              <th class="py-3 px-4">Cash Collected</th>
              <th class="py-3 px-4">Commission Deducted</th>
              <th class="py-3 px-4">Net Driver Take-Home</th>
              <th class="py-3 px-4 text-right">Ledger Standing</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="row in filteredEarnings"
              :key="row.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3.5 px-4">
                <div class="font-bold text-neutral-900">{{ row.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ row.plateNumber }}</div>
              </td>
              <td class="py-3.5 px-4 font-mono text-neutral-800">{{ row.trips }} rides</td>
              <td class="py-3.5 px-4 font-mono font-semibold text-neutral-900 tabular-nums">
                {{ formatPhp(row.cashGrossPhp) }}
              </td>
              <td class="py-3.5 px-4 font-mono text-neutral-600 tabular-nums">
                -{{ formatPhp(platformCommission(row)) }}
                <span class="text-[10px] text-neutral-400 ml-1">
                  ({{ (row.commissionBps / 100).toFixed(0) }}%)
                </span>
              </td>
              <td class="py-3.5 px-4 font-mono font-bold text-neutral-900 tabular-nums">
                {{ formatPhp(driverTakeHome(row)) }}
              </td>
              <td class="py-3.5 px-4 text-right">
                <StatusBadge
                  :label="row.walletStatus"
                  :tone="row.walletStatus === 'Prepaid Credit Active' ? 'success' : 'warning'"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
