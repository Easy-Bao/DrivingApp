<script setup lang="ts">
import { ref } from 'vue'
import { formatBpsAsPercent, formatCentavos, ModalDialog, PageHeader, ToastBanner } from '@/shared'
import type { ToastTone } from '@/shared'
import { useCommissionTiers } from '@/features/payments'
import type { CommissionTier } from '@/features/payments'

const { tiers, saveCommissionTier } = useCommissionTiers()

const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('success')
const showEditModal = ref(false)
const activeTier = ref<CommissionTier | null>(null)
const draftRateBps = ref(1500)
const draftFixedFeePhp = ref(0)
const draftMinWalletPhp = ref(50)
const draftEligibilityRule = ref('')
const modalError = ref<string | null>(null)

function openEditModal(tier: CommissionTier) {
  activeTier.value = tier
  draftRateBps.value = tier.rateBps
  draftFixedFeePhp.value = tier.fixedBookingFeeCentavos / 100
  draftMinWalletPhp.value = tier.minWalletBalanceCentavos / 100
  draftEligibilityRule.value = tier.eligibilityRule
  modalError.value = null
  showEditModal.value = true
}

function submitTierUpdate() {
  if (!activeTier.value) return
  const result = saveCommissionTier(activeTier.value.id, {
    rateBps: Number(draftRateBps.value),
    fixedBookingFeeCentavos: Math.round(Number(draftFixedFeePhp.value) * 100),
    minWalletBalanceCentavos: Math.round(Number(draftMinWalletPhp.value) * 100),
    eligibilityRule: draftEligibilityRule.value,
  })
  if (!result.ok) {
    modalError.value = result.error
    return
  }
  showEditModal.value = false
  toastMessage.value = result.message ?? `Updated ${activeTier.value.category}`
  toastTone.value = 'success'
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <PageHeader
      title="Commission Settings"
      description="Configure Bao-Bao platform commission basis points (bps), booking fees, and prepaid wallet minimums."
    />

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <div
        v-for="tier in tiers"
        :key="tier.id"
        class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4"
      >
        <div class="space-y-3">
          <div class="flex items-start justify-between gap-2">
            <div>
              <h2 class="text-sm font-bold text-neutral-900">{{ tier.category }}</h2>
              <p class="text-[11px] font-mono text-neutral-500 mt-0.5">{{ tier.rateBps }} bps</p>
            </div>
            <span class="text-lg font-extrabold font-mono text-neutral-900">
              {{ formatBpsAsPercent(tier.rateBps) }}
            </span>
          </div>

          <div class="grid grid-cols-2 gap-3 text-xs border-y border-neutral-100 py-3">
            <div>
              <div class="text-neutral-500">Fixed Booking Fee</div>
              <div class="font-mono font-semibold text-neutral-900 mt-0.5">
                {{ formatCentavos(tier.fixedBookingFeeCentavos) }}
              </div>
            </div>
            <div>
              <div class="text-neutral-500">Min Dispatch Wallet</div>
              <div class="font-mono font-semibold text-neutral-900 mt-0.5">
                {{ formatCentavos(tier.minWalletBalanceCentavos) }}
              </div>
            </div>
          </div>

          <div class="text-xs space-y-1.5">
            <p class="text-neutral-700 leading-relaxed">{{ tier.eligibilityRule }}</p>
            <p class="text-[11px] text-neutral-500">{{ tier.settlementNote }}</p>
          </div>
        </div>

        <button
          type="button"
          class="w-full py-2 border border-neutral-300 bg-white text-neutral-900 text-xs font-semibold hover:bg-neutral-50 cursor-pointer"
          @click="openEditModal(tier)"
        >
          Configure Rate &amp; Threshold
        </button>
      </div>
    </div>

    <ModalDialog
      v-model:open="showEditModal"
      :title="activeTier ? `Configure ${activeTier.category}` : 'Configure Commission Tier'"
      subtitle="Rates are persisted as integer basis points (100 bps = 1%) to eliminate rounding drift."
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div>
          <label for="commission-bps" class="block font-medium text-neutral-700 mb-1">
            Commission Rate (Basis Points · 100–3500 bps)
          </label>
          <input
            id="commission-bps"
            v-model.number="draftRateBps"
            type="number"
            min="100"
            max="3500"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
          />
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label for="commission-fixed-fee" class="block font-medium text-neutral-700 mb-1">
              Fixed Booking Fee (PHP)
            </label>
            <input
              id="commission-fixed-fee"
              v-model.number="draftFixedFeePhp"
              type="number"
              min="0"
              step="0.5"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="commission-min-wallet" class="block font-medium text-neutral-700 mb-1">
              Min Dispatch Wallet (PHP)
            </label>
            <input
              id="commission-min-wallet"
              v-model.number="draftMinWalletPhp"
              type="number"
              min="0"
              step="10"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white font-mono text-neutral-900"
            />
          </div>
        </div>

        <div>
          <label for="commission-eligibility" class="block font-medium text-neutral-700 mb-1">
            Eligibility Rule
          </label>
          <textarea
            id="commission-eligibility"
            v-model="draftEligibilityRule"
            rows="2"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <p v-if="modalError" class="text-rose-700 font-medium">{{ modalError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-700 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
            @click="showEditModal = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            @click="submitTierUpdate"
          >
            Save Commission Config
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
