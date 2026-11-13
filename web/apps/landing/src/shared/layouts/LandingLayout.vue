<script setup lang="ts">
import SiteFooter from '@/shared/components/SiteFooter.vue'
import SiteHeader from '@/shared/components/SiteHeader.vue'
</script>

<template>
  <div class="flex min-h-screen flex-col bg-neutral-50 text-neutral-900 font-sans antialiased">
    <a
      href="#main-content"
      class="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:bg-neutral-900 focus:px-4 focus:py-2 focus:text-sm focus:font-semibold focus:text-white"
    >
      Skip to content
    </a>

    <SiteHeader />

    <main id="main-content" tabindex="-1" class="flex-1 focus:outline-none">
      <slot />
    </main>

    <SiteFooter />
  </div>
</template>
