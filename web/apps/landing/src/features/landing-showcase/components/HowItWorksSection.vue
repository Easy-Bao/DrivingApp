<script setup lang="ts">
import { motion } from 'motion-v'
import { HOW_IT_WORKS_STEPS } from '@/features/landing-showcase/data/landingContent'

const EASE = [0.22, 1, 0.36, 1] as const
</script>

<template>
  <section id="how-it-works" class="border-b border-neutral-200/70 bg-white py-20 sm:py-24">
    <div class="mx-auto max-w-6xl px-5 sm:px-6">
      <motion.div
        :initial="{ opacity: 0, y: 12 }"
        :while-in-view="{ opacity: 1, y: 0 }"
        :viewport="{ once: true, amount: 0.3 }"
        :transition="{ duration: 0.45, ease: EASE }"
        class="flex flex-col justify-between gap-2 sm:flex-row sm:items-end"
      >
        <div>
          <p class="text-[11px] font-bold tracking-[0.14em] text-neutral-400 uppercase">
            Simple Process
          </p>
          <h2 class="mt-2.5 text-2xl font-bold tracking-[-0.025em] text-neutral-950 sm:text-3xl">
            How It Works
          </h2>
        </div>
        <p class="text-sm text-neutral-500">From pickup pin to cash drop-off in three steps.</p>
      </motion.div>

      <div class="relative mt-12 grid gap-8 md:grid-cols-3 md:gap-10">
        <div
          class="pointer-events-none absolute top-[1.125rem] right-12 left-12 hidden h-px bg-neutral-200/80 md:block"
          aria-hidden="true"
        />

        <motion.div
          v-for="(step, index) in HOW_IT_WORKS_STEPS"
          :key="step.number"
          :initial="{ opacity: 0, y: 14 }"
          :while-in-view="{ opacity: 1, y: 0 }"
          :viewport="{ once: true, amount: 0.25 }"
          :transition="{ duration: 0.45, delay: index * 0.08, ease: EASE }"
          class="relative"
        >
          <span
            class="relative inline-flex h-9 w-9 items-center justify-center rounded-full border border-neutral-200/90 bg-white font-mono text-xs font-bold tabular-nums text-neutral-900 shadow-[0_1px_2px_rgba(9,13,22,0.04)]"
          >
            {{ step.number }}
          </span>
          <h3 class="mt-5 text-base font-bold tracking-[-0.01em] text-neutral-950">
            {{ step.title }}
          </h3>
          <p class="mt-2 max-w-xs text-sm leading-relaxed text-neutral-500">
            {{ step.description }}
          </p>
        </motion.div>
      </div>
    </div>
  </section>
</template>
