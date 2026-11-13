<script setup lang="ts">
import { ref } from 'vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import { formatBpsAsPercent, formatPhp } from '@/shared/utils/format'

interface CommissionTier {
  id: string
  category: string
  rateBps: number
  fixedBookingFeePhp: number
  minWalletBalancePhp: number
  eligibilityRule: string
  settlementNote: string
}

const commissionTiers = ref<CommissionTier[]>([
  {
    id: 'standard-taxicle',
    category: 'Standard Solo Taxicle Fleet',
    rateBps: 1500,
    fixedBookingFeePhp: 0,
    minWalletBalancePhp: 50,
    eligibilityRule: 'Default Pagadian TODA franchise taxicles upon activation.',
    settlementNote: '15% deducted from driver prepaid commission wallet on trip completion.',
  },
  {
    id: 'top-rated-incentive',
    category: 'Top-Rated Service Tier (>= 4.85★)',
    rateBps: 1200,
    fixedBookingFeePhp: 0,
    minWalletBalancePhp: 50,
    eligibilityRule: 'Maintains >= 4.85★ rating and >= 95% acceptance over trailing 30 days.',
    settlementNote: 'Discounted 12% commission rate automatically awarded weekly.',
  },
  {
    id: 'etrike-pioneer',
    category: 'Electric Tricycle Pioneer Program',
    rateBps: 1000,
    fixedBookingFeePhp: 0,
    minWalletBalancePhp: 50,
    eligibilityRule: 'Verified battery-electric public utility tricycles operating in Pagadian.',
    settlementNote: '10% sustainability incentive tier stored as 1000 bps in settlement ledger.',
  },
])

const editingTier = ref<CommissionTier | null>(null)
const draftBps = ref<number>(1500)
const draftBookingFee = ref<number>(0)
const draftMinWallet = ref<number>(50)
const draftRuleText = ref<string>('')
const modalError = ref<string | null>(null)
const toastMessage = ref<string | null>(null)

const openConfigModal = (tier: CommissionTier) => {
  editingTier.value = tier
  draftBps.value = tier.rateBps
  draftBookingFee.value = tier.fixedBookingFeePhp
  draftMinWallet.value = tier.minWalletBalancePhp
  draftRuleText.value = tier.eligibilityRule
  modalError.value = null
}

const closeConfigModal = () => {
  editingTier.value = null
  modalError.value = null
}

