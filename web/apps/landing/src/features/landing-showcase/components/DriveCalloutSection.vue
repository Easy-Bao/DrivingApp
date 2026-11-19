<script setup lang="ts">
import { motion } from 'motion-v'
import { RouterLink } from 'vue-router'

const EASE = [0.22, 1, 0.36, 1] as const
</script>

<template>
  <section class="bg-white py-6 sm:py-10">
    <div class="mx-auto max-w-6xl px-5 sm:px-6">
      <motion.div
        :initial="{ opacity: 0, y: 16 }"
        :while-in-view="{ opacity: 1, y: 0 }"
        :viewport="{ once: true, amount: 0.25 }"
        :transition="{ duration: 0.5, ease: EASE }"
        class="relative overflow-hidden rounded-3xl bg-[#090d16] px-7 py-12 text-white shadow-[0_24px_60px_-24px_rgba(9,13,22,0.45)] ring-1 ring-inset ring-white/10 sm:px-12 sm:py-14 lg:px-14"
      >
        <div
          class="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_60%_70%_at_92%_10%,rgba(5,150,105,0.18),transparent_62%)]"
          aria-hidden="true"
        />

        <div
          class="relative flex flex-col items-start justify-between gap-8 sm:flex-row sm:items-center"
        >
          <div class="max-w-lg">
            <p class="text-[11px] font-bold tracking-[0.14em] text-neutral-400 uppercase">
              For Drivers
            </p>
            <h2 class="mt-2.5 text-2xl font-bold tracking-[-0.025em] text-white sm:text-3xl">
              Drive EasyRide
            </h2>
            <p class="mt-3 text-sm leading-relaxed text-neutral-300 sm:text-base">
              Keep 85%–90% of cash fares across Pagadian with prepaid wallet top-ups.
            </p>

            <div
              class="mt-5 flex flex-wrap items-center gap-x-4 gap-y-1.5 text-xs text-neutral-400"
            >
              <span>QRPh top-ups from ₱50</span>
              <span class="h-1 w-1 rounded-full bg-neutral-700" aria-hidden="true" />
              <span>10%–15% commission tiers</span>
            </div>
          </div>

          <RouterLink
            to="/drive"
            class="inline-flex min-h-12 shrink-0 items-center rounded-full bg-white px-6 py-3 text-sm font-semibold text-neutral-950 shadow-[0_6px_20px_-6px_rgba(255,255,255,0.3)] transition-all duration-150 hover:bg-neutral-100 active:scale-[0.98]"
          >
            Start Driving
          </RouterLink>
        </div>
      </motion.div>
    </div>
  </section>
</template>
