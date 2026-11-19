<script setup lang="ts">
import { RouterLink } from 'vue-router'
import BrandLogo from '@/shared/components/BrandLogo.vue'

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
  <footer class="border-t border-neutral-200/75 bg-neutral-50/50">
    <div class="mx-auto max-w-6xl px-5 py-10 sm:px-6 sm:py-12">
      <div class="flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
          <RouterLink to="/" aria-label="EasyRide Home">
            <BrandLogo size="sm" />
          </RouterLink>
          <span class="hidden h-3.5 w-px bg-neutral-200 sm:inline-block" aria-hidden="true" />
          <span class="text-xs font-medium text-neutral-500">Pagadian City, Zamboanga del Sur</span>
        </div>

        <nav aria-label="Footer navigation" class="flex flex-wrap items-center gap-x-6 gap-y-2">
          <RouterLink
            v-for="link in FOOTER_LINKS"
            :key="link.to"
            :to="link.to"
            class="text-sm font-medium text-neutral-500 transition-colors hover:text-neutral-950"
          >
            {{ link.label }}
          </RouterLink>
        </nav>
      </div>

      <div
        class="mt-8 flex flex-col gap-2 border-t border-neutral-200/70 pt-6 text-xs text-neutral-400 sm:flex-row sm:items-center sm:justify-between"
      >
        <p>Upfront Taxicle, TukTuk, and e-BaoBao fares across Pagadian.</p>
        <p>Cash on arrival · Android &amp; iOS</p>
      </div>
    </div>
  </footer>
</template>
