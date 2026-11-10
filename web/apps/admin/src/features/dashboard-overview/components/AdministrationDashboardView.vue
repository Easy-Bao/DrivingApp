<script setup lang="ts">
import { onMounted } from 'vue'
import { useAdministrationDashboard } from '@/features/dashboard-overview/composables/useAdministrationDashboard'

const { isLoading, metrics, loadMetrics } = useAdministrationDashboard()

onMounted(() => {
  void loadMetrics()
})
</script>

<template>
  <section class="p-6">
    <h1 class="text-2xl font-bold mb-4">Administration Overview</h1>
    <div v-if="isLoading" class="text-neutral-500">Loading overview metrics...</div>
    <div v-else-if="metrics" class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="p-4 rounded-lg border border-neutral-200">
        <span class="text-sm text-neutral-600">Active Rides</span>
        <p class="text-xl font-semibold">{{ metrics.activeRidesCount }}</p>
      </div>
      <div class="p-4 rounded-lg border border-neutral-200">
        <span class="text-sm text-neutral-600">Online Drivers</span>
        <p class="text-xl font-semibold">{{ metrics.onlineDriversCount }}</p>
      </div>
      <div class="p-4 rounded-lg border border-neutral-200">
        <span class="text-sm text-neutral-600">System Status</span>
        <p class="text-xl font-semibold capitalize">{{ metrics.systemHealthStatus }}</p>
      </div>
    </div>
  </section>
</template>
