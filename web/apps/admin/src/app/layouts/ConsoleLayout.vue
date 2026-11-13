<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import Sidebar from '@/app/layouts/Sidebar.vue'
import { navigationGroups } from '@/app/navigation/menu'
import { useEscapeKey } from '@/shared/composables/use-escape-key'

interface BreadcrumbMeta {
  section: string
  sectionTo: string
  item: string
}

interface BreadcrumbItem {
  label: string
  to?: string
}

const route = useRoute()
const mobileNavOpen = ref(false)

const routeLookup: Record<string, BreadcrumbMeta> = {
  '/account/profile': { section: 'Account', sectionTo: '/account/profile', item: 'Profile' },
  '/unauthorized': {
    section: 'Security',
    sectionTo: '/dashboard/overview',
    item: 'Restricted Access',
  },
}

for (const group of navigationGroups) {
  const sectionTo = group.items[0]?.path ?? '/dashboard/overview'
  for (const item of group.items) {
    routeLookup[item.path] = {
      section: group.title,
      sectionTo,
      item: item.label,
    }
  }
}

watch(
  () => route.path,
  () => {
    mobileNavOpen.value = false
  },
)

useEscapeKey(mobileNavOpen, () => {
  mobileNavOpen.value = false
})

const breadcrumbs = computed<BreadcrumbItem[]>(() => {
  const match = routeLookup[route.path]
  if (match) {
    if (match.item === match.section) {
      return [{ label: match.section }]
    }
    return [{ label: match.section, to: match.sectionTo }, { label: match.item }]
  }

  const segments = route.path.split('/').filter(Boolean)
  if (segments.length >= 3) {
    const parentPath = `/${segments[0]}/${segments[1]}`
    const parentMatch = routeLookup[parentPath]
    const paramId = 'id' in route.params ? String(route.params.id) : ''
    const detailId = paramId || segments.slice(2).join('/')
    if (parentMatch) {
      return [
        { label: parentMatch.section, to: parentMatch.sectionTo },
        { label: parentMatch.item, to: parentPath },
        { label: `#${detailId}` },
      ]
    }
  }

  const sectionLabel = segments[0]
    ? segments[0].charAt(0).toUpperCase() + segments[0].slice(1)
    : 'Dashboard'
  const itemLabel = segments[1]
    ? segments[1].replace(/-/g, ' ').replace(/\b\w/g, (char) => char.toUpperCase())
    : 'Overview'
  if (sectionLabel === itemLabel) {
    return [{ label: sectionLabel }]
  }
  return [
    { label: sectionLabel, to: `/${segments[0] || 'dashboard/overview'}` },
    { label: itemLabel },
  ]
})
</script>

<template>
  <div class="h-dvh min-h-screen bg-neutral-50 flex overflow-hidden font-sans text-neutral-900">
    <div
      v-if="mobileNavOpen"
      class="fixed inset-0 z-30 bg-black/40 lg:hidden"
      aria-hidden="true"
      @click="mobileNavOpen = false"
    />

    <Sidebar :mobile-open="mobileNavOpen" @close-mobile="mobileNavOpen = false" />

    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      <header
        class="h-14 sm:h-16 border-b border-neutral-200 bg-white px-3 sm:px-6 flex items-center justify-between gap-3 shrink-0 select-none"
      >
        <div class="flex items-center gap-2.5 sm:gap-3 min-w-0">
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
              class="text-neutral-400 hover:text-neutral-900 transition-colors flex items-center shrink-0 p-1"
              title="Overview"
              aria-label="Overview"
            >
              <Icon icon="lucide:home" class="text-sm" aria-hidden="true" />
            </RouterLink>

            <template v-for="(crumb, index) in breadcrumbs" :key="crumb.label + index">
              <Icon
                icon="lucide:chevron-right"
                class="text-[11px] text-neutral-300 shrink-0"
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
        </div>
      </header>

      <main class="flex-1 min-w-0 overflow-y-auto overflow-x-hidden p-3 sm:p-6 bg-neutral-50">
        <slot />
      </main>
    </div>
  </div>
</template>
