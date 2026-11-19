<script setup lang="ts">
import { AnimatePresence, motion } from 'motion-v'
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
const headerRef = ref<HTMLElement | null>(null)
const mobileMenuOpen = ref(false)

const isActiveLink = (path: string) => route?.path === path

const handleKeyDown = (event: KeyboardEvent) => {
  if (event.key === 'Escape' && mobileMenuOpen.value) {
    mobileMenuOpen.value = false
  }
}

const handlePointerDown = (event: PointerEvent) => {
  if (!mobileMenuOpen.value) {
    return
  }
  const target = event.target
  if (headerRef.value && target instanceof Node && !headerRef.value.contains(target)) {
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
  document.addEventListener('pointerdown', handlePointerDown)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleKeyDown)
  document.removeEventListener('pointerdown', handlePointerDown)
})
</script>

<template>
  <header
    ref="headerRef"
    class="sticky top-0 z-40 w-full border-b border-neutral-200/75 bg-white/80 backdrop-blur-md supports-[backdrop-filter]:bg-white/75"
  >
    <div class="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-5 sm:px-6">
      <RouterLink
        to="/"
        aria-label="EasyRide Home"
        class="rounded-md py-1 transition-opacity hover:opacity-75"
      >
        <BrandLogo />
      </RouterLink>

      <div class="hidden items-center gap-3 md:flex">
        <nav aria-label="Main navigation" class="flex items-center gap-1">
          <RouterLink
            v-for="item in NAV_LINKS"
            :key="item.to"
            :to="item.to"
            class="relative rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors duration-150"
            :class="
              isActiveLink(item.to)
                ? 'font-semibold text-neutral-950'
                : 'text-neutral-500 hover:text-neutral-950'
            "
          >
            <motion.span
              v-if="isActiveLink(item.to)"
              layout-id="header-active-pill"
              :transition="{ type: 'spring', stiffness: 460, damping: 34 }"
              class="absolute inset-0 -z-10 rounded-full bg-neutral-100"
              aria-hidden="true"
            />
            {{ item.label }}
          </RouterLink>
        </nav>

        <span class="mx-1 h-4 w-px bg-neutral-200/80" aria-hidden="true" />

        <RouterLink
          to="/download"
          class="inline-flex min-h-9 items-center rounded-full bg-neutral-950 px-4 py-2 text-sm font-semibold text-white shadow-[0_1px_2px_rgba(9,13,22,0.16)] transition-all duration-150 hover:bg-neutral-800 active:scale-[0.98]"
        >
          Get App
        </RouterLink>
      </div>

      <motion.button
        type="button"
        class="inline-flex h-10 w-10 items-center justify-center rounded-lg text-neutral-950 transition-opacity hover:opacity-70 md:hidden"
        :while-press="{ scale: 0.9 }"
        :aria-expanded="mobileMenuOpen"
        aria-controls="mobile-nav-drawer"
        aria-label="Toggle navigation menu"
        @click="mobileMenuOpen = !mobileMenuOpen"
      >
        <span class="relative flex h-4 w-5 flex-col items-center justify-center" aria-hidden="true">
          <motion.span
            class="absolute h-[1.75px] w-5 rounded-full bg-current"
            :initial="false"
            :animate="mobileMenuOpen ? { y: 0, rotate: 45 } : { y: -5.5, rotate: 0 }"
            :transition="{ type: 'spring', stiffness: 420, damping: 30 }"
          />
          <motion.span
            class="absolute h-[1.75px] w-5 rounded-full bg-current"
            :initial="false"
            :animate="mobileMenuOpen ? { opacity: 0, scaleX: 0 } : { opacity: 1, scaleX: 1 }"
            :transition="{ duration: 0.16, ease: [0.22, 1, 0.36, 1] }"
          />
          <motion.span
            class="absolute h-[1.75px] w-5 rounded-full bg-current"
            :initial="false"
            :animate="mobileMenuOpen ? { y: 0, rotate: -45 } : { y: 5.5, rotate: 0 }"
            :transition="{ type: 'spring', stiffness: 420, damping: 30 }"
          />
        </span>
      </motion.button>
    </div>

    <AnimatePresence>
      <motion.div
        v-if="mobileMenuOpen"
        id="mobile-nav-drawer"
        key="mobile-nav-drawer"
        :initial="{ opacity: 0, y: -8 }"
        :animate="{ opacity: 1, y: 0 }"
        :exit="{ opacity: 0, y: -6 }"
        :transition="{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }"
        class="absolute inset-x-0 top-full z-40 border-b border-neutral-200/80 bg-white/95 shadow-[0_20px_40px_-16px_rgba(9,13,22,0.14)] backdrop-blur-md md:hidden"
      >
        <div class="px-5 py-4">
          <nav aria-label="Mobile navigation" class="flex flex-col gap-1">
            <motion.div
              v-for="(item, index) in NAV_LINKS"
              :key="item.to"
              :initial="{ opacity: 0, x: -6 }"
              :animate="{ opacity: 1, x: 0 }"
              :transition="{ duration: 0.18, delay: index * 0.035, ease: [0.22, 1, 0.36, 1] }"
            >
              <RouterLink
                :to="item.to"
                class="block rounded-xl px-3.5 py-2.5 text-sm font-medium transition-colors"
                :class="
                  isActiveLink(item.to)
                    ? 'bg-neutral-100 font-semibold text-neutral-950'
                    : 'text-neutral-600 hover:bg-neutral-50 hover:text-neutral-950'
                "
              >
                {{ item.label }}
              </RouterLink>
            </motion.div>
          </nav>

          <motion.div
            :initial="{ opacity: 0, y: 4 }"
            :animate="{ opacity: 1, y: 0 }"
            :transition="{ duration: 0.2, delay: 0.1, ease: [0.22, 1, 0.36, 1] }"
            class="mt-3 border-t border-neutral-100 pt-3"
          >
            <RouterLink
              to="/download"
              class="inline-flex min-h-10 w-full items-center justify-center rounded-full bg-neutral-950 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-neutral-800"
            >
              Get App
            </RouterLink>
          </motion.div>
        </div>
      </motion.div>
    </AnimatePresence>
  </header>
</template>
