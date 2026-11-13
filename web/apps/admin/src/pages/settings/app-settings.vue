<script setup lang="ts">
import { ref } from 'vue'
import ConfirmDialog from '@/shared/dialogs/ConfirmDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'

const settings = ref({
  biddingWindowSeconds: 90,
  gpsBeaconIntervalSeconds: 5,
  maxBiddingSurgeCap: 2.5,
  ratingBonusThreshold: 4.5,
  ratingBonusMultiplier: 1.05,
  minWalletBalancePhp: 50.0,
  enforceDocumentGate: true,
  enableSurgePricing: true,
  autoLockLowBalanceDispatch: true,
})

const confirmOpen = ref(false)
const auditReason = ref('')
const toastMessage = ref<string | null>(null)

const requestSave = () => {
  auditReason.value = ''
  confirmOpen.value = true
}

const commitSettings = () => {
  if (!auditReason.value.trim()) return
  toastMessage.value = `Saved Pagadian runtime configuration (₱${settings.value.minWalletBalancePhp.toFixed(2)} min wallet, ${settings.value.maxBiddingSurgeCap}x surge cap).`
  confirmOpen.value = false
  auditReason.value = ''
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

    <PageHeader
      title="Preferences"
      description="Configure dispatch timeouts, wallet thresholds, and compliance gates."
    >
      <template #actions>
        <StatusBadge label="Live Bidding Architecture" tone="neutral" />
        <button
          type="button"
          class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold"
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
            <label class="block text-neutral-700 font-medium mb-1">
              Bidding Session Offer Window (Seconds)
            </label>
            <input
              v-model.number="settings.biddingWindowSeconds"
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
            <label class="block text-neutral-700 font-medium mb-1">
              Driver Telemetry Beacon Interval (Seconds)
            </label>
            <input
              v-model.number="settings.gpsBeaconIntervalSeconds"
              type="number"
              min="2"
              max="30"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 rounded-none font-mono text-xs text-neutral-900"
            />
            <p class="text-[11px] text-neutral-400 mt-0.5">
              Real-time coordinate ping cadence across active trips
            </p>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="block text-neutral-700 font-medium mb-1">Max Surge Ceiling (x)</label>
              <input
                v-model.number="settings.maxBiddingSurgeCap"
                type="number"
                min="1"
                max="2.5"
                step="0.1"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 rounded-none font-mono text-xs text-neutral-900"
              />
            </div>
            <div>
              <label class="block text-neutral-700 font-medium mb-1">
                4.5★ Rating Bonus Factor
              </label>
              <input
                v-model.number="settings.ratingBonusMultiplier"
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
            <label class="block text-neutral-700 font-medium mb-1">
              Minimum Driver Wallet Balance for Dispatch (PHP ₱)
            </label>
            <input
              v-model.number="settings.minWalletBalancePhp"
              type="number"
              min="0"
              step="10"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 rounded-none font-mono text-xs text-neutral-900"
            />
            <p class="text-[11px] text-neutral-400 mt-0.5">
              Drivers below ₱{{ settings.minWalletBalancePhp.toFixed(2) }} cannot accept new cash
              bid requests
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
              v-model="settings.enforceDocumentGate"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 rounded-none"
            />
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Dynamic Corridor Surge Multiplier</div>
              <div class="text-[11px] text-neutral-400">
                Allow geofenced demand multipliers up to the 2.5x server cap
              </div>
            </div>
            <input
              v-model="settings.enableSurgePricing"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 rounded-none"
            />
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Auto-Lock Low-Balance Dispatch</div>
              <div class="text-[11px] text-neutral-400">
                Automatically pause bidding eligibility when prepaid balance drops below ₱50.00
              </div>
            </div>
            <input
              v-model="settings.autoLockLowBalanceDispatch"
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
      description="Changes apply immediately to active Pagadian City bidding sessions and prepaid dispatch checks."
      confirm-label="Apply Runtime Settings"
      tone="emerald"
      :require-reason="true"
      reason-label="Mandatory Change Control Note"
      reason-placeholder="e.g., Adjusted peak surge threshold per Pagadian TODA weekly review..."
      @confirm="commitSettings"
      @cancel="confirmOpen = false"
    />
  </div>
</template>
