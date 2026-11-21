<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import {
  DEFAULT_APP_SYSTEM_CONFIG,
  useAppSystemConfig,
  useComplianceRules,
  useDispatchPolicy,
  usePricingPolicy,
  useSafetyConfig,
  useVehicleClasses,
  useWalletPolicy,
  validateAppSystemConfig,
  type AppSystemConfig,
} from '@/features/settings'
import { useCommissionTiers, useFarePricing } from '@/features/payments'
import {
  BaseSelect,
  ConfirmDialog,
  PageHeader,
  StatusBadge,
  ToastBanner,
  formatBpsAsPercent,
  formatCentavos,
  useToast,
} from '@/shared'

const { systemConfig, commitSystemConfig, resetSystemDefaults } = useAppSystemConfig()
const { policy: pricingPolicy } = usePricingPolicy()
const { policy: walletPolicy } = useWalletPolicy()
const { policy: dispatchPolicy } = useDispatchPolicy()
const { policy: compliancePolicy, requirements } = useComplianceRules()
const { primaryHotlineLabel } = useSafetyConfig()
const { vehicleClasses } = useVehicleClasses()
const { rules: fareRules } = useFarePricing()
const { defaultStandardRateBps } = useCommissionTiers()

const draft = ref<AppSystemConfig>({ ...systemConfig.value })

watch(
  systemConfig,
  (next) => {
    draft.value = { ...next }
  },
  { deep: true },
)

const confirmOpen = ref(false)
const auditReason = ref('')
const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

const configDirectoryCards = computed(() => [
  {
    title: 'Fare Configuration',
    to: '/config/fare-pricing',
    summary: `${fareRules.value.length} tiers · ${formatCentavos(pricingPolicy.value.baseFareCentavos)} base · ${pricingPolicy.value.maxBiddingSurgeCap.toFixed(1)}x cap`,
  },
  {
    title: 'Commissions',
    to: '/config/commissions',
    summary: `${formatBpsAsPercent(defaultStandardRateBps.value)} standard (${defaultStandardRateBps.value} bps)`,
  },
  {
    title: 'Wallet & Top-Up Rules',
    to: '/config/wallet-rules',
    summary: `${formatCentavos(walletPolicy.value.minWalletBalanceCentavos)} min dispatch · ${formatCentavos(walletPolicy.value.minTopUpAmountCentavos)} min top-up`,
  },
  {
    title: 'Dispatch & Ride Policy',
    to: '/config/dispatch-policy',
    summary: `${dispatchPolicy.value.biddingWindowSeconds}s bid window · ${dispatchPolicy.value.dispatchSearchRadiusKm} km · ${dispatchPolicy.value.arrivalRadiusMeters}m arrival`,
  },
  {
    title: 'Vehicle & Compliance',
    to: '/config/document-rules',
    summary: `${vehicleClasses.value.length} classes · ${requirements.value.filter((d) => d.mandatory && d.isActive).length} mandatory docs · ${compliancePolicy.value.enforceDocumentGate ? 'Gate On' : 'Gate Off'}`,
  },
  {
    title: 'Safety & SOS Config',
    to: '/config/safety-sos',
    summary: `${primaryHotlineLabel.value}`,
  },
])

function requestSave() {
  const error = validateAppSystemConfig(draft.value)
  if (error) {
    showToast(error, 'error')
    return
  }
  auditReason.value = ''
  confirmOpen.value = true
}

function confirmSave() {
  const result = commitSystemConfig(draft.value, auditReason.value)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  confirmOpen.value = false
  auditReason.value = ''
  showToast(result.message ?? 'Saved app and system configuration.', 'success')
}

