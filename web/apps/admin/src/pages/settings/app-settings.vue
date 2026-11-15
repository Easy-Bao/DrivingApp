<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import {
  DEFAULT_PLATFORM_CONFIG,
  clonePlatformConfig,
  usePlatformConfig,
  validatePlatformConfig,
  type PlatformConfig,
} from '@/features/settings'
import { ConfirmDialog, PageHeader, StatusBadge, ToastBanner, formatCentavos } from '@/shared'

const { config, commitConfig, resetToDefaults } = usePlatformConfig()

const draft = ref<PlatformConfig>(clonePlatformConfig(config.value))
const minWalletPhp = ref(draft.value.minWalletBalanceCentavos / 100)

watch(
  config,
  (next) => {
    draft.value = clonePlatformConfig(next)
    minWalletPhp.value = next.minWalletBalanceCentavos / 100
  },
  { deep: true },
)

const draftMinWalletCentavos = computed(() =>
  Number.isFinite(minWalletPhp.value) ? Math.round(minWalletPhp.value * 100) : -1,
)

const draftPayload = computed<PlatformConfig>(() => ({
  ...draft.value,
  minWalletBalanceCentavos: draftMinWalletCentavos.value,
}))

const ratingThresholdLabel = computed(() =>
  Number.isFinite(draft.value.ratingBonusThreshold)
    ? `${draft.value.ratingBonusThreshold.toFixed(1)}★ Rating Bonus Factor`
    : 'Rating Bonus Factor',
)

const formattedMinBalance = computed(() =>
  draftMinWalletCentavos.value >= 0 ? formatCentavos(draftMinWalletCentavos.value) : '₱0.00',
)

const validationError = ref<string | null>(null)
const auditReason = ref('')
const confirmOpen = ref(false)
const toastMessage = ref<string | null>(null)

const requestSave = () => {
  validationError.value = validatePlatformConfig(draftPayload.value)
  if (validationError.value) return
  auditReason.value = ''
  confirmOpen.value = true
}

const commitSettings = () => {
  const result = commitConfig(draftPayload.value, auditReason.value)
  if (!result.ok) {
    validationError.value = result.error
    return
  }
  toastMessage.value = `Saved platform configuration (${formatCentavos(config.value.minWalletBalanceCentavos)} min wallet, ${config.value.maxBiddingSurgeCap}x surge cap).`
  confirmOpen.value = false
  auditReason.value = ''
  validationError.value = null
}

