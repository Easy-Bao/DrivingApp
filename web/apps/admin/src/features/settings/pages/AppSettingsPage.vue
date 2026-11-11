<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const settings = ref({
  maxDispatchRadiusKm: 8,
  driverAcceptanceTimeoutSec: 25,
  minWalletBalanceForDispatch: 5.0,
  gpsTelemetryIntervalSec: 3,
  autoCancelTimeoutSec: 180,
  enableSurgePricing: true,
  enableScheduledRides: true,
  maintenanceMode: false,
})

const actionToast = ref<string | null>(null)

function saveSettings() {
  actionToast.value = 'Global application settings updated and broadcasted to dispatch clusters.'
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Global Application & Dispatch Parameters
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Configure real-time dispatch radii, driver timeout windows, minimum wallet balances, and
          GPS intervals.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors flex items-center space-x-2"
        @click="saveSettings"
      >
        <span>Save Configuration</span>
      </button>
    </div>

    <div
      v-if="actionToast"
      class="p-4 bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- Dispatch & Matching Engine -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center space-x-2.5 pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">Dispatch & Telemetry Parameters</h2>
        </div>

        <div class="space-y-3 text-xs">
          <div>
            <label class="block text-neutral-700 font-medium mb-1"
              >Max Dispatch Search Radius (km)</label
            >
            <input
              v-model.number="settings.maxDispatchRadiusKm"
              type="number"
              class="w-full px-3 py-1.5 bg-neutral-50 border border-neutral-200 font-mono text-xs"
            />
            <p class="text-[11px] text-neutral-400 mt-0.5">
              Maximum radius to search for online drivers
            </p>
          </div>

          <div>
            <label class="block text-neutral-700 font-medium mb-1"
              >Driver Response Timeout (seconds)</label
            >
            <input
              v-model.number="settings.driverAcceptanceTimeoutSec"
              type="number"
              class="w-full px-3 py-1.5 bg-neutral-50 border border-neutral-200 font-mono text-xs"
            />
            <p class="text-[11px] text-neutral-400 mt-0.5">
              Window for driver to accept ride offer before auto-reassigning
            </p>
          </div>

          <div>
            <label class="block text-neutral-700 font-medium mb-1"
              >GPS Telemetry Interval (seconds)</label
            >
            <input
              v-model.number="settings.gpsTelemetryIntervalSec"
              type="number"
              class="w-full px-3 py-1.5 bg-neutral-50 border border-neutral-200 font-mono text-xs"
            />
            <p class="text-[11px] text-neutral-400 mt-0.5">
              Driver app coordinate beacon transmit cadence
            </p>
          </div>
        </div>
      </div>

      <!-- Financial & System Controls -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center space-x-2.5 pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">Wallet Controls & Features</h2>
        </div>

        <div class="space-y-3 text-xs">
          <div>
            <label class="block text-neutral-700 font-medium mb-1"
              >Minimum Driver Wallet Balance ($)</label
            >
            <input
              v-model.number="settings.minWalletBalanceForDispatch"
              type="number"
              step="0.5"
              class="w-full px-3 py-1.5 bg-neutral-50 border border-neutral-200 font-mono text-xs"
            />
            <p class="text-[11px] text-neutral-400 mt-0.5">
              Drivers below this balance cannot receive new dispatch offers
            </p>
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Dynamic Surge Pricing</div>
              <div class="text-[11px] text-neutral-400">Enable automatic demand multipliers</div>
            </div>
            <input
              v-model="settings.enableSurgePricing"
              type="checkbox"
              class=" text-neutral-900"
            />
          </div>

          <div class="flex items-center justify-between py-2 border-t border-neutral-100">
            <div>
              <div class="font-medium text-neutral-900">Advance Scheduled Bookings</div>
              <div class="text-[11px] text-neutral-400">
                Allow riders to schedule up to 7 days ahead
              </div>
            </div>
            <input
              v-model="settings.enableScheduledRides"
              type="checkbox"
              class=" text-neutral-900"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