function handleResetDefaults() {
  resetSystemDefaults()
  draft.value = { ...DEFAULT_APP_SYSTEM_CONFIG }
  showToast('Restored default application & system settings.', 'success')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="App & System"
      description="Manage mobile app minimum version gates, maintenance mode, reporting timezone, and jump to independent configuration modules."
    >
      <template #actions>
        <StatusBadge
          :label="systemConfig.maintenanceMode ? 'Maintenance Active' : 'Normal Operation'"
          :tone="systemConfig.maintenanceMode ? 'danger' : 'success'"
        />
        <button
          id="reset-system-defaults"
          type="button"
          class="px-3 py-2 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-800 text-xs font-medium cursor-pointer"
          @click="handleResetDefaults"
        >
          Reset Defaults
        </button>
        <button
          id="save-system-config"
          type="button"
          class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="requestSave"
        >
          Save System Config
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <!-- Independent Configuration Hub -->
    <section class="space-y-3" aria-labelledby="config-directory-heading">
      <div>
        <h2
          id="config-directory-heading"
          class="text-xs font-bold uppercase tracking-wider text-neutral-700"
        >
          Independent Configuration Modules
        </h2>
        <p class="text-xs text-neutral-500 mt-0.5">
          Pricing, wallet thresholds, dispatch timing, compliance rules, and SOS hotlines are
          managed independently.
        </p>
      </div>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        <RouterLink
          v-for="card in configDirectoryCards"
          :key="card.to"
          :to="card.to"
          class="bg-white border border-neutral-200 p-4 hover:border-neutral-900 transition-colors flex flex-col justify-between gap-2"
        >
          <div class="flex items-center justify-between gap-2">
            <span class="text-xs font-bold text-neutral-900">{{ card.title }}</span>
            <span class="text-[11px] font-semibold text-neutral-500">Configure →</span>
          </div>
          <p class="text-[11px] font-mono text-neutral-600">{{ card.summary }}</p>
        </RouterLink>
      </div>
    </section>

    <!-- App Release & System Controls -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">Regional Identity &amp; Reporting</h2>
        </div>

        <div class="space-y-3 text-xs">
          <div>
            <div class="font-medium text-neutral-700 mb-1">Reporting Timezone</div>
            <BaseSelect
              v-model="draft.reportingTimezone"
              :full-width="true"
              aria-label="Reporting timezone"
              :options="[
                { label: 'Asia/Manila (PHT · UTC+8)', value: 'Asia/Manila' },
                { label: 'Asia/Singapore (SGT · UTC+8)', value: 'Asia/Singapore' },
                { label: 'UTC (Coordinated Universal Time)', value: 'UTC' },
              ]"
            />
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label for="system-support-email" class="block text-neutral-700 font-medium mb-1">
                Support Contact Email
              </label>
              <input
                id="system-support-email"
                v-model="draft.supportEmail"
                type="email"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="system-support-phone" class="block text-neutral-700 font-medium mb-1">
                Support Desk Hotline
              </label>
              <input
                id="system-support-phone"
                v-model="draft.supportPhone"
                type="text"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>

          <div
            class="p-3 bg-neutral-50 border border-neutral-200 flex items-center justify-between"
          >
            <div>
              <div class="font-semibold text-neutral-900">Operating Currency</div>
              <div class="text-[11px] text-neutral-500">
                All fares and wallets are persisted in integer centavos
              </div>
            </div>
            <span class="font-mono font-bold text-neutral-900">PHP (₱)</span>
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">Mobile Release Gates &amp; Maintenance</h2>
        </div>

        <div class="space-y-3 text-xs">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label for="passenger-min-version" class="block text-neutral-700 font-medium mb-1">
                Passenger App Min Version
              </label>
              <input
                id="passenger-min-version"
                v-model="draft.passengerMinVersion"
                type="text"
                placeholder="1.4.0"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="driver-min-version" class="block text-neutral-700 font-medium mb-1">
                Driver App Min Version
              </label>
              <input
                id="driver-min-version"
                v-model="draft.driverMinVersion"
                type="text"
                placeholder="1.4.0"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Enforce Force-Update Gate</div>
              <div class="text-[11px] text-neutral-500">
                Prompt mobile clients below minimum semver to upgrade before booking
              </div>
            </div>
            <input
              v-model="draft.enforceMinAppVersion"
              aria-label="Enforce Force-Update Gate"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Platform Maintenance Mode</div>
              <div class="text-[11px] text-neutral-500">
                Pause new ride requests while allowing in-progress trips to complete
              </div>
            </div>
            <input
              v-model="draft.maintenanceMode"
              aria-label="Platform Maintenance Mode"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>

          <div>
            <label for="maintenance-notice" class="block text-neutral-700 font-medium mb-1">
              Maintenance Notice Banner
            </label>
            <textarea
              id="maintenance-notice"
              v-model="draft.maintenanceNotice"
              rows="2"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 text-neutral-900"
            />
          </div>
        </div>
      </div>
    </div>

    <ConfirmDialog
      v-model:open="confirmOpen"
      v-model:reason="auditReason"
      title="Publish App & System Settings"
      description="Changes apply to mobile version gates, maintenance banners, and reporting configuration."
      confirm-label="Apply System Config"
      :tone="draft.maintenanceMode ? 'rose' : 'emerald'"
      :require-reason="true"
      reason-label="Mandatory Change Control Note"
      reason-placeholder="e.g., Bumped required Flutter client version after security patch..."
      @confirm="confirmSave"
      @cancel="confirmOpen = false"
    />
  </div>
</template>
