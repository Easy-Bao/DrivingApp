<script setup lang="ts">
import { ref, watch } from 'vue'
import {
  DEFAULT_DISPATCH_POLICY,
  useDispatchPolicy,
  validateDispatchPolicy,
  type DispatchPolicyConfig,
} from '@/features/settings'
import { ConfirmDialog, PageHeader, ToastBanner, useToast } from '@/shared'

const { policy, commitDispatchPolicy, resetDispatchDefaults } = useDispatchPolicy()
const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

const draft = ref<DispatchPolicyConfig>({ ...policy.value })

watch(
  policy,
  (next) => {
    draft.value = { ...next }
  },
  { deep: true },
)

const confirmOpen = ref(false)
const auditReason = ref('')

function requestSave() {
  const error = validateDispatchPolicy(draft.value)
  if (error) {
    showToast(error, 'error')
    return
  }
  auditReason.value = ''
  confirmOpen.value = true
}

function confirmSave() {
  const result = commitDispatchPolicy(draft.value, auditReason.value)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  confirmOpen.value = false
  auditReason.value = ''
  showToast(result.message ?? 'Saved dispatch policy.', 'success')
}

function handleResetDefaults() {
  resetDispatchDefaults()
  draft.value = { ...DEFAULT_DISPATCH_POLICY }
  showToast('Restored default dispatch and ride lifecycle settings.', 'success')
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Dispatch & Ride Policy"
      description="Configure bidding windows, spatial search radius, passenger bid bounds, GPS telemetry expiry, and geofence arrival radii."
    >
      <template #actions>
        <button
          id="reset-dispatch-defaults"
          type="button"
          class="px-3 py-2 border border-neutral-300 bg-white hover:bg-neutral-50 text-neutral-800 text-xs font-medium cursor-pointer"
          @click="handleResetDefaults"
        >
          Reset Defaults
        </button>
        <button
          id="save-dispatch-policy"
          type="button"
          class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="requestSave"
        >
          Save Dispatch Policy
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">Bidding &amp; Spatial Matching</h2>
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
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
            <p class="text-[11px] text-neutral-500 mt-0.5">
              Duration passengers review driver offers before session expiration
            </p>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label for="dispatch-search-radius" class="block text-neutral-700 font-medium mb-1">
                Spatial Search Radius (km)
              </label>
              <input
                id="dispatch-search-radius"
                v-model.number="draft.dispatchSearchRadiusKm"
                type="number"
                min="1"
                max="25"
                step="0.5"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="dispatch-max-offers" class="block text-neutral-700 font-medium mb-1">
                Max Driver Offers / Session
              </label>
              <input
                id="dispatch-max-offers"
                v-model.number="draft.maxOffersPerSession"
                type="number"
                min="1"
                max="20"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label for="dispatch-bid-floor" class="block text-neutral-700 font-medium mb-1">
                Passenger Bid Floor (% of Est.)
              </label>
              <input
                id="dispatch-bid-floor"
                v-model.number="draft.minPassengerBidPercent"
                type="number"
                min="50"
                max="100"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="dispatch-bid-ceiling" class="block text-neutral-700 font-medium mb-1">
                Passenger Bid Ceiling (% of Est.)
              </label>
              <input
                id="dispatch-bid-ceiling"
                v-model.number="draft.maxPassengerBidPercent"
                type="number"
                min="100"
                max="250"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Allow Manual Dispatcher Override</div>
              <div class="text-[11px] text-neutral-500">
                Permit Fleet operators to manually assign or reassign drivers from Live Dispatch
              </div>
            </div>
            <input
              v-model="draft.allowManualDispatchOverride"
              aria-label="Allow Manual Dispatcher Override"
              type="checkbox"
              class="h-4 w-4 accent-neutral-900 cursor-pointer"
            />
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">
            Telemetry, Geofence &amp; No-Show Gates
          </h2>
        </div>

        <div class="space-y-3 text-xs">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label for="gps-beacon-interval" class="block text-neutral-700 font-medium mb-1">
                Driver GPS Ping Interval (Sec)
              </label>
              <input
                id="gps-beacon-interval"
                v-model.number="draft.gpsBeaconIntervalSeconds"
                type="number"
                min="2"
                max="60"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="driver-location-max-age" class="block text-neutral-700 font-medium mb-1">
                Stale GPS Eviction Age (Sec)
              </label>
              <input
                id="driver-location-max-age"
                v-model.number="draft.driverLocationMaxAgeSeconds"
                type="number"
                min="15"
                max="300"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>

          <div>
            <label for="passenger-noshow-wait" class="block text-neutral-700 font-medium mb-1">
              Passenger No-Show Grace Wait (Minutes)
            </label>
            <input
              id="passenger-noshow-wait"
              v-model.number="draft.passengerNoShowWaitMinutes"
              type="number"
              min="1"
              max="30"
              class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
            />
            <p class="text-[11px] text-neutral-500 mt-0.5">
              Minimum waiting time at pickup curb before driver can submit a passenger no-show
            </p>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label for="arrival-radius-meters" class="block text-neutral-700 font-medium mb-1">
                Arrival Geofence Radius (m)
              </label>
              <input
                id="arrival-radius-meters"
                v-model.number="draft.arrivalRadiusMeters"
                type="number"
                min="50"
                max="1000"
                step="25"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
            <div>
              <label for="completion-radius-meters" class="block text-neutral-700 font-medium mb-1">
                Completion Geofence Radius (m)
              </label>
              <input
                id="completion-radius-meters"
                v-model.number="draft.completionRadiusMeters"
                type="number"
                min="50"
                max="1000"
                step="25"
                class="w-full px-3 py-1.5 bg-white border border-neutral-300 font-mono text-neutral-900"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <ConfirmDialog
      v-model:open="confirmOpen"
      v-model:reason="auditReason"
      title="Publish Dispatch & Ride Policy"
      description="Changes apply to new bidding sessions, driver spatial matching, and ride geofence validation."
      confirm-label="Apply Dispatch Policy"
      tone="emerald"
      :require-reason="true"
      reason-label="Mandatory Change Control Note"
      reason-placeholder="e.g., Widened arrival radius for steep hillside barangays..."
      @confirm="confirmSave"
      @cancel="confirmOpen = false"
    />
  </div>
</template>
