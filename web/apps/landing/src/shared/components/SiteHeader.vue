<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import BrandLogo from '@/shared/components/BrandLogo.vue'
import UiIcon from '@/shared/components/UiIcon.vue'

interface NavLinkItem {
  label: string
  to: '/' | '/drive' | '/safety' | '/architecture'
  description: string
}

const NAV_LINKS: NavLinkItem[] = [
  {
    label: 'Ride',
    to: '/',
    description: 'Book Taxicles with upfront fare floors',
  },
  {
    label: 'Drive & Earn',
    to: '/drive',
    description: 'Prepaid QRPh wallet & transparent tiers',
  },
  {
    label: 'Safety',
    to: '/safety',
    description: 'Verified TODA units & 24/7 SOS desk',
  },
  {
    label: 'Architecture',
    to: '/architecture',
    description: 'Go dispatch, WebSocket & Flutter stack',
  },
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
  <header
    class="sticky top-0 z-40 w-full border-b border-slate-200/80 bg-white/95 backdrop-blur-md"
  >
    <div
      class="mx-auto flex h-16 max-w-7xl items-center justify-between gap-4 px-4 sm:px-6 lg:px-8"
    >
      <RouterLink
        to="/"
        aria-label="EasyRide Pagadian Home"
        class="rounded-xl py-1 transition-opacity hover:opacity-90"
      >
        <BrandLogo show-city-tag />
      </RouterLink>

      <nav aria-label="Main navigation" class="hidden items-center gap-1 md:flex">
        <RouterLink
          v-for="item in NAV_LINKS"
          :key="item.to"
          :to="item.to"
          class="rounded-full px-4 py-2 text-sm font-semibold transition-colors"
          :class="
            isActiveLink(item.to)
              ? 'bg-emerald-50 text-emerald-800 ring-1 ring-inset ring-emerald-200'
              : 'text-slate-700 hover:bg-slate-100 hover:text-[#090d16]'
          "
        >
          {{ item.label }}
        </RouterLink>
      </nav>

      <div class="hidden items-center gap-3 md:flex">
        <RouterLink
          :to="{ path: '/', hash: '#fare-estimator' }"
          class="inline-flex min-h-10 items-center gap-1.5 rounded-full px-3.5 py-2 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-100 hover:text-[#090d16]"
        >
          <span>Estimate Fare</span>
        </RouterLink>

        <RouterLink
          to="/download"
          class="inline-flex min-h-10 items-center gap-2 rounded-full bg-emerald-700 px-5 py-2 text-sm font-semibold text-white shadow-xs transition-colors hover:bg-emerald-800"
        >
          <span>Get the App</span>
          <UiIcon name="arrow-right" size-class="h-4 w-4" />
        </RouterLink>
      </div>

      <div class="flex items-center gap-2 md:hidden">
        <RouterLink
          to="/download"
          class="inline-flex min-h-10 items-center rounded-full bg-emerald-700 px-4 py-2 text-xs font-bold text-white shadow-xs transition-colors hover:bg-emerald-800"
        >
          Get App
        </RouterLink>
        <button
          type="button"
          class="inline-flex h-11 w-11 items-center justify-center rounded-xl border border-slate-200 bg-white text-[#090d16] transition-colors hover:bg-slate-50"
          :aria-expanded="mobileMenuOpen"
          aria-controls="mobile-nav-drawer"
          aria-label="Toggle navigation menu"
          @click="mobileMenuOpen = !mobileMenuOpen"
        >
          <UiIcon :name="mobileMenuOpen ? 'close' : 'menu'" size-class="h-5 w-5" />
        </button>
      </div>
    </div>

    <div
      v-if="mobileMenuOpen"
      id="mobile-nav-drawer"
      class="border-t border-slate-200 bg-white px-4 py-4 shadow-lg md:hidden"
    >
      <nav aria-label="Mobile navigation" class="flex flex-col gap-2">
        <RouterLink
          v-for="item in NAV_LINKS"
          :key="item.to"
          :to="item.to"
          class="flex items-center justify-between rounded-2xl px-4 py-3 transition-colors"
          :class="
            isActiveLink(item.to)
              ? 'bg-emerald-50 text-emerald-900 ring-1 ring-emerald-200'
              : 'bg-slate-50 text-[#090d16] hover:bg-slate-100'
          "
        >
          <span>
            <span class="block text-sm font-bold">{{ item.label }}</span>
            <span class="block text-xs text-slate-600">{{ item.description }}</span>
          </span>
          <UiIcon name="arrow-right" size-class="h-4 w-4 text-slate-400" />
        </RouterLink>
      </nav>

      <div class="mt-4 flex flex-col gap-2 border-t border-slate-100 pt-4">
        <RouterLink
          :to="{ path: '/', hash: '#fare-estimator' }"
          class="inline-flex min-h-11 items-center justify-center rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-[#090d16]"
        >
          Check Pagadian Fare Floor
        </RouterLink>
        <RouterLink
          to="/download"
          class="inline-flex min-h-11 items-center justify-center gap-2 rounded-xl bg-emerald-700 px-4 py-2.5 text-sm font-bold text-white"
        >
          <span>Download Passenger &amp; Driver Apps</span>
          <UiIcon name="download" size-class="h-4 w-4" />
        </RouterLink>
      </div>
    </div>
  </header>
</template>
