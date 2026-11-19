<script setup lang="ts">
import { motion } from 'motion-v'
import { triggerFarePrefill } from '@/features/fare-estimation'
import { FLEET_TIERS } from '@/features/landing-showcase/data/landingContent'

const EASE = [0.22, 1, 0.36, 1] as const
</script>

<template>
  <section id="rides" class="border-b border-neutral-200/70 bg-neutral-50/70 py-20 sm:py-24">
    <div class="mx-auto max-w-6xl px-5 sm:px-6">
      <motion.div
        :initial="{ opacity: 0, y: 12 }"
        :while-in-view="{ opacity: 1, y: 0 }"
        :viewport="{ once: true, amount: 0.3 }"
        :transition="{ duration: 0.45, ease: EASE }"
        class="flex flex-col justify-between gap-2 sm:flex-row sm:items-end"
      >
        <div>
          <p class="text-[11px] font-bold tracking-[0.14em] text-neutral-400 uppercase">Fleet</p>
          <h2 class="mt-2.5 text-2xl font-bold tracking-[-0.025em] text-neutral-950 sm:text-3xl">
            Our Rides
          </h2>
        </div>
        <p class="text-sm text-neutral-500">Three Taxicle tiers priced in PHP.</p>
      </motion.div>

      <div class="mt-10 grid gap-5 md:grid-cols-3">
        <motion.article
          v-for="(tier, index) in FLEET_TIERS"
          :key="tier.id"
          :initial="{ opacity: 0, y: 16 }"
          :while-in-view="{ opacity: 1, y: 0 }"
          :while-hover="{ y: -3 }"
          :viewport="{ once: true, amount: 0.25 }"
          :transition="{ duration: 0.45, delay: index * 0.07, ease: EASE }"
          class="group flex flex-col justify-between rounded-2xl border border-neutral-200/80 bg-white p-6 shadow-[0_1px_2px_rgba(9,13,22,0.03)] transition-[border-color,box-shadow] duration-200 hover:border-neutral-300 hover:shadow-[0_18px_36px_-20px_rgba(9,13,22,0.12)] sm:p-7"
        >
          <div>
            <div class="flex items-baseline justify-between gap-3">
              <h3 class="text-lg font-bold tracking-[-0.015em] text-neutral-950">
                {{ tier.name }}
              </h3>
              <span
                class="rounded-full bg-neutral-100 px-3 py-1 text-xs font-bold tabular-nums text-neutral-900"
              >
                {{ tier.priceLabel }}
              </span>
            </div>

            <p class="mt-3 text-sm leading-relaxed text-neutral-500">{{ tier.description }}</p>
          </div>

          <div class="mt-7 border-t border-neutral-100 pt-4">
            <button
              type="button"
              class="inline-flex items-center gap-1.5 text-xs font-semibold text-neutral-700 transition-colors hover:text-neutral-950"
              @click="triggerFarePrefill({ rideTier: tier.rideTierKey })"
            >
              <span>Check rate</span>
              <span
                class="transition-transform duration-150 group-hover:translate-x-0.5"
                aria-hidden="true"
              >
                &rarr;
              </span>
            </button>
          </div>
        </motion.article>
      </div>
    </div>
  </section>
</template>
