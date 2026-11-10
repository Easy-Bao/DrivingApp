<script setup lang="ts">
import { FareEstimatorCard } from '@/features/fare-estimation'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'
</script>

<template>
  <LandingLayout>
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
      <div>
        <h1 class="text-4xl font-extrabold text-neutral-900 tracking-tight sm:text-5xl mb-4">
          Seamless, reliable rides at your fingertips.
        </h1>
        <p class="text-lg text-neutral-600 mb-8 leading-relaxed">
          Experience low-latency dispatching, upfront fare transparency, and real-time ride tracking
          with EasyRide.
        </p>
      </div>
      <div>
        <FareEstimatorCard />
      </div>
    </div>
  </LandingLayout>
</template>
