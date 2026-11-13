<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import TablePagination from '@/app/components/TablePagination.vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import { exportToCsv, formatPhp } from '@/shared/utils/format'

interface DriverWalletRow {
  driverId: string
  driver: string
  phone: string
  plateNumber: string
  balance: number
  totalTopups: number
  totalCommissionPaid: number
  lastTopupAt: string
}

const MINIMUM_DISPATCH_BALANCE = 50

const driverWallets = ref<DriverWalletRow[]>([
  {
    driverId: 'DRV-7016-101',
    driver: 'Rodelio Cruz',
    phone: '+63 917 482 1903',
    plateNumber: 'ZDS-4821 · TODA-0412',
    balance: 18.5,
    totalTopups: 1450,
    totalCommissionPaid: 1431.5,
    lastTopupAt: '4 days ago',
  },
  {
    driverId: 'DRV-7016-102',
    driver: 'Danilo Mendoza',
    phone: '+63 918 654 2219',
    plateNumber: 'ZDS-3019 · TODA-0194',
    balance: 312.75,
    totalTopups: 3800,
    totalCommissionPaid: 3487.25,
    lastTopupAt: 'Yesterday',
  },
  {
    driverId: 'DRV-7016-103',
    driver: 'Reynaldo Bautista',
    phone: '+63 917 773 8810',
    plateNumber: 'ZDS-1944 · TODA-0277',
    balance: 42.0,
    totalTopups: 2150,
    totalCommissionPaid: 2108.0,
    lastTopupAt: '3 days ago',
  },
  {
    driverId: 'DRV-7016-104',
    driver: 'Ernesto Villafuerte',
    phone: '+63 928 914 5532',
    plateNumber: 'ZDS-6120 · TODA-0318',
    balance: 195.0,
    totalTopups: 2700,
    totalCommissionPaid: 2505.0,
    lastTopupAt: 'Today, 08:15 AM',
  },
  {
    driverId: 'DRV-7016-105',
    driver: 'Arnel Cabug',
    phone: '+63 919 331 0745',
    plateNumber: 'ZDS-4402 · TODA-0122',
    balance: 12.0,
    totalTopups: 950,
    totalCommissionPaid: 938.0,
    lastTopupAt: '6 days ago',
  },
])

const searchQuery = ref('')
const eligibilityFilter = ref<'All' | 'Eligible' | 'Locked'>('All')
const currentPage = ref(1)
const itemsPerPage = 8

const toastMessage = ref<string | null>(null)
const adjustingWallet = ref<DriverWalletRow | null>(null)
const adjustmentType = ref<'credit' | 'debit'>('credit')
const adjustmentAmount = ref<number>(100)
const confirmAdjustOpen = ref(false)
const adjustReason = ref('')

const filteredWallets = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return driverWallets.value.filter((wallet) => {
    const isEligible = wallet.balance >= MINIMUM_DISPATCH_BALANCE
    const matchesStatus =
      eligibilityFilter.value === 'All' ||
      (eligibilityFilter.value === 'Eligible' && isEligible) ||
      (eligibilityFilter.value === 'Locked' && !isEligible)
    const matchesSearch =
      !q ||
      wallet.driverId.toLowerCase().includes(q) ||
      wallet.driver.toLowerCase().includes(q) ||
      wallet.phone.toLowerCase().includes(q) ||
      wallet.plateNumber.toLowerCase().includes(q)
    return matchesStatus && matchesSearch
  })
})

watch([searchQuery, eligibilityFilter], () => {
  currentPage.value = 1
})

const paginatedWallets = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredWallets.value.slice(start, start + itemsPerPage)
})

const totalLiability = computed(() =>
  driverWallets.value.reduce((sum, wallet) => sum + wallet.balance, 0),
)

const dispatchLockedCount = computed(
  () => driverWallets.value.filter((wallet) => wallet.balance < MINIMUM_DISPATCH_BALANCE).length,
)

const totalCommissionCollected = computed(() =>
  driverWallets.value.reduce((sum, wallet) => sum + wallet.totalCommissionPaid, 0),
)

const triggerTopupPrompt = (wallet: DriverWalletRow) => {
  toastMessage.value = `Sent GCash/Maya QRPh top-up reminder via SMS & app push to ${wallet.driver} (${wallet.phone}).`
}

const openAdjustModal = (wallet: DriverWalletRow) => {
  adjustingWallet.value = wallet
  adjustmentType.value = 'credit'
  adjustmentAmount.value = 100
  adjustReason.value = ''
}