const saveConfig = () => {
  if (!editingTier.value) return
  if (draftBps.value < 100 || draftBps.value > 3500) {
    modalError.value = 'Commission rate must stay between 100 bps (1.0%) and 3500 bps (35.0%).'
    return
  }
  if (draftMinWallet.value < 0 || draftBookingFee.value < 0) {
    modalError.value = 'Fee and wallet threshold values cannot be negative.'
    return
  }
  editingTier.value.rateBps = draftBps.value
  editingTier.value.fixedBookingFeePhp = draftBookingFee.value
  editingTier.value.minWalletBalancePhp = draftMinWallet.value
  editingTier.value.eligibilityRule =
    draftRuleText.value.trim() || editingTier.value.eligibilityRule
  toastMessage.value = `Updated ${editingTier.value.category} to ${formatBpsAsPercent(draftBps.value)} (${draftBps.value} bps).`
  closeConfigModal()
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
      class="bg-white border border-neutral-200 p-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between"
    >
      <div>
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-neutral-900">
            Platform Commission &amp; Settlement Basis-Point Rules
          </h2>
          <StatusBadge label="Cash Settlement Model" tone="neutral" />
        </div>
        <p class="text-xs text-neutral-500 mt-0.5">
          Drivers collect 100% fare in cash; platform commission is automatically debited in basis
          points from their PHP prepaid credit wallet.
        </p>
      </div>
      <span class="text-xs font-mono text-neutral-500">Default Split: 1500 bps (15.0%)</span>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div
        v-for="tier in commissionTiers"
        :key="tier.id"
        class="bg-white border border-neutral-200 p-6 flex flex-col justify-between space-y-5"
      >
        <div>
          <div class="flex items-center justify-between gap-2">
            <h3 class="font-bold text-neutral-900 text-sm">{{ tier.category }}</h3>
            <span class="font-mono text-[11px] text-neutral-500">{{ tier.rateBps }} bps</span>
          </div>

          <div class="text-3xl font-bold font-mono text-neutral-900 my-4 tabular-nums">
            {{ formatBpsAsPercent(tier.rateBps) }}
            <span class="text-xs font-sans font-normal text-neutral-500">per trip</span>
          </div>

          <p class="text-xs text-neutral-600 mb-4">{{ tier.eligibilityRule }}</p>

          <div class="space-y-2 border-t border-neutral-100 pt-3 text-xs text-neutral-600">
            <div class="flex justify-between">
              <span>Fixed Booking Fee:</span>
              <span class="font-mono font-bold text-neutral-900">
                {{ formatPhp(tier.fixedBookingFeePhp) }}
              </span>
            </div>
            <div class="flex justify-between">
              <span>Min Dispatch Wallet:</span>
              <span class="font-mono font-bold text-neutral-900">
                {{ formatPhp(tier.minWalletBalancePhp) }}
              </span>
            </div>
            <p class="text-[11px] text-neutral-400 pt-1">{{ tier.settlementNote }}</p>
          </div>
        </div>

        <button
          type="button"
          class="w-full py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-medium transition-colors"
          @click="openConfigModal(tier)"
        >
          Configure Rate &amp; Threshold
        </button>
      </div>
    </div>

    <Teleport to="body">
      <div
        v-if="editingTier"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/60 p-4"
        @click.self="closeConfigModal"
      >
        <div
          role="dialog"
          aria-modal="true"
          class="w-full max-w-md bg-white border border-neutral-200 rounded-none p-5 space-y-4 shadow-xl"
        >
          <div class="border-b border-neutral-100 pb-3">
            <h3 class="text-sm font-bold text-neutral-900">
              Configure Commission · {{ editingTier.category }}
            </h3>
            <p class="text-xs text-neutral-500 mt-0.5">
              100 bps equals 1.00% deduction against finalized trip fare.
            </p>
          </div>

          <div class="space-y-3 text-xs">
            <div>
              <label class="block font-medium text-neutral-700 mb-1">
                Commission Rate (Basis Points)
              </label>
              <input
                v-model.number="draftBps"
                type="number"
                min="100"
                max="3500"
                step="50"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
              />
              <span class="text-[11px] text-neutral-500 font-mono">
                Effective cut: {{ formatBpsAsPercent(draftBps) }}
              </span>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block font-medium text-neutral-700 mb-1">
                  Fixed Booking Fee (₱)
                </label>
                <input
                  v-model.number="draftBookingFee"
                  type="number"
                  min="0"
                  step="1"
                  class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
                />
              </div>
              <div>
                <label class="block font-medium text-neutral-700 mb-1">
                  Min Dispatch Wallet (₱)
                </label>
                <input
                  v-model.number="draftMinWallet"
                  type="number"
                  min="0"
                  step="10"
                  class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
                />
              </div>
            </div>

            <div>
              <label class="block font-medium text-neutral-700 mb-1">Qualifying Rule</label>
              <textarea
                v-model="draftRuleText"
                rows="2"
                class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
              />
            </div>

            <p v-if="modalError" class="text-xs font-medium text-rose-700">{{ modalError }}</p>
          </div>

          <div class="flex items-center justify-end gap-2 border-t border-neutral-100 pt-3">
            <button
              type="button"
              class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
              @click="closeConfigModal"
            >
              Cancel
            </button>
            <button
              type="button"
              class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
              @click="saveConfig"
            >
              Save Commission Config
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