const handleResetDefaults = () => {
  resetToDefaults()
  draft.value = clonePlatformConfig(DEFAULT_PLATFORM_CONFIG)
  minWalletPhp.value = DEFAULT_PLATFORM_CONFIG.minWalletBalanceCentavos / 100
  validationError.value = null
  toastMessage.value = 'Restored default platform configuration.'
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

    <ToastBanner
      v-if="validationError"
      :message="validationError"
      tone="error"
      @dismiss="validationError = null"
    />

    <PageHeader
      title="Preferences"
      description="Configure dispatch timeouts, wallet thresholds, and compliance gates."
    >
      <template #actions>
        <StatusBadge label="Live Bidding Architecture" tone="neutral" />
        <button
          id="reset-runtime-defaults"
          type="button"
          class="px-3 py-2 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-800 rounded-none text-xs font-medium cursor-pointer"
          @click="handleResetDefaults"
        >
          Reset Defaults
        </button>
        <button
          id="save-runtime-config"
          type="button"
          class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold cursor-pointer"
          @click="requestSave"
        >
          Save Runtime Configuration
        </button>
      </template>
    </PageHeader>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="pb-3 border-b border-neutral-100">
          <h3 class="font-bold text-sm text-neutral-900">Bidding Engine &amp; Telemetry Timing</h3>
        </div>

        <div class="space-y-3 text-xs">
          <div>
            <label for="bidding-window-seconds" class="block text-neutral-700 font-medium mb-1">
              Bidding Session Offer Window (Seconds)
            </label>
            <input
              id="bidding-window-seconds"
              v-model.number="draft.biddingWindowSeconds"
              type="number"
              min="30"
              max="300"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 rounded-none font-mono text-xs text-neutral-900"
            />
            <p class="text-[11px] text-neutral-400 mt-0.5">
              Duration passengers review driver offers before session expiration
            </p>
          </div>

          <div>
            <label for="gps-beacon-interval" class="block text-neutral-700 font-medium mb-1">
              Driver Telemetry Beacon Interval (Seconds)
            </label>
            <input
              id="gps-beacon-interval"
              v-model.number="draft.gpsBeaconIntervalSeconds"
              type="number"
              min="2"
              max="60"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 rounded-none font-mono text-xs text-neutral-900"
            />
            <p class="text-[11px] text-neutral-400 mt-0.5">
              Real-time coordinate ping cadence across active trips
            </p>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label for="max-bidding-surge" class="block text-neutral-700 font-medium mb-1">
                Max Surge Ceiling (x)
              </label>
              <input
                id="max-bidding-surge"
                v-model.number="draft.maxBiddingSurgeCap"
                type="number"
                min="1"
                max="2.5"
                step="0.1"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 rounded-none font-mono text-xs text-neutral-900"
              />
            </div>
            <div>
              <label for="rating-bonus-threshold" class="block text-neutral-700 font-medium mb-1">
                Rating Bonus Min (★)
              </label>
              <input
                id="rating-bonus-threshold"
                v-model.number="draft.ratingBonusThreshold"
                type="number"
                min="1"
                max="5"
                step="0.1"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 rounded-none font-mono text-xs text-neutral-900"
              />
            </div>
            <div>
              <label for="rating-bonus-multiplier" class="block text-neutral-700 font-medium mb-1">
                {{ ratingThresholdLabel }}
              </label>
              <input
                id="rating-bonus-multiplier"
                v-model.number="draft.ratingBonusMultiplier"
                type="number"
                min="1"
                max="1.2"
                step="0.01"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 rounded-none font-mono text-xs text-neutral-900"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="pb-3 border-b border-neutral-100">
          <h3 class="font-bold text-sm text-neutral-900">Prepaid Wallet &amp; Compliance Gates</h3>
        </div>

        <div class="space-y-3 text-xs">
          <div>
            <label for="min-wallet-balance" class="block text-neutral-700 font-medium mb-1">
              Minimum Driver Wallet Balance for Dispatch (PHP ₱)
            </label>
            <input
              id="min-wallet-balance"
              v-model.number="minWalletPhp"
              type="number"
              min="0"
              step="10"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 rounded-none font-mono text-xs text-neutral-900"
            />
            <p class="text-[11px] text-neutral-400 mt-0.5">
              Drivers below {{ formattedMinBalance }} cannot accept new cash bid requests
            </p>
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Enforce LTO &amp; TODA Document Gate</div>
              <div class="text-[11px] text-neutral-400">
                Block dispatch when driver license, OR/CR, or MTOP expires
              </div>
            </div>
            <input
              v-model="draft.enforceDocumentGate"
              aria-label="Enforce LTO and TODA Document Gate"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 rounded-none"
            />
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Dynamic Corridor Surge Multiplier</div>
              <div class="text-[11px] text-neutral-400">
                Allow geofenced demand multipliers up to the
                {{ draft.maxBiddingSurgeCap.toFixed(1) }}x server cap
              </div>
            </div>
            <input
              v-model="draft.enableSurgePricing"
              aria-label="Dynamic Corridor Surge Multiplier"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 rounded-none"
            />
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Auto-Lock Low-Balance Dispatch</div>
              <div class="text-[11px] text-neutral-400">
                Automatically pause bidding eligibility when prepaid balance drops below
                {{ formattedMinBalance }}
              </div>
            </div>
            <input
              v-model="draft.autoLockLowBalanceDispatch"
              aria-label="Auto-Lock Low-Balance Dispatch"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 rounded-none"
            />
          </div>
        </div>
      </div>
    </div>

    <ConfirmDialog
      v-model:open="confirmOpen"
      v-model:reason="auditReason"
      title="Publish Runtime Configuration Changes"
      description="Changes apply immediately to active bidding sessions and prepaid dispatch checks."
      confirm-label="Apply Runtime Settings"
      tone="emerald"
      :require-reason="true"
      reason-label="Mandatory Change Control Note"
      reason-placeholder="e.g., Adjusted peak surge threshold per weekly review..."
      @confirm="commitSettings"
      @cancel="confirmOpen = false"
    />
  </div>
</template>
