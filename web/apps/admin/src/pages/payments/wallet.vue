<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink } from 'vue-router'
import {
  BaseSelect,
  ConfirmDialog,
  EmptyTableRow,
  exportToCsv,
  formatCentavos,
  ModalDialog,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  ToastBanner,
  useDataTable,
  useToast,
} from '@/shared'
import { useWalletAccounts } from '@/features/payments'
import type { DriverWalletRow } from '@/features/payments'

const { wallets, minDispatchBalanceCentavos, minTopUpAmountCentavos, adjustDriverWallet } =
  useWalletAccounts()

const searchQuery = ref('')
const eligibilityFilter = ref<'All' | 'Eligible' | 'Locked'>('All')
const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

const showAdjustModal = ref(false)
const showAuditConfirm = ref(false)
const targetWallet = ref<DriverWalletRow | null>(null)
const adjustDirection = ref<'credit' | 'debit'>('credit')
const adjustAmountPhp = ref('100')
const adjustNote = ref('')
const modalError = ref<string | null>(null)

const filteredWallets = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  const threshold = minDispatchBalanceCentavos.value
  return wallets.value.filter((wallet) => {
    const matchesQuery =
      !query ||
      wallet.driver.toLowerCase().includes(query) ||
      wallet.driverId.toLowerCase().includes(query) ||
      wallet.phone.toLowerCase().includes(query) ||
      wallet.plateNumber.toLowerCase().includes(query)
    const isEligible = wallet.balanceCentavos >= threshold
    const matchesEligibility =
      eligibilityFilter.value === 'All' ||
      (eligibilityFilter.value === 'Eligible' && isEligible) ||
      (eligibilityFilter.value === 'Locked' && !isEligible)
    return matchesQuery && matchesEligibility
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || eligibilityFilter.value !== 'All',
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredWallets, {
  initialPageSize: 10,
  resetDeps: [searchQuery, eligibilityFilter],
})

const totalLiabilityCentavos = computed(() =>
  wallets.value.reduce((sum, wallet) => sum + wallet.balanceCentavos, 0),
)
const dispatchLockedCount = computed(
  () =>
    wallets.value.filter((wallet) => wallet.balanceCentavos < minDispatchBalanceCentavos.value)
      .length,
)
const totalCommissionCollectedCentavos = computed(() =>
  wallets.value.reduce((sum, wallet) => sum + wallet.totalCommissionPaidCentavos, 0),
)

function resetFilters() {
  searchQuery.value = ''
  eligibilityFilter.value = 'All'
}

function openAdjustModal(wallet: DriverWalletRow) {
  targetWallet.value = wallet
  adjustDirection.value = 'credit'
  adjustAmountPhp.value = '100'
  adjustNote.value = ''
  modalError.value = null
  showAdjustModal.value = true
}

function proceedToAuditConfirmation() {
  const amountCentavos = Math.round(Number(adjustAmountPhp.value) * 100)
  if (!Number.isFinite(amountCentavos) || amountCentavos <= 0) {
    modalError.value = 'Enter a valid PHP adjustment amount greater than zero.'
    return
  }
  modalError.value = null
  showAdjustModal.value = false
  showAuditConfirm.value = true
}

function submitWalletAdjustment() {
  if (!targetWallet.value) return
  const amountCentavos = Math.round(Number(adjustAmountPhp.value) * 100)
  const result = adjustDriverWallet(targetWallet.value.driverId, {
    direction: adjustDirection.value,
    amountCentavos,
    reason: adjustNote.value,
  })
  if (!result.ok) {
    showToast(result.error, 'warning')
    return
  }
  showAuditConfirm.value = false
  adjustNote.value = ''
  showToast(result.message ?? `Adjusted wallet for ${targetWallet.value.driver}`)
}

function triggerTopupPrompt(wallet: DriverWalletRow) {
  showToast(`Queued SMS/in-app low-wallet reminder for ${wallet.driver} (${wallet.phone}).`, 'info')
}

function exportWalletLedger() {
  const threshold = minDispatchBalanceCentavos.value
  exportToCsv(
    'easyride-driver-wallets',
    [
      'Driver ID',
      'Driver',
      'Phone',
      'Plate / TODA',
      'Balance PHP',
      'Total Top-Ups PHP',
      'Commission Deducted PHP',
      'Standing',
    ],
    filteredWallets.value.map((wallet) => [
      wallet.driverId,
      wallet.driver,
      wallet.phone,
      wallet.plateNumber,
      (wallet.balanceCentavos / 100).toFixed(2),
      (wallet.totalTopupsCentavos / 100).toFixed(2),
      (wallet.totalCommissionPaidCentavos / 100).toFixed(2),
      wallet.balanceCentavos >= threshold ? 'Dispatch Eligible' : 'Dispatch Locked',
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Wallets"
      :description="`Monitor driver prepaid balances and the ${formatCentavos(minDispatchBalanceCentavos)} dispatch threshold.`"
    />

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Fleet Prepaid Credit Liability</span>
        <div class="text-xl font-bold font-mono tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalLiabilityCentavos) }}
        </div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">
          Dispatch Locked (&lt; {{ formatCentavos(minDispatchBalanceCentavos) }} min)
        </span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">
          {{ dispatchLockedCount }} Drivers
        </div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Platform Commission Collected</span>
        <div class="text-xl font-bold font-mono tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(totalCommissionCollectedCentavos) }}
        </div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <div class="flex items-center justify-between gap-2">
          <span class="text-xs text-neutral-500 font-medium">Minimum Top-Up Increment</span>
          <RouterLink
            to="/config/wallet-rules"
            class="text-[11px] font-semibold text-neutral-600 hover:text-neutral-900 hover:underline"
          >
            Rules
          </RouterLink>
        </div>
        <div class="text-xl font-bold font-mono tabular-nums text-neutral-900 mt-1">
          {{ formatCentavos(minTopUpAmountCentavos) }}
        </div>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search driver, phone, or TODA plate..."
          aria-label="Search driver wallets"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="eligibilityFilter"
            aria-label="Filter by dispatch eligibility"
            :options="[
              { label: 'All Eligibility States', value: 'All' },
              {
                label: `Dispatch Eligible (>= ${formatCentavos(minDispatchBalanceCentavos)})`,
                value: 'Eligible',
              },
              {
                label: `Dispatch Locked (< ${formatCentavos(minDispatchBalanceCentavos)})`,
                value: 'Locked',
              },
            ]"
          />
          <button
            v-if="hasActiveFilters"
            type="button"
            class="px-3 py-1.5 bg-white border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            @click="resetFilters"
          >
            Reset
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-white border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            @click="exportWalletLedger"
          >
            Export CSV
          </button>
          <RouterLink
            to="/payments/topups"
            class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800"
          >
            Pending Top-Ups
          </RouterLink>
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
              v-for="wallet in paginatedItems"
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
                <div class="text-[11px] text-neutral-500">
                  Last top-up: {{ wallet.lastTopupAt }}
                </div>
              </td>
              <td class="py-3 px-4">
                <span class="font-mono font-bold text-sm tabular-nums text-neutral-900">
                  {{ formatCentavos(wallet.balanceCentavos) }}
                </span>
              </td>
              <td class="py-3 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatCentavos(wallet.totalTopupsCentavos) }}
              </td>
              <td class="py-3 px-4 font-mono tabular-nums text-neutral-700">
                {{ formatCentavos(wallet.totalCommissionPaidCentavos) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="
                    wallet.balanceCentavos >= minDispatchBalanceCentavos
                      ? 'Dispatch Eligible'
                      : 'Dispatch Locked'
                  "
                  :tone="
                    wallet.balanceCentavos >= minDispatchBalanceCentavos ? 'success' : 'danger'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <div class="inline-flex items-center gap-2">
                  <button
                    type="button"
                    class="px-2.5 py-1 border border-neutral-300 bg-white text-neutral-800 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
                    @click="openAdjustModal(wallet)"
                  >
                    Adjust Credit
                  </button>
                  <button
                    v-if="wallet.balanceCentavos < minDispatchBalanceCentavos"
                    type="button"
                    class="px-2.5 py-1 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800 cursor-pointer"
                    @click="triggerTopupPrompt(wallet)"
                  >
                    Remind Top-Up
                  </button>
                </div>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="7"
              title="No matching driver wallets"
              description="No prepaid driver wallet accounts match the selected filter criteria."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredWallets.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      v-model:open="showAdjustModal"
      :title="targetWallet ? `Adjust Prepaid Wallet · ${targetWallet.driver}` : 'Adjust Wallet'"
      subtitle="Specify credit or debit amount in PHP before logging a mandatory audit trail note."
      size="sm"
    >
      <div class="space-y-3 text-xs">
        <div>
          <div class="font-medium text-neutral-700 mb-1">Adjustment Direction</div>
          <BaseSelect
            v-model="adjustDirection"
            :full-width="true"
            aria-label="Wallet adjustment direction"
            :options="[
              { label: 'Credit Prepaid Wallet (+)', value: 'credit' },
              { label: 'Debit Prepaid Wallet (-)', value: 'debit' },
            ]"
          />
        </div>
        <div>
          <label for="wallet-adjustment-amount" class="block font-medium text-neutral-700 mb-1">
            Amount (PHP)
          </label>
          <input
            id="wallet-adjustment-amount"
            v-model="adjustAmountPhp"
            type="number"
            min="1"
            step="0.01"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
          />
        </div>
        <p v-if="modalError" role="alert" class="text-rose-700 font-medium">{{ modalError }}</p>
      </div>

      <template #footer>
        <button
          type="button"
          class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-700 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
          @click="showAdjustModal = false"
        >
          Cancel
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="proceedToAuditConfirmation"
        >
          Continue to Audit Note
        </button>
      </template>
    </ModalDialog>

    <ConfirmDialog
      v-model:open="showAuditConfirm"
      v-model:reason="adjustNote"
      :title="`Confirm Wallet ${adjustDirection === 'credit' ? 'Credit' : 'Debit'}`"
      :description="`Record an immutable ledger adjustment for ${targetWallet?.driver ?? 'driver'}.`"
      confirm-label="Apply Adjustment"
      :tone="adjustDirection === 'debit' ? 'rose' : 'neutral'"
      :require-reason="true"
      reason-label="Mandatory Ledger Audit Note"
      reason-placeholder="e.g., Operator reserve credit for TODA orientation."
      @confirm="submitWalletAdjustment"
    />
  </div>
</template>
