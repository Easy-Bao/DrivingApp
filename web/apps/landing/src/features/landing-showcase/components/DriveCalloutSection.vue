<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <section class="bg-[#090d16] py-14 text-white sm:py-16">
    <div
      class="mx-auto flex max-w-6xl flex-col items-start justify-between gap-6 px-4 sm:flex-row sm:items-center sm:px-6"
    >
      <div>
        <h2 class="text-2xl font-bold tracking-tight text-white sm:text-3xl">Drive EasyRide</h2>
        <p class="mt-2 max-w-md text-sm text-neutral-300">
          Keep 85%–90% of cash fares across Pagadian with prepaid wallet top-ups.
        </p>
      </div>

      <RouterLink
        to="/drive"
        class="inline-flex min-h-11 shrink-0 items-center bg-white px-5 py-2.5 text-sm font-semibold text-neutral-900 transition-colors hover:bg-neutral-200"
      >
        Start Driving
      </RouterLink>
    </div>
  </section>
</template>
