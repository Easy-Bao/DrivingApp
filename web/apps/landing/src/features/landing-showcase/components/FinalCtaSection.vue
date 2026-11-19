<script setup lang="ts">
import { motion } from 'motion-v'
import { RouterLink } from 'vue-router'

const EASE = [0.22, 1, 0.36, 1] as const
</script>

<template>
  <section class="bg-white py-20 sm:py-28">
    <motion.div
      :initial="{ opacity: 0, y: 14 }"
      :while-in-view="{ opacity: 1, y: 0 }"
      :viewport="{ once: true, amount: 0.3 }"
      :transition="{ duration: 0.5, ease: EASE }"
      class="mx-auto max-w-2xl px-5 text-center sm:px-6"
    >
      <h2
        class="text-3xl font-bold tracking-[-0.03em] text-neutral-950 sm:text-4xl lg:text-[2.625rem]"
      >
        Ready to ride?
      </h2>
      <p class="mt-3.5 text-base leading-relaxed text-neutral-500">
        Get EasyRide and book your first Taxicle today.
      </p>

      <div class="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
        <RouterLink
          to="/download"
          class="inline-flex min-h-12 items-center rounded-full bg-neutral-950 px-8 py-3 text-sm font-semibold text-white shadow-[0_8px_20px_-8px_rgba(9,13,22,0.45)] transition-all duration-150 hover:bg-neutral-800 active:scale-[0.98]"
        >
          Download App
        </RouterLink>
      </div>

      <p class="mt-5 text-xs text-neutral-400">Free for passengers · Android &amp; iOS</p>
    </motion.div>
  </section>
</template>
