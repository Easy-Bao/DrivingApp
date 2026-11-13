<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { motion, AnimatePresence } from 'motion-v'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import { navigationGroups, type SidebarSubItem } from '@/app/navigation/sidebar-menu'
import { ROLE_PROFILES, lockAuthSession, useAuthSession } from '@/core/auth/auth-session'

withDefaults(
  defineProps<{
    mobileOpen?: boolean
  }>(),
  {
    mobileOpen: false,
  },
)

const emit = defineEmits<{
  (e: 'closeMobile'): void
}>()

const route = useRoute()
const router = useRouter()

const isCollapsed = ref(false)
const searchQuery = ref('')
const showSignOutConfirm = ref(false)
const signedOutNotice = ref(false)
const authSession = useAuthSession()

const activeRoleLabel = computed(() => {
  const role = authSession.value.role
  return role ? ROLE_PROFILES[role].label : 'Locked Session'
})

const operatorInitials = computed(() => {
  const words = authSession.value.operatorName.trim().split(/\s+/).filter(Boolean)
  return (
    words
      .slice(0, 2)
      .map((w) => w[0]?.toUpperCase() || '')
      .join('') || 'OP'
  )
})

const expandedGroups = ref<Record<string, boolean>>({
  dashboard: true,
  users: true,
  trips: true,
  payments: true,
  reports: false,
  documents: false,
  support: false,
  settings: false,
})

function toggleCollapse() {
  isCollapsed.value = !isCollapsed.value
}

function toggleGroup(groupId: string) {
  expandedGroups.value[groupId] = !expandedGroups.value[groupId]
}

function navigateTo(path: string) {
  emit('closeMobile')
  void router.push(path)
}

function confirmSignOut() {
  showSignOutConfirm.value = false
  signedOutNotice.value = true
  lockAuthSession()
  emit('closeMobile')
  void router.push({ name: 'auth-login', query: { redirect: route.fullPath } })
}

const activeItem = computed(() => {
  const allItems = navigationGroups.flatMap((g) => g.items)

  const exact = allItems.find((item) => route.path === item.path)
  if (exact) return exact

  if (route.path === '/' || route.path === '/dashboard' || route.path === '/dashboard/overview') {
    return allItems.find((item) => item.id === 'overview')
  }

  const prefixMatches = allItems.filter(
    (item) => item.path !== '/' && route.path.startsWith(`${item.path}/`),
  )
  if (prefixMatches.length > 0) {
    prefixMatches.sort((a, b) => b.path.length - a.path.length)
    return prefixMatches[0]
  }

  return null
})

function isItemActive(item: SidebarSubItem): boolean {
  return activeItem.value?.id === item.id && activeItem.value?.path === item.path
}

watch(
  () => route.path,
  () => {
    for (const group of navigationGroups) {
      if (group.items.some((i) => isItemActive(i))) {
        expandedGroups.value[group.id] = true
      }
    }
  },
  { immediate: true },
)

const filteredGroups = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) return navigationGroups

  return navigationGroups
    .map((group) => {
      const matchingItems = group.items.filter(
        (item) =>
          item.label.toLowerCase().includes(query) || group.title.toLowerCase().includes(query),
      )
      return {
        ...group,
        items: matchingItems,
      }
    })
    .filter((group) => group.items.length > 0)
})
</script>

