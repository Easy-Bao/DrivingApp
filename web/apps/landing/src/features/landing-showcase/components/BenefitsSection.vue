<script setup lang="ts">
import { BENEFITS } from '@/features/landing-showcase/data/landingContent'
</script>

<template>
  <section id="why" class="bg-neutral-50 py-14 sm:py-20">
    <div class="mx-auto max-w-6xl px-4 sm:px-6">
      <h2 class="max-w-md text-2xl font-bold tracking-tight text-neutral-900 sm:text-3xl">
        Built for local rides.
      </h2>

      <div class="mt-10 grid gap-x-10 gap-y-8 sm:grid-cols-2 lg:grid-cols-4">
        <div v-for="item in BENEFITS" :key="item.title" class="border-t-2 border-neutral-900 pt-4">
          <h3 class="text-base font-bold text-neutral-900">{{ item.title }}</h3>
          <p class="mt-2 text-sm leading-relaxed text-neutral-600">{{ item.description }}</p>
        </div>
      </div>
    </div>
  </section>
</template>
