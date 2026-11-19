<script setup lang="ts">
import { motion } from 'motion-v'
import PlatformArchitectureExplorer from '@/features/platform-architecture/components/PlatformArchitectureExplorer.vue'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'

const EASE = [0.22, 1, 0.36, 1] as const
</script>

<template>
  <LandingLayout>
    <section class="bg-neutral-50/70 py-16 sm:py-22">
      <div class="mx-auto max-w-6xl px-5 sm:px-6">
        <motion.div
          :initial="{ opacity: 0, y: 12 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.45, ease: EASE }"
        >
          <p class="text-[11px] font-bold tracking-[0.14em] text-neutral-400 uppercase">Platform</p>
          <h1
            class="mt-3 text-3xl leading-tight font-bold tracking-[-0.035em] text-neutral-950 sm:text-4xl lg:text-5xl"
          >
            System Architecture
          </h1>
          <p class="mt-3 max-w-xl text-sm leading-relaxed text-neutral-500 sm:text-base">
            Overview of the gateway, core dispatch, and real-time bidding components.
          </p>
        </motion.div>

        <motion.div
          :initial="{ opacity: 0, y: 16 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.5, delay: 0.08, ease: EASE }"
          class="mt-10"
        >
          <PlatformArchitectureExplorer />
        </motion.div>
      </div>
    </section>
  </LandingLayout>
</template>
