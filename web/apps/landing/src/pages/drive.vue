<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { DriverEarningsCalculator } from '@/features/landing-showcase'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'

const DRIVER_STEPS = [
  { number: '01', title: 'Documents', detail: 'Submit LTO Pro, MTOP, OR/CR, and clearances.' },
  { number: '02', title: 'Top Up', detail: 'Keep at least ₱50 loaded via QRPh anytime.' },
  { number: '03', title: 'Drive', detail: 'Accept nearby bids and collect cash at drop-off.' },
]
</script>

<template>
  <LandingLayout>
    <section class="border-b border-neutral-200 bg-neutral-50 py-14 sm:py-16">
      <div class="mx-auto max-w-6xl px-4 sm:px-6">
        <div class="flex flex-col justify-between gap-6 sm:flex-row sm:items-end">
          <div>
            <h1 class="text-4xl font-bold tracking-tight text-neutral-900 sm:text-5xl">
              Drive EasyRide
            </h1>
            <p class="mt-3 max-w-lg text-base text-neutral-600">
              Keep 85%–90% of cash fares in Pagadian City with prepaid QRPh fees.
            </p>
          </div>

          <RouterLink
            :to="{ path: '/download', query: { role: 'driver' } }"
            class="inline-flex min-h-11 w-fit items-center bg-neutral-900 px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-neutral-800"
          >
            Get Driver App
          </RouterLink>
        </div>

        <div class="mt-10">
          <DriverEarningsCalculator />
        </div>
      </div>
    </section>

    <section class="bg-white py-14 sm:py-16">
      <div class="mx-auto max-w-6xl px-4 sm:px-6">
        <h2 class="text-2xl font-bold tracking-tight text-neutral-900">Getting Started</h2>

        <div class="mt-8 grid gap-8 md:grid-cols-3">
          <div v-for="item in DRIVER_STEPS" :key="item.number">
            <span class="font-mono text-xs font-bold tabular-nums text-neutral-500">
              {{ item.number }}
            </span>
            <h3 class="mt-2 text-base font-bold text-neutral-900">{{ item.title }}</h3>
            <p class="mt-1.5 text-sm text-neutral-600">{{ item.detail }}</p>
          </div>
        </div>
      </div>
    </section>
  </LandingLayout>
</template>
