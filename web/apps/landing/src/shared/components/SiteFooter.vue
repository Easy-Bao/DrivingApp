<script setup lang="ts">
import { RouterLink } from 'vue-router'

interface FooterLink {
  label: string
  to: '/' | '/drive' | '/download' | '/architecture'
}

const FOOTER_LINKS: FooterLink[] = [
  { label: 'Ride', to: '/' },
  { label: 'Drive', to: '/drive' },
  { label: 'Download', to: '/download' },
  { label: 'Architecture', to: '/architecture' },
]
</script>

<template>
  <footer class="border-t border-neutral-200 bg-white">
    <div
      class="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-8 text-sm sm:flex-row sm:items-center sm:justify-between sm:px-6"
    >
      <div class="flex items-center gap-3">
        <span class="font-bold text-neutral-900">EasyRide</span>
        <span class="text-neutral-500">Pagadian City</span>
      </div>

      <nav aria-label="Footer navigation" class="flex flex-wrap items-center gap-6">
        <RouterLink
          v-for="link in FOOTER_LINKS"
          :key="link.to"
          :to="link.to"
          class="font-medium text-neutral-500 transition-colors hover:text-neutral-900"
        >
          {{ link.label }}
        </RouterLink>
      </nav>
    </div>
  </footer>
</template>
