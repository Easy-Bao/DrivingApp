<script setup lang="ts">
import { motion } from 'motion-v'
import { FareEstimatorCard } from '@/features/fare-estimation'

const EASE = [0.22, 1, 0.36, 1] as const

const FARE_HIGHLIGHTS = [
  'Flag-down starts at ₱25 across Poblacion',
  'Built-in peak surge caps for uphill corridors',
  'Exact cash fare agreed before pickup',
]
</script>

<template>
  <section id="fare-estimator" class="bg-white py-20 sm:py-28">
    <div class="mx-auto grid max-w-6xl items-center gap-12 px-5 sm:px-6 lg:grid-cols-12 lg:gap-16">
      <motion.div
        :initial="{ opacity: 0, y: 14 }"
        :while-in-view="{ opacity: 1, y: 0 }"
        :viewport="{ once: true, amount: 0.25 }"
        :transition="{ duration: 0.5, ease: EASE }"
        class="lg:col-span-5"
      >
        <p class="text-[11px] font-bold tracking-[0.14em] text-neutral-400 uppercase">
          Fare Preview
        </p>
        <h2
          class="mt-2.5 text-2xl font-bold tracking-[-0.025em] text-neutral-950 sm:text-3xl lg:text-[2.125rem] lg:leading-tight"
        >
          Know your fare first.
        </h2>
        <p class="mt-3.5 max-w-md text-sm leading-relaxed text-neutral-500 sm:text-base">
          Try a popular Pagadian route and see the starting price before you book.
        </p>

        <ul class="mt-8 space-y-2.5 border-t border-neutral-200/75 pt-6 text-sm text-neutral-600">
          <li v-for="point in FARE_HIGHLIGHTS" :key="point" class="flex items-center gap-3">
            <span class="h-px w-3 shrink-0 bg-neutral-300" aria-hidden="true" />
            <span>{{ point }}</span>
          </li>
        </ul>
      </motion.div>

      <motion.div
        :initial="{ opacity: 0, y: 18 }"
        :while-in-view="{ opacity: 1, y: 0 }"
        :viewport="{ once: true, amount: 0.2 }"
        :transition="{ duration: 0.55, delay: 0.08, ease: EASE }"
        class="lg:col-span-7"
      >
        <FareEstimatorCard />
      </motion.div>
    </div>
  </section>
</template>
