<script setup lang="ts">
import { FareEstimatorCard } from '@/features/fare-estimation'
</script>

<template>
  <section id="fare-estimator" class="border-y border-neutral-200 bg-white py-14 sm:py-20">
    <div class="mx-auto grid max-w-6xl items-center gap-10 px-4 sm:px-6 lg:grid-cols-2 lg:gap-16">
      <div>
        <h2 class="text-2xl font-bold tracking-tight text-neutral-900 sm:text-3xl">
          Know your fare first.
        </h2>
        <p class="mt-3 max-w-md text-sm leading-relaxed text-neutral-600 sm:text-base">
          Try a popular Pagadian route and see the starting price before you book.
        </p>
      </div>
      <FareEstimatorCard />
    </div>
  </section>
</template>
