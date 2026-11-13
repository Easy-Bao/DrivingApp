<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <section class="bg-white py-16 sm:py-24">
    <div class="mx-auto max-w-3xl px-4 text-center sm:px-6">
      <h2 class="text-3xl font-bold tracking-tight text-neutral-900 sm:text-4xl">Ready to ride?</h2>
      <p class="mt-3 text-base text-neutral-600">Get EasyRide and book your first Taxicle today.</p>
      <RouterLink
        to="/download"
        class="mt-8 inline-flex min-h-12 items-center bg-neutral-900 px-8 py-3 text-sm font-semibold text-white transition-colors hover:bg-neutral-800"
      >
        Download App
      </RouterLink>
    </div>
  </section>
</template>
