<script setup lang="ts">
import PlatformArchitectureExplorer from '@/features/platform-architecture/components/PlatformArchitectureExplorer.vue'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'
</script>

<template>
  <LandingLayout>
    <section class="py-14 sm:py-16">
      <div class="mx-auto max-w-6xl px-4 sm:px-6">
        <h1 class="text-3xl font-bold tracking-tight text-neutral-900 sm:text-4xl">
          System Architecture
        </h1>
        <p class="mt-2 max-w-xl text-sm text-neutral-600 sm:text-base">
          Overview of the gateway, core dispatch, and real-time bidding components.
        </p>

        <div class="mt-8">
          <PlatformArchitectureExplorer />
        </div>
      </div>
    </section>
  </LandingLayout>
</template>
