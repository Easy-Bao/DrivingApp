<script setup lang="ts">
import { HOW_IT_WORKS_STEPS } from '@/features/landing-showcase/data/landingContent'
</script>

<template>
  <section id="how-it-works" class="border-y border-neutral-200 bg-neutral-50 py-14 sm:py-20">
    <div class="mx-auto max-w-6xl px-4 sm:px-6">
      <h2 class="text-2xl font-bold tracking-tight text-neutral-900 sm:text-3xl">How It Works</h2>

      <div class="mt-8 grid gap-8 md:grid-cols-3">
        <div v-for="step in HOW_IT_WORKS_STEPS" :key="step.number">
          <span class="font-mono text-xs font-bold tabular-nums text-neutral-500">
            {{ step.number }}
          </span>
          <h3 class="mt-2 text-base font-bold text-neutral-900">{{ step.title }}</h3>
          <p class="mt-1.5 text-sm leading-relaxed text-neutral-600">{{ step.description }}</p>
        </div>
      </div>
    </div>
  </section>
</template>
