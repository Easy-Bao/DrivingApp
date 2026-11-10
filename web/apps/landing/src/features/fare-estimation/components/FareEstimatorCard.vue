<script setup lang="ts">
import { useFareEstimation } from '@/features/fare-estimation/composables/useFareEstimation'

const { request, estimate, isCalculating, estimateFare } = useFareEstimation()
</script>

<template>
  <div class="rounded-xl border border-neutral-200 bg-white p-6 shadow-sm">
    <h3 class="text-lg font-semibold text-neutral-900 mb-4">Estimate Your Trip</h3>
    <div class="space-y-4">
      <div>
        <label class="block text-xs font-medium text-neutral-600 mb-1">Pickup</label>
        <input
          v-model="request.pickupLocation"
          type="text"
          placeholder="Enter pickup point"
          class="w-full px-3 py-2 border border-neutral-300 rounded-md text-sm"
        />
      </div>
      <div>
        <label class="block text-xs font-medium text-neutral-600 mb-1">Destination</label>
        <input
          v-model="request.destinationLocation"
          type="text"
          placeholder="Where to?"
          class="w-full px-3 py-2 border border-neutral-300 rounded-md text-sm"
        />
      </div>
      <button
        type="button"
        :disabled="isCalculating"
        class="w-full py-2 px-4 bg-neutral-900 text-white text-sm font-medium rounded-md hover:bg-neutral-800 disabled:opacity-50"
        @click="estimateFare"
      >
        {{ isCalculating ? 'Calculating...' : 'Get Fare Estimate' }}
      </button>

      <div v-if="estimate" class="mt-4 pt-4 border-t border-neutral-100 flex justify-between">
        <span class="text-sm text-neutral-600">Estimated Fare</span>
        <span class="text-sm font-bold text-neutral-900">
          ${{ (estimate.estimatedFareCents / 100).toFixed(2) }}
        </span>
      </div>
    </div>
  </div>
</template>
