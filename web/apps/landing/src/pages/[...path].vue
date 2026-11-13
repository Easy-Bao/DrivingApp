<script setup lang="ts">
import { RouterLink } from 'vue-router'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'
</script>

<template>
  <LandingLayout>
    <section class="py-20">
      <div class="mx-auto max-w-md px-4 text-center sm:px-6">
        <h1 class="text-3xl font-bold tracking-tight text-neutral-900">Not Found</h1>
        <p class="mt-2 text-sm text-neutral-600">This page does not exist.</p>
        <RouterLink
          to="/"
          class="mt-6 inline-flex min-h-10 items-center bg-neutral-900 px-5 py-2 text-sm font-semibold text-white hover:bg-neutral-800"
        >
          Back Home
        </RouterLink>
      </div>
    </section>
  </LandingLayout>
</template>
