<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const commissionSettings = ref([
  {
    tier: 'Standard Fleet (Combustion / Hybrid)',
    rate: 15,
    description:
      'Default platform commission deducted from driver prepaid wallet per completed ride.',
    activeDrivers: 840,
  },
  {
    tier: 'Green Fleet (100% Electric Vehicle)',
    rate: 10,
    description:
      'Reduced commission incentive to encourage eco-friendly zero-emission fleet transition.',
    activeDrivers: 420,
  },
  {
    tier: 'Top Chauffeur Executive Program',
    rate: 18,
    description: 'Covers high-touch concierge dispatch, VIP marketing, and airport gate permits.',
    activeDrivers: 160,
  },
])

const actionToast = ref<string | null>(null)

function updateCommission() {
  actionToast.value = 'Platform commission rate settings updated successfully.'
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
          Platform Commission Settings
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Configure platform service fee deductions taken automatically from driver prepaid wallet
          upon ride completion.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors flex items-center space-x-2"
        @click="updateCommission"
      >
        <span>Save Commission Rates</span>
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

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div
        v-for="c in commissionSettings"
        :key="c.tier"
        class="bg-white border border-neutral-200 p-5 space-y-3 flex flex-col justify-between"
      >
        <div>
          <div class="flex items-center justify-between">
            <h3 class="font-bold text-sm text-neutral-900">{{ c.tier }}</h3>
            <span
              class="px-2.5 py-1 bg-neutral-900 text-white font-mono font-bold text-sm"
            >
              {{ c.rate }}%
            </span>
          </div>
          <p class="text-xs text-neutral-500 mt-2">{{ c.description }}</p>
        </div>

        <div
          class="pt-3 border-t border-neutral-100 flex items-center justify-between text-xs text-neutral-400"
        >
          <span>Active in tier: {{ c.activeDrivers }} drivers</span>
          <button type="button" class="text-neutral-900 font-semibold hover:underline">
            Configure →
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
