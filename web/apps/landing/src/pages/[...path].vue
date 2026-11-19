<script setup lang="ts">
import { motion } from 'motion-v'
import { RouterLink } from 'vue-router'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'

const EASE = [0.22, 1, 0.36, 1] as const
</script>

<template>
  <LandingLayout>
    <section class="py-24 sm:py-32">
      <motion.div
        :initial="{ opacity: 0, y: 12 }"
        :animate="{ opacity: 1, y: 0 }"
        :transition="{ duration: 0.45, ease: EASE }"
        class="mx-auto max-w-md px-5 text-center sm:px-6"
      >
        <span
          class="inline-flex rounded-full border border-neutral-200/90 bg-neutral-50 px-3 py-1 font-mono text-xs font-semibold text-neutral-500"
        >
          404
        </span>
        <h1 class="mt-5 text-3xl font-bold tracking-[-0.03em] text-neutral-950">Not Found</h1>
        <p class="mt-2.5 text-sm leading-relaxed text-neutral-500">
          The page you are looking for does not exist or has moved.
        </p>
        <RouterLink
          to="/"
          class="mt-7 inline-flex min-h-11 items-center rounded-full bg-neutral-950 px-6 py-2.5 text-sm font-semibold text-white shadow-[0_6px_16px_-6px_rgba(9,13,22,0.35)] transition-all duration-150 hover:bg-neutral-800 active:scale-[0.98]"
        >
          Back Home
        </RouterLink>
      </motion.div>
    </section>
  </LandingLayout>
</template>
