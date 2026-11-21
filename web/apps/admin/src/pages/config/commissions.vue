<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink } from 'vue-router'
import {
  formatBpsAsPercent,
  formatCentavos,
  ModalDialog,
  PageHeader,
  StatusBadge,
  ToastBanner,
  useToast,
} from '@/shared'
import { useWalletPolicy } from '@/features/settings'
import { useCommissionTiers, type CommissionTier } from '@/features/payments'

const { tiers, createCommissionTier, saveCommissionTier, toggleCommissionTierActive } =
  useCommissionTiers()
const { policy: walletPolicy } = useWalletPolicy()

const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')
const showEditModal = ref(false)
const activeTier = ref<CommissionTier | null>(null)
const draftCategory = ref('')
const draftRateBps = ref(1500)
const draftFixedFeePhp = ref(0)
const draftMinWalletPhp = ref(50)
const draftEligibilityRule = ref('')
const modalError = ref<string | null>(null)

const activeCount = computed(() => tiers.value.filter((tier) => tier.isActive !== false).length)

function openCreateModal() {
  activeTier.value = null
  draftCategory.value = ''
  draftRateBps.value = 1400
  draftFixedFeePhp.value = 0
  draftMinWalletPhp.value = walletPolicy.value.minWalletBalanceCentavos / 100
  draftEligibilityRule.value = ''
  modalError.value = null
  showEditModal.value = true
}

function openEditModal(tier: CommissionTier) {
  activeTier.value = tier
  draftCategory.value = tier.category
  draftRateBps.value = tier.rateBps
  draftFixedFeePhp.value = tier.fixedBookingFeeCentavos / 100
  draftMinWalletPhp.value = tier.minWalletBalanceCentavos / 100
  draftEligibilityRule.value = tier.eligibilityRule
  modalError.value = null
  showEditModal.value = true
}

function submitTierUpdate() {
  const result = activeTier.value
    ? saveCommissionTier(activeTier.value.id, {
        rateBps: Number(draftRateBps.value),
        fixedBookingFeeCentavos: Math.round(Number(draftFixedFeePhp.value) * 100),
        minWalletBalanceCentavos: Math.round(Number(draftMinWalletPhp.value) * 100),
        eligibilityRule: draftEligibilityRule.value,
      })
    : createCommissionTier({
        category: draftCategory.value,
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
  showToast(
    result.message ?? `Updated ${activeTier.value?.category ?? draftCategory.value}`,
    'success',
  )
}

function handleToggleTier(tier: CommissionTier) {
  const result = toggleCommissionTierActive(tier.id)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(result.message ?? 'Updated tier status.', 'info')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Commissions"
      description="Configure Bao-Bao platform commission basis points (bps), booking fees, and driver incentive tiers."
    >
      <template #actions>
        <span class="text-xs font-mono text-neutral-500">
          {{ activeCount }} Active / {{ tiers.length }} Tiers
        </span>
        <RouterLink
          to="/config/wallet-rules"
          class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-800 text-xs font-medium hover:bg-neutral-50"
        >
          Global Wallet Rules ({{ formatCentavos(walletPolicy.minWalletBalanceCentavos) }})
        </RouterLink>
        <button
          type="button"
          class="px-3.5 py-1.5 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="openCreateModal"
        >
          + Add Commission Tier
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <div
        v-for="tier in tiers"
        :key="tier.id"
        class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4"
      >
        <div class="space-y-3">
          <div class="flex items-start justify-between gap-2">
            <div>
              <div class="flex flex-wrap items-center gap-2">
                <h2 class="text-sm font-bold text-neutral-900">{{ tier.category }}</h2>
                <StatusBadge
                  :label="tier.isActive !== false ? 'Active' : 'Paused'"
                  :tone="tier.isActive !== false ? 'success' : 'neutral'"
                />
              </div>
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
              <div class="text-neutral-500">Tier Wallet Floor</div>
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

        <div class="flex items-center gap-2">
          <button
            type="button"
            class="flex-1 py-2 border border-neutral-300 bg-white text-neutral-900 text-xs font-semibold hover:bg-neutral-50 cursor-pointer"
            @click="openEditModal(tier)"
          >
            Configure Rate &amp; Threshold
          </button>
          <button
            type="button"
            class="px-3 py-2 border border-neutral-200 bg-neutral-50 text-neutral-700 text-xs font-medium hover:bg-neutral-100 cursor-pointer"
            @click="handleToggleTier(tier)"
          >
            {{ tier.isActive !== false ? 'Pause' : 'Activate' }}
          </button>
        </div>
      </div>
    </div>

    <ModalDialog
      v-model:open="showEditModal"
      :title="activeTier ? `Configure ${activeTier.category}` : 'Create Commission Tier'"
      subtitle="Rates are persisted as integer basis points (100 bps = 1%) to eliminate rounding drift."
      size="md"
    >
      <div class="space-y-3 text-xs">
        <div v-if="!activeTier">
          <label for="commission-category" class="block font-medium text-neutral-700 mb-1">
            Commission Tier Title
          </label>
          <input
            id="commission-category"
            v-model="draftCategory"
            type="text"
            placeholder="e.g., Night Shift Incentive Tier"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>

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
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
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
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
            />
          </div>
          <div>
            <label for="commission-min-wallet" class="block font-medium text-neutral-700 mb-1">
              Tier Min Dispatch Wallet (PHP)
            </label>
            <input
              id="commission-min-wallet"
              v-model.number="draftMinWalletPhp"
              type="number"
              min="0"
              step="10"
              class="w-full px-3 py-1.5 border border-neutral-300 bg-white font-mono text-neutral-900"
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
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>

        <p v-if="modalError" role="alert" class="text-rose-700 font-medium">{{ modalError }}</p>
      </div>

      <template #footer>
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
      </template>
    </ModalDialog>
  </div>
</template>
