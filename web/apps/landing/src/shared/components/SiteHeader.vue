<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import BrandLogo from '@/shared/components/BrandLogo.vue'

interface NavLinkItem {
  label: string
  to: '/' | '/drive' | '/download'
}

const NAV_LINKS: NavLinkItem[] = [
  { label: 'Ride', to: '/' },
  { label: 'Drive', to: '/drive' },
  { label: 'Download', to: '/download' },
]

const route = useRoute()
const mobileMenuOpen = ref(false)

const isActiveLink = (path: string) => route?.path === path

const handleKeyDown = (event: KeyboardEvent) => {
  if (event.key === 'Escape' && mobileMenuOpen.value) {
    mobileMenuOpen.value = false
  }
}

watch(
  () => route?.fullPath,
  () => {
    mobileMenuOpen.value = false
  },
)

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleKeyDown)
})
</script>

<template>
  <header class="sticky top-0 z-40 w-full border-b border-neutral-200 bg-white">
    <div class="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-4 sm:px-6">
      <RouterLink to="/" aria-label="EasyRide Home" class="py-1">
        <BrandLogo />
      </RouterLink>

      <div class="hidden items-center gap-6 md:flex">
        <nav aria-label="Main navigation" class="flex items-center gap-6">
          <RouterLink
            v-for="item in NAV_LINKS"
            :key="item.to"
            :to="item.to"
            class="border-b-2 py-1 text-sm font-semibold transition-colors"
            :class="
              isActiveLink(item.to)
                ? 'border-neutral-900 text-neutral-900'
                : 'border-transparent text-neutral-500 hover:text-neutral-900'
            "
          >
            {{ item.label }}
          </RouterLink>
        </nav>

        <RouterLink
          to="/download"
          class="inline-flex min-h-9 items-center bg-neutral-900 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-neutral-800"
        >
          Get App
        </RouterLink>
      </div>

      <button
        type="button"
        class="inline-flex h-10 w-10 items-center justify-center border border-neutral-300 bg-white text-neutral-900 md:hidden"
        :aria-expanded="mobileMenuOpen"
        aria-controls="mobile-nav-drawer"
        aria-label="Toggle navigation menu"
        @click="mobileMenuOpen = !mobileMenuOpen"
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path
            v-if="!mobileMenuOpen"
            d="M4 7h16M4 12h16M4 17h16"
            stroke="currentColor"
            stroke-width="1.9"
            stroke-linecap="round"
          />
          <path
            v-else
            d="M6 6l12 12M18 6L6 18"
            stroke="currentColor"
            stroke-width="1.9"
            stroke-linecap="round"
          />
        </svg>
      </button>
    </div>

    <div
      v-if="mobileMenuOpen"
      id="mobile-nav-drawer"
      class="border-t border-neutral-200 bg-white px-4 py-3 md:hidden"
    >
      <nav aria-label="Mobile navigation" class="flex flex-col gap-1">
        <RouterLink
          v-for="item in NAV_LINKS"
          :key="item.to"
          :to="item.to"
          class="px-3 py-2.5 text-sm font-semibold transition-colors"
          :class="
            isActiveLink(item.to)
              ? 'bg-neutral-100 text-neutral-900'
              : 'text-neutral-600 hover:bg-neutral-50 hover:text-neutral-900'
          "
        >
          {{ item.label }}
        </RouterLink>
      </nav>
    </div>
  </header>
</template>
