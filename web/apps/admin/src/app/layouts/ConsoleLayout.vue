<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import Sidebar from '@/app/layouts/Sidebar.vue'
import { resolveBreadcrumbs } from '@/app/navigation/breadcrumbs'
import { useEscapeKey } from '@/shared'

const route = useRoute()
const mobileNavOpen = ref(false)

watch(
  () => route.path,
  () => {
    mobileNavOpen.value = false
  },
)

useEscapeKey(mobileNavOpen, () => {
  mobileNavOpen.value = false
})

const breadcrumbs = computed(() =>
  resolveBreadcrumbs(route.path, route.params as Record<string, unknown>),
)
</script>

<template>
  <div class="h-dvh bg-neutral-50 flex overflow-hidden font-sans text-neutral-900">
    <a
      href="#main-content"
      class="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-[100] focus:px-3 focus:py-2 focus:bg-neutral-900 focus:text-white focus:text-xs focus:font-semibold"
    >
      Skip to main content
    </a>

    <div
      v-if="mobileNavOpen"
      class="fixed inset-0 z-30 bg-black/40 lg:hidden"
      aria-hidden="true"
      @click="mobileNavOpen = false"
    />

    <Sidebar :mobile-open="mobileNavOpen" @close-mobile="mobileNavOpen = false" />

    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      <header
        class="h-14 sm:h-16 border-b border-neutral-200 bg-white px-3 sm:px-6 flex items-center gap-2.5 sm:gap-3 shrink-0"
      >
        <button
          type="button"
          class="lg:hidden w-9 h-9 flex items-center justify-center border border-neutral-200 text-neutral-700 hover:bg-neutral-100 transition-colors cursor-pointer shrink-0"
          aria-label="Open navigation menu"
          @click="mobileNavOpen = true"
        >
          <Icon icon="lucide:menu" class="text-base" aria-hidden="true" />
        </button>

        <nav
          aria-label="Breadcrumb"
          class="flex items-center gap-1.5 sm:gap-2 text-xs min-w-0 truncate"
        >
          <RouterLink
            to="/dashboard/overview"
            class="text-neutral-500 hover:text-neutral-900 transition-colors flex items-center shrink-0 p-1"
            title="Overview"
            aria-label="Overview"
          >
            <Icon icon="lucide:home" class="text-sm" aria-hidden="true" />
          </RouterLink>

          <template v-for="(crumb, index) in breadcrumbs" :key="crumb.label + index">
            <Icon
              icon="lucide:chevron-right"
              class="text-[11px] text-neutral-400 shrink-0"
              aria-hidden="true"
            />
            <RouterLink
              v-if="crumb.to && index < breadcrumbs.length - 1"
              :to="crumb.to"
              class="font-semibold text-neutral-500 hover:text-neutral-900 transition-colors truncate"
            >
              {{ crumb.label }}
            </RouterLink>
            <span v-else class="font-bold text-neutral-900 truncate" aria-current="page">
              {{ crumb.label }}
            </span>
          </template>
        </nav>
      </header>

      <main
        id="main-content"
        tabindex="-1"
        class="flex-1 min-w-0 overflow-y-auto overflow-x-hidden p-3 sm:p-6 bg-neutral-50 focus:outline-none"
      >
        <slot />
      </main>
    </div>
  </div>
</template>
