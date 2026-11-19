<script setup lang="ts">
import { motion } from 'motion-v'
import { RouterLink } from 'vue-router'
import { DriverEarningsCalculator } from '@/features/landing-showcase'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'

const EASE = [0.22, 1, 0.36, 1] as const

const DRIVER_STEPS = [
  { number: '01', title: 'Documents', detail: 'Submit LTO Pro, MTOP, OR/CR, and clearances.' },
  { number: '02', title: 'Top Up', detail: 'Keep at least ₱50 loaded via QRPh anytime.' },
  { number: '03', title: 'Drive', detail: 'Accept nearby bids and collect cash at drop-off.' },
]
</script>

<template>
  <LandingLayout>
    <section class="border-b border-neutral-200/70 bg-neutral-50/70 py-16 sm:py-22">
      <div class="mx-auto max-w-6xl px-5 sm:px-6">
        <motion.div
          :initial="{ opacity: 0, y: 12 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.48, ease: EASE }"
          class="flex flex-col justify-between gap-6 sm:flex-row sm:items-end"
        >
          <div>
            <h1
              class="text-4xl leading-tight font-bold tracking-[-0.035em] text-neutral-950 sm:text-5xl"
            >
              Drive EasyRide
            </h1>
            <p class="mt-3 max-w-lg text-base leading-relaxed text-neutral-500">
              Keep 85%–90% of cash fares in Pagadian City with prepaid QRPh fees.
            </p>
          </div>

          <RouterLink
            :to="{ path: '/download', query: { role: 'driver' } }"
            class="inline-flex min-h-12 w-fit items-center rounded-full bg-neutral-950 px-6 py-3 text-sm font-semibold text-white shadow-[0_8px_20px_-8px_rgba(9,13,22,0.45)] transition-all duration-150 hover:bg-neutral-800 active:scale-[0.98]"
          >
            Get Driver App
          </RouterLink>
        </motion.div>

        <motion.div
          :initial="{ opacity: 0, y: 16 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.52, delay: 0.1, ease: EASE }"
          class="mt-10"
        >
          <DriverEarningsCalculator />
        </motion.div>
      </div>
    </section>

    <section class="bg-white py-20 sm:py-24">
      <div class="mx-auto max-w-6xl px-5 sm:px-6">
        <motion.div
          :initial="{ opacity: 0, y: 12 }"
          :while-in-view="{ opacity: 1, y: 0 }"
          :viewport="{ once: true, amount: 0.3 }"
          :transition="{ duration: 0.45, ease: EASE }"
        >
          <p class="text-[11px] font-bold tracking-[0.14em] text-neutral-400 uppercase">
            Onboarding
          </p>
          <h2 class="mt-2.5 text-2xl font-bold tracking-[-0.025em] text-neutral-950 sm:text-3xl">
            Getting Started
          </h2>
        </motion.div>

        <div class="relative mt-12 grid gap-8 md:grid-cols-3 md:gap-10">
          <div
            class="pointer-events-none absolute top-[1.125rem] right-12 left-12 hidden h-px bg-neutral-200/80 md:block"
            aria-hidden="true"
          />

          <motion.div
            v-for="(item, index) in DRIVER_STEPS"
            :key="item.number"
            :initial="{ opacity: 0, y: 14 }"
            :while-in-view="{ opacity: 1, y: 0 }"
            :viewport="{ once: true, amount: 0.25 }"
            :transition="{ duration: 0.45, delay: index * 0.08, ease: EASE }"
            class="relative"
          >
            <span
              class="relative inline-flex h-9 w-9 items-center justify-center rounded-full border border-neutral-200/90 bg-white font-mono text-xs font-bold tabular-nums text-neutral-900 shadow-[0_1px_2px_rgba(9,13,22,0.04)]"
            >
              {{ item.number }}
            </span>
            <h3 class="mt-5 text-base font-bold tracking-[-0.01em] text-neutral-950">
              {{ item.title }}
            </h3>
            <p class="mt-2 max-w-xs text-sm leading-relaxed text-neutral-500">{{ item.detail }}</p>
          </motion.div>
        </div>
      </div>
    </section>
  </LandingLayout>
</template>