const closeAdjustModal = () => {
  adjustingWallet.value = null
  confirmAdjustOpen.value = false
}

const requestAdjustmentConfirm = () => {
  if (!adjustingWallet.value || adjustmentAmount.value <= 0) return
  confirmAdjustOpen.value = true
}

const applyWalletAdjustment = () => {
  if (!adjustingWallet.value || !adjustReason.value.trim()) return
  const delta = adjustmentType.value === 'credit' ? adjustmentAmount.value : -adjustmentAmount.value
  adjustingWallet.value.balance = Math.max(
    0,
    Number((adjustingWallet.value.balance + delta).toFixed(2)),
  )
  if (delta > 0) {
    adjustingWallet.value.totalTopups = Number(
      (adjustingWallet.value.totalTopups + delta).toFixed(2),
    )
    adjustingWallet.value.lastTopupAt = 'Just now (Admin Credit)'
  }
  toastMessage.value = `${adjustmentType.value === 'credit' ? 'Credited' : 'Debited'} ${formatPhp(adjustmentAmount.value)} for ${adjustingWallet.value.driver}. New balance: ${formatPhp(adjustingWallet.value.balance)}.`
  closeAdjustModal()
}

const exportWalletLedger = () => {
  exportToCsv(
    'pagadian-driver-wallets.csv',
    ['Driver ID', 'Driver', 'Phone', 'Plate', 'Balance (PHP)', 'Total Top-Ups', 'Eligibility'],
    filteredWallets.value.map((w) => [
      w.driverId,
      w.driver,
      w.phone,
      w.plateNumber,
      w.balance.toFixed(2),
      w.totalTopups.toFixed(2),
      w.balance >= MINIMUM_DISPATCH_BALANCE ? 'Dispatch Eligible' : 'Dispatch Locked',
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner
      v-if="toastMessage"
      :message="toastMessage"
      tone="success"
      @dismiss="toastMessage = null"
    />

    <div
      class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white border border-neutral-200 rounded-md p-4"
    >
      <div>
        <h2 class="text-sm font-semibold text-neutral-900">
          Prepaid Driver Wallet &amp; Dispatch Eligibility
        </h2>
        <p class="text-xs text-neutral-500 mt-0.5">
          Drivers maintain at least {{ formatPhp(MINIMUM_DISPATCH_BALANCE) }} prepaid commission
          credits to remain eligible for live bidding offers in Pagadian City.
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-2 shrink-0">
        <button
          type="button"
          class="px-3 py-1.5 bg-white border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
          @click="exportWalletLedger"
        >
          Export Wallet CSV
        </button>
        <RouterLink
          to="/payments/topups"
          class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
        >
          Review Pending Top-Ups
        </RouterLink>
      </div>
    </div>

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Fleet Prepaid Credit Liability</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ formatPhp(totalLiability) }}
        </div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">
          Dispatch Locked (&lt; {{ formatPhp(MINIMUM_DISPATCH_BALANCE) }} min)
        </span>
        <div class="text-xl font-bold tabular-nums text-rose-600 mt-1">
          {{ dispatchLockedCount }} Drivers
        </div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Platform Commission Collected</span>
        <div class="text-xl font-bold tabular-nums text-emerald-700 mt-1">
          {{ formatPhp(totalCommissionCollected) }}
        </div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Minimum Top-Up Increment</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ formatPhp(50) }}
        </div>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <div class="relative w-full md:w-80">
          <Icon
            icon="lucide:search"
            class="absolute left-3 top-2.5 text-neutral-400 text-sm"
            aria-hidden="true"
          />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search driver, +63 phone, or TODA plate..."
            class="w-full pl-9 pr-3 py-1.5 bg-white border border-neutral-300 rounded-none text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>

        <div class="flex items-center gap-2">
          <BaseSelect
            v-model="eligibilityFilter"
            aria-label="Filter by dispatch eligibility"
            :options="[
              { label: 'All Eligibility States', value: 'All' },
              { label: 'Dispatch Eligible (>= ₱50)', value: 'Eligible' },
              { label: 'Dispatch Locked (< ₱50)', value: 'Locked' },
            ]"
          />
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[840px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Vehicle &amp; TODA</th>
              <th class="py-3 px-4">Prepaid Balance</th>
              <th class="py-3 px-4">Total Top-Ups</th>
              <th class="py-3 px-4">Commission Deducted</th>
              <th class="py-3 px-4">Dispatch Eligibility</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="wallet in paginatedWallets"
              :key="wallet.driverId"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ wallet.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-500">
                  {{ wallet.driverId }} · {{ wallet.phone }}
                </div>
              </td>
              <td class="py-3 px-4">
                <div class="font-mono text-neutral-800">{{ wallet.plateNumber }}</div>
                <div class="text-[11px] text-neutral-400">
                  Last top-up: {{ wallet.lastTopupAt }}
                </div>
              </td>
              <td class="py-3 px-4">
                <span
                  class="font-mono font-bold text-sm tabular-nums"
                  :class="
                    wallet.balance < MINIMUM_DISPATCH_BALANCE ? 'text-rose-600' : 'text-neutral-900'
                  "
                >
                  {{ formatPhp(wallet.balance) }}
                </span>
              </td>
              <td class="py-3 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatPhp(wallet.totalTopups) }}
              </td>
              <td class="py-3 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatPhp(wallet.totalCommissionPaid) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="
                    wallet.balance >= MINIMUM_DISPATCH_BALANCE
                      ? 'Dispatch Eligible'
                      : 'Dispatch Locked'
                  "
                  :tone="wallet.balance >= MINIMUM_DISPATCH_BALANCE ? 'success' : 'danger'"
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <div class="inline-flex items-center gap-2">
                  <button
                    type="button"
                    class="px-2.5 py-1 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50"
                    @click="openAdjustModal(wallet)"
                  >
                    Adjust Credit
                  </button>
                  <button
                    v-if="wallet.balance < MINIMUM_DISPATCH_BALANCE"
                    type="button"
                    class="px-2.5 py-1 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
                    @click="triggerTopupPrompt(wallet)"
                  >
                    Remind Top-Up
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="paginatedWallets.length === 0">
              <td colspan="7" class="py-10 px-4 text-center text-xs text-neutral-500">
                No driver wallets match the active filters.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredWallets.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <Teleport to="body">
      <div
        v-if="adjustingWallet && !confirmAdjustOpen"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/60 p-4"
        @click.self="closeAdjustModal"
      >
        <div
          role="dialog"
          aria-modal="true"
          class="w-full max-w-md bg-white border border-neutral-200 rounded-none p-5 space-y-4 shadow-xl"
        >
          <div class="border-b border-neutral-100 pb-3">
            <h3 class="text-sm font-bold text-neutral-900">
              Manual Wallet Adjustment · {{ adjustingWallet.driver }}
            </h3>
            <p class="text-xs text-neutral-500 mt-0.5">
              Current prepaid balance: {{ formatPhp(adjustingWallet.balance) }} ({{
                adjustingWallet.driverId
              }})
            </p>
          </div>

          <div class="space-y-3 text-xs">
            <div>
              <label class="block font-medium text-neutral-700 mb-1">Adjustment Direction</label>
              <BaseSelect
                v-model="adjustmentType"
                :full-width="true"
                aria-label="Adjustment direction"
                :options="[
                  { label: 'Credit Wallet (+ Add Funds)', value: 'credit' },
                  { label: 'Debit Wallet (- Deduct Correction)', value: 'debit' },
                ]"
              />
            </div>

            <div>
              <label class="block font-medium text-neutral-700 mb-1">Amount (PHP)</label>
              <input
                v-model.number="adjustmentAmount"
                type="number"
                min="1"
                step="10"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-mono bg-white text-neutral-900 focus:outline-none focus:border-neutral-900"
              />
            </div>
          </div>

          <div class="flex items-center justify-end gap-2 border-t border-neutral-100 pt-3">
            <button
              type="button"
              class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
              @click="closeAdjustModal"
            >
              Cancel
            </button>
            <button
              type="button"
              :disabled="!adjustmentAmount || adjustmentAmount <= 0"
              class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800 disabled:opacity-40"
              @click="requestAdjustmentConfirm"
            >
              Continue to Audit Note
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <ConfirmDialog
      v-model:open="confirmAdjustOpen"
      v-model:reason="adjustReason"
      :title="`Confirm Wallet ${adjustmentType === 'credit' ? 'Credit' : 'Debit'} · ${formatPhp(adjustmentAmount)}`"
      :description="`Apply a manual ${adjustmentType} adjustment to ${adjustingWallet?.driver ?? 'driver'}'s prepaid commission ledger.`"
      confirm-label="Apply Adjustment"
      :tone="adjustmentType === 'credit' ? 'emerald' : 'rose'"
      :require-reason="true"
      reason-label="Mandatory Ledger Audit Note"
      reason-placeholder="e.g., Manual fee reversal after cancellation dispute review..."
      @confirm="applyWalletAdjustment"
      @cancel="confirmAdjustOpen = false"
    />
  </div>
</template>
