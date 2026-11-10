<script setup lang="ts">
import { PlatformArchitectureExplorer } from '@/features/platform-architecture'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'
</script>

<template>
  <LandingLayout>
    <div class="space-y-6">
      <div>
        <h1 class="text-3xl font-bold text-neutral-900 mb-2">Platform Infrastructure</h1>
        <p class="text-neutral-600">
          Modular microservices, high-throughput WebSockets, and low-latency geospatial matching.
        </p>
      </div>
      <PlatformArchitectureExplorer />
    </div>
  </LandingLayout>
</template>
