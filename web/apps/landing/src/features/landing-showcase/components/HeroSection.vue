<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { FareEstimatorCard } from '@/features/fare-estimation'
import { HERO_STATS } from '@/features/landing-showcase/data/landingContent'
</script>

<template>
  <section
    id="fare-estimator"
    class="border-b border-neutral-200 bg-neutral-50 py-12 sm:py-16 lg:py-20"
  >
    <div class="mx-auto max-w-6xl px-4 sm:px-6">
      <div class="grid items-center gap-10 lg:grid-cols-12 lg:gap-12">
        <div class="lg:col-span-6">
          <h1 class="text-4xl font-bold tracking-tight text-neutral-900 sm:text-5xl">
            Pagadian Rides.
          </h1>

          <p class="mt-4 max-w-md text-base leading-relaxed text-neutral-600 sm:text-lg">
            Check upfront Taxicle fares and pick a nearby driver without street haggling.
          </p>

          <div class="mt-7 flex flex-wrap items-center gap-3">
            <RouterLink
              to="/download"
              class="inline-flex min-h-11 items-center bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-neutral-800"
            >
              Get App
            </RouterLink>
            <RouterLink
              to="/drive"
              class="inline-flex min-h-11 items-center border border-neutral-300 bg-white px-5 py-2.5 text-sm font-semibold text-neutral-900 transition-colors hover:bg-neutral-100"
            >
              Drive EasyRide
            </RouterLink>
          </div>

          <dl class="mt-10 grid grid-cols-3 gap-6 border-t border-neutral-200 pt-6">
            <div v-for="stat in HERO_STATS" :key="stat.label">
              <dt class="text-xs font-medium text-neutral-500">{{ stat.label }}</dt>
              <dd class="mt-1 text-xl font-bold tabular-nums text-neutral-900 sm:text-2xl">
                {{ stat.value }}
              </dd>
            </div>
          </dl>
        </div>

        <div class="lg:col-span-6">
          <FareEstimatorCard />
        </div>
      </div>
    </div>
  </section>
</template>
