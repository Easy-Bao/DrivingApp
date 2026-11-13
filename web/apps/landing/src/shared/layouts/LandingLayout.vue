<script setup lang="ts">
import SiteFooter from '@/shared/components/SiteFooter.vue'
import SiteHeader from '@/shared/components/SiteHeader.vue'
</script>

<template>
  <div class="flex min-h-screen flex-col bg-white text-[#090d16] font-sans antialiased">
    <a
      href="#main-content"
      class="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-xl focus:bg-emerald-700 focus:px-4 focus:py-2.5 focus:text-sm focus:font-bold focus:text-white focus:shadow-lg"
    >
      Skip to main content
    </a>

    <SiteHeader />

    <main id="main-content" tabindex="-1" class="flex-1 focus:outline-none">
      <slot />
    </main>

    <SiteFooter />
  </div>
</template>
