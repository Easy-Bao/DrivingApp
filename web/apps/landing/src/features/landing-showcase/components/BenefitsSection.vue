<script setup lang="ts">
import { motion } from 'motion-v'
import { BENEFITS } from '@/features/landing-showcase/data/landingContent'

const EASE = [0.22, 1, 0.36, 1] as const
</script>

<template>
  <section id="why" class="border-b border-neutral-200/70 bg-neutral-50/70 py-20 sm:py-24">
    <div class="mx-auto max-w-6xl px-5 sm:px-6">
      <motion.div
        :initial="{ opacity: 0, y: 12 }"
        :while-in-view="{ opacity: 1, y: 0 }"
        :viewport="{ once: true, amount: 0.3 }"
        :transition="{ duration: 0.45, ease: EASE }"
        class="max-w-lg"
      >
        <p class="text-[11px] font-bold tracking-[0.14em] text-neutral-400 uppercase">
          Why EasyRide
        </p>
        <h2 class="mt-2.5 text-2xl font-bold tracking-[-0.025em] text-neutral-950 sm:text-3xl">
          Built for local rides.
        </h2>
      </motion.div>

      <div class="mt-12 grid gap-x-10 gap-y-8 sm:grid-cols-2 lg:grid-cols-4">
        <motion.div
          v-for="(item, index) in BENEFITS"
          :key="item.title"
          :initial="{ opacity: 0, y: 14 }"
          :while-in-view="{ opacity: 1, y: 0 }"
          :viewport="{ once: true, amount: 0.25 }"
          :transition="{ duration: 0.45, delay: index * 0.06, ease: EASE }"
          class="border-t border-neutral-200/90 pt-5"
        >
          <h3 class="text-[15px] font-bold tracking-[-0.01em] text-neutral-950">
            {{ item.title }}
          </h3>
          <p class="mt-2 text-sm leading-relaxed text-neutral-500">{{ item.description }}</p>
        </motion.div>
      </div>
    </div>
  </section>
</template>