<template>
  <motion.aside
    :animate="{ width: isCollapsed ? '5rem' : '18rem' }"
    :transition="{ duration: 0.25, ease: [0.16, 1, 0.3, 1] }"
    class="bg-white border-r border-neutral-200 flex flex-col justify-between shrink-0 select-none h-screen fixed inset-y-0 left-0 lg:sticky lg:top-0 z-40 overflow-hidden transition-transform duration-200"
    :class="[
      isCollapsed ? 'w-20' : 'w-72',
      mobileOpen ? 'translate-x-0 shadow-2xl lg:shadow-none' : '-translate-x-full lg:translate-x-0',
    ]"
    aria-label="Navigation Sidebar"
  >
    <div class="shrink-0">
      <div
        class="h-16 flex items-center border-b border-neutral-200 transition-all duration-300"
        :class="isCollapsed ? 'justify-center px-2' : 'justify-between px-4'"
      >
        <div v-if="!isCollapsed" class="flex items-center space-x-3 overflow-hidden min-w-0">
          <div class="flex flex-col overflow-hidden whitespace-nowrap">
            <span class="font-bold text-sm text-neutral-900 leading-tight">EasyRide</span>
            <span class="text-[11px] text-neutral-500 font-medium">Pagadian Ops · 7016</span>
          </div>
        </div>

        <div class="flex items-center gap-1">
          <button
            v-if="mobileOpen"
            type="button"
            class="lg:hidden rounded-none text-neutral-600 hover:text-neutral-900 hover:bg-neutral-100 p-1.5 transition-colors cursor-pointer"
            aria-label="Close navigation menu"
            @click="emit('closeMobile')"
          >
            <Icon icon="lucide:x" class="text-lg" aria-hidden="true" />
          </button>

          <button
            type="button"
            class="rounded-none text-neutral-600 hover:text-neutral-900 hover:bg-neutral-100 transition-colors flex items-center justify-center shrink-0"
            :class="isCollapsed ? 'w-10 h-10 bg-neutral-50 border border-neutral-200' : 'p-1.5'"
            :aria-label="isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'"
            :title="isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'"
            @click="toggleCollapse"
          >
            <Icon
              :icon="isCollapsed ? 'lucide:panel-left-open' : 'lucide:panel-left-close'"
              class="text-lg"
            />
          </button>
        </div>
      </div>

      <div v-if="!isCollapsed" class="p-3 border-b border-neutral-100">
        <div class="relative">
          <Icon
            icon="lucide:search"
            class="absolute left-2.5 top-2.5 text-neutral-400 text-sm"
            aria-hidden="true"
          />
          <input
            v-model="searchQuery"
            type="text"
            aria-label="Filter navigation sections"
            placeholder="Search sections..."
            class="w-full pl-8 pr-7 py-1.5 bg-neutral-50 border border-neutral-200 text-xs placeholder:text-neutral-400 focus:outline-none focus:ring-1 focus:ring-neutral-900 focus:bg-white transition-all"
          />
          <button
            v-if="searchQuery"
            type="button"
            aria-label="Clear navigation filter"
            class="absolute right-2 top-2 text-neutral-400 hover:text-neutral-700 cursor-pointer"
            @click="searchQuery = ''"
          >
            <Icon icon="lucide:x" class="text-xs" aria-hidden="true" />
          </button>
        </div>
      </div>
    </div>

    <nav class="flex-1 overflow-y-auto px-3 py-3 space-y-3" aria-label="Main navigation">
      <div
        v-if="filteredGroups.length === 0"
        class="px-3 py-6 text-center text-xs text-neutral-500 border border-dashed border-neutral-200"
      >
        No matching sections for "{{ searchQuery }}"
      </div>
      <div v-for="group in filteredGroups" :key="group.id" class="space-y-1">
        <button
          v-if="!isCollapsed"
          type="button"
          class="w-full flex items-center justify-between px-2.5 py-1.5 text-xs font-semibold uppercase tracking-wider text-neutral-400 hover:text-neutral-700 transition-colors"
          @click="toggleGroup(group.id)"
        >
          <div class="flex items-center space-x-2">
            <Icon :icon="group.icon" class="text-sm" />
            <span>{{ group.title }}</span>
          </div>
          <Icon
            :icon="
              expandedGroups[group.id] || searchQuery
                ? 'lucide:chevron-down'
                : 'lucide:chevron-right'
            "
            class="text-xs transition-transform"
          />
        </button>

        <div v-else class="h-px bg-neutral-100 my-2 mx-2" :title="group.title" />

        <AnimatePresence>
          <motion.div
            v-if="isCollapsed || expandedGroups[group.id] || searchQuery"
            :initial="{ opacity: 0, height: 0 }"
            :animate="{ opacity: 1, height: 'auto' }"
            :exit="{ opacity: 0, height: 0 }"
            :transition="{ duration: 0.2, ease: 'easeInOut' }"
            class="overflow-hidden space-y-0.5"
            :class="!isCollapsed ? 'ml-4 pl-2 border-l border-neutral-200 my-0.5' : ''"
          >
            <button
              v-for="item in group.items"
              :key="item.id"
              type="button"
              class="w-full flex items-center text-xs font-medium transition-colors group relative"
              :class="[
                isItemActive(item)
                  ? 'text-white'
                  : 'text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900',
                isCollapsed ? 'justify-center p-2.5' : 'justify-between px-3 py-2',
              ]"
              :title="isCollapsed ? `${group.title}: ${item.label}` : undefined"
              @click="navigateTo(item.path)"
            >
              <motion.span
                v-if="isItemActive(item)"
                layoutId="activeSidebarIndicator"
                class="absolute inset-0 rounded-none bg-neutral-900"
                :transition="{ type: 'spring', stiffness: 380, damping: 30 }"
              />

              <div class="relative z-10 flex items-center space-x-2.5 overflow-hidden">
                <Icon
                  v-if="isCollapsed"
                  :icon="item.icon"
                  class="text-base shrink-0 transition-colors"
                  :class="
                    isItemActive(item)
                      ? 'text-white'
                      : 'text-neutral-400 group-hover:text-neutral-700'
                  "
                />
                <span v-if="!isCollapsed" class="truncate">{{ item.label }}</span>
              </div>

              <span
                v-if="!isCollapsed && item.badge"
                class="relative z-10 text-[10px] px-1.5 py-0.5 rounded-none font-semibold transition-colors"
                :class="
                  isItemActive(item)
                    ? 'bg-neutral-800 text-white'
                    : item.badgeClass || 'bg-neutral-100 text-neutral-700'
                "
              >
                {{ item.badge }}
              </span>

              <span
                v-if="isCollapsed && item.badge"
                class="relative z-10 absolute top-1.5 right-1.5 w-2 h-2 rounded-none"
                :class="item.id === 'sos-alerts' ? 'bg-neutral-900' : 'bg-neutral-500'"
              />
            </button>
          </motion.div>
        </AnimatePresence>
      </div>
    </nav>

    <div class="shrink-0 p-3 border-t border-neutral-200 bg-neutral-50/50">
      <div
        class="flex items-center p-2 hover:bg-neutral-100 transition-colors"
        :class="isCollapsed ? 'justify-center' : 'justify-between'"
      >
        <button
          type="button"
          class="flex items-center space-x-3 overflow-hidden text-left focus:outline-none"
          :title="isCollapsed ? 'Profile' : undefined"
          @click="navigateTo('/account/profile')"
        >
          <div
            class="w-8 h-8 bg-neutral-900 text-white flex items-center justify-center font-semibold text-xs shrink-0"
          >
            {{ operatorInitials }}
          </div>
          <div v-if="!isCollapsed" class="flex flex-col overflow-hidden whitespace-nowrap">
            <span class="text-xs font-semibold text-neutral-900 truncate">{{
              authSession.operatorName
            }}</span>
            <span class="text-[11px] text-neutral-500 truncate">{{ activeRoleLabel }}</span>
          </div>
        </button>

        <button
          v-if="!isCollapsed"
          type="button"
          class="text-neutral-400 hover:text-neutral-900 p-1.5 hover:bg-neutral-100 transition-colors cursor-pointer"
          title="Lock session"
          aria-label="Lock session"
          @click="showSignOutConfirm = true"
        >
          <Icon icon="lucide:lock" class="text-base" />
        </button>
      </div>

      <p
        v-if="signedOutNotice && !isCollapsed"
        class="mt-2 px-2 py-1 text-[10px] font-medium bg-neutral-100 text-neutral-700 border border-neutral-200"
      >
        Session locked.
      </p>
    </div>

    <ConfirmDialog
      v-model:open="showSignOutConfirm"
      title="Lock Session?"
      description="Locks your session and returns to login."
      confirm-label="Lock Session"
      tone="neutral"
      @confirm="confirmSignOut"
    />
  </motion.aside>
</template>
