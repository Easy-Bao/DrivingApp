<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { motion, AnimatePresence } from 'motion-v'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import {
  navigationGroups,
  type SidebarNavGroup,
  type SidebarSubItem,
} from '@/app/navigation/sidebar-menu'
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
const isToggleHovered = ref(false)
const searchQuery = ref('')
const showSignOutConfirm = ref(false)
const signedOutNotice = ref(false)
const authSession = useAuthSession()

interface FlyoutItem {
  id: string
  label: string
  icon: string
  badge?: string | number
  isActive?: boolean
  onSelect: () => void
}

interface FlyoutState {
  id: string
  title: string
  activeItemLabel?: string | null
  metaText?: string
  items: FlyoutItem[]
  top: number
  left: number
}

interface TooltipState {
  label: string
  top: number
  left: number
}

const activeFlyout = ref<FlyoutState | null>(null)
const collapsedTooltip = ref<TooltipState | null>(null)
let flyoutCloseTimer: ReturnType<typeof setTimeout> | null = null

const clearFlyoutTimer = () => {
  if (flyoutCloseTimer !== null) {
    clearTimeout(flyoutCloseTimer)
    flyoutCloseTimer = null
  }
}

const openGroupFlyout = (group: SidebarNavGroup, event: Event) => {
  if (!isCollapsed.value) return
  clearFlyoutTimer()
  collapsedTooltip.value = null
  const target = event.currentTarget as HTMLElement | null
  if (!target) return
  const rect = target.getBoundingClientRect()
  const estimatedHeight = 44 + group.items.length * 36
  const maxTop =
    typeof window !== 'undefined'
      ? Math.max(8, window.innerHeight - estimatedHeight - 12)
      : rect.top
  const current = isGroupActive(group) ? activeItem.value : null
  const numericCount = getGroupNotificationCount(group)
  activeFlyout.value = {
    id: group.id,
    title: group.title,
    activeItemLabel: current?.label ?? null,
    metaText: numericCount > 0 ? String(numericCount) : undefined,
    items: group.items.map((item) => ({
      id: item.id,
      label: item.label,
      icon: item.icon,
      badge: item.badge,
      isActive: isItemActive(item),
      onSelect: () => navigateTo(item.path),
    })),
    top: Math.min(rect.top, maxTop),
    left: rect.right + 4,
  }
}

const openProfileFlyout = (event: Event) => {
  if (!isCollapsed.value) return
  clearFlyoutTimer()
  collapsedTooltip.value = null
  const target = event.currentTarget as HTMLElement | null
  if (!target) return
  const rect = target.getBoundingClientRect()
  const estimatedHeight = 44 + 2 * 36
  const maxTop =
    typeof window !== 'undefined'
      ? Math.max(8, window.innerHeight - estimatedHeight - 12)
      : rect.top
  activeFlyout.value = {
    id: 'profile',
    title: authSession.value.operatorName,
    activeItemLabel: activeRoleLabel.value,
    items: [
      {
        id: 'profile',
        label: 'Profile',
        icon: 'lucide:user',
        isActive: route.path.startsWith('/account/profile'),
        onSelect: () => navigateTo('/account/profile'),
      },
      {
        id: 'lock-session',
        label: 'Lock Session',
        icon: 'lucide:lock',
        isActive: false,
        onSelect: () => {
          activeFlyout.value = null
          showSignOutConfirm.value = true
        },
      },
    ],
    top: Math.min(rect.top, maxTop),
    left: rect.right + 4,
  }
}

const scheduleCloseFlyout = () => {
  clearFlyoutTimer()
  flyoutCloseTimer = setTimeout(() => {
    activeFlyout.value = null
    flyoutCloseTimer = null
  }, 140)
}

const cancelCloseFlyout = () => {
  clearFlyoutTimer()
}

const showButtonTooltip = (label: string, event: Event) => {
  if (!isCollapsed.value) return
  const target = event.currentTarget as HTMLElement | null
  if (!target) return
  const rect = target.getBoundingClientRect()
  collapsedTooltip.value = {
    label,
    top: rect.top + rect.height / 2,
    left: rect.right + 8,
  }
}

const hideButtonTooltip = () => {
  collapsedTooltip.value = null
}

onBeforeUnmount(() => {
  clearFlyoutTimer()
})

const activeRoleLabel = computed(() => {
  const role = authSession.value.role
  return role ? ROLE_PROFILES[role].label : 'Locked'
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
  isToggleHovered.value = false
  activeFlyout.value = null
  collapsedTooltip.value = null
}

function toggleGroup(groupId: string) {
  expandedGroups.value[groupId] = !expandedGroups.value[groupId]
}

function navigateTo(path: string) {
  activeFlyout.value = null
  collapsedTooltip.value = null
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

function isGroupActive(group: SidebarNavGroup): boolean {
  return group.items.some((item) => isItemActive(item))
}

function getGroupNotificationCount(group: SidebarNavGroup): number {
  return group.items.filter(
    (item) =>
      item.badge !== undefined &&
      (typeof item.badge === 'number' || /^\d+$/.test(item.badge.trim())),
  ).length
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
            <span class="text-[11px] text-neutral-500 font-medium">Pagadian Ops</span>
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
            class="p-1.5 text-neutral-700 hover:text-neutral-900 transition-colors flex items-center justify-center shrink-0 cursor-pointer"
            :aria-label="isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'"
            :title="isCollapsed ? undefined : 'Collapse sidebar'"
            @mouseenter="((isToggleHovered = true), showButtonTooltip('Expand', $event))"
            @mouseleave="((isToggleHovered = false), hideButtonTooltip())"
            @focus="((isToggleHovered = true), showButtonTooltip('Expand', $event))"
            @blur="((isToggleHovered = false), hideButtonTooltip())"
            @click="toggleCollapse"
          >
            <svg
              v-if="isCollapsed && !isToggleHovered"
              data-test="collapsed-brand-logo"
              viewBox="0 0 24 24"
              class="w-5 h-5"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="square"
              stroke-linejoin="miter"
              aria-hidden="true"
            >
              <polygon points="12,2 21,7 21,17 12,22 3,17 3,7" />
              <circle cx="12" cy="12" r="2.5" />
              <line x1="12" y1="2" x2="12" y2="9.5" />
              <line x1="20" y1="16.5" x2="14.2" y2="13.2" />
              <line x1="4" y1="16.5" x2="9.8" y2="13.2" />
            </svg>
            <Icon
              v-else
              data-test="sidebar-toggle-icon"
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

        <div v-else class="flex justify-center py-0.5">
          <button
            type="button"
            :aria-label="group.title"
            :aria-expanded="activeFlyout?.id === group.id"
            aria-haspopup="menu"
            class="relative w-11 h-11 flex items-center justify-center transition-colors cursor-pointer"
            :class="
              isGroupActive(group)
                ? 'bg-neutral-900 text-white'
                : activeFlyout?.id === group.id
                  ? 'bg-neutral-100 text-neutral-900'
                  : 'text-neutral-500 hover:bg-neutral-100 hover:text-neutral-900'
            "
            @mouseenter="openGroupFlyout(group, $event)"
            @mouseleave="scheduleCloseFlyout"
            @focus="openGroupFlyout(group, $event)"
            @blur="scheduleCloseFlyout"
            @click="navigateTo(group.items[0]?.path || '/dashboard/overview')"
          >
            <Icon :icon="group.icon" class="text-base shrink-0" />
            <span
              v-if="getGroupNotificationCount(group) > 0"
              data-test="collapsed-notif-count"
              class="absolute top-0.5 right-0.5 min-w-[16px] h-4 px-1 flex items-center justify-center text-[10px] font-bold leading-none tabular-nums"
              :class="
                isGroupActive(group)
                  ? 'bg-white text-neutral-900 border border-neutral-900'
                  : 'bg-neutral-900 text-white'
              "
            >
              {{ getGroupNotificationCount(group) }}
            </span>
          </button>
        </div>

        <AnimatePresence>
          <motion.div
            v-if="!isCollapsed && (expandedGroups[group.id] || searchQuery)"
            :initial="{ opacity: 0, height: 0 }"
            :animate="{ opacity: 1, height: 'auto' }"
            :exit="{ opacity: 0, height: 0 }"
            :transition="{ duration: 0.2, ease: 'easeInOut' }"
            class="overflow-hidden space-y-0.5 ml-4 pl-2 border-l border-neutral-200 my-0.5"
          >
            <button
              v-for="item in group.items"
              :key="item.id"
              type="button"
              class="w-full flex items-center justify-between px-3 py-2 text-xs font-medium transition-colors group relative"
              :class="
                isItemActive(item)
                  ? 'text-white'
                  : 'text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900'
              "
              @click="navigateTo(item.path)"
            >
              <motion.span
                v-if="isItemActive(item)"
                layoutId="activeSidebarIndicator"
                class="absolute inset-0 rounded-none bg-neutral-900"
                :transition="{ type: 'spring', stiffness: 380, damping: 30 }"
              />

              <div class="relative z-10 flex items-center space-x-2.5 overflow-hidden">
                <span class="truncate">{{ item.label }}</span>
              </div>

              <span
                v-if="item.badge"
                class="relative z-10 text-[10px] px-1.5 py-0.5 rounded-none font-semibold transition-colors"
                :class="
                  isItemActive(item)
                    ? 'bg-neutral-800 text-white'
                    : item.badgeClass || 'bg-neutral-100 text-neutral-700'
                "
              >
                {{ item.badge }}
              </span>
            </button>
          </motion.div>
        </AnimatePresence>
      </div>
    </nav>

    <div class="shrink-0 p-3 border-t border-neutral-200 bg-neutral-50/50">
      <div
        class="flex items-center p-2 transition-colors"
        :class="isCollapsed ? 'justify-center' : 'justify-between hover:bg-neutral-100'"
      >
        <button
          type="button"
          class="flex items-center space-x-3 overflow-hidden text-left focus:outline-none cursor-pointer"
          aria-label="Profile"
          :aria-expanded="isCollapsed ? activeFlyout?.id === 'profile' : undefined"
          :aria-haspopup="isCollapsed ? 'menu' : undefined"
          @mouseenter="isCollapsed ? openProfileFlyout($event) : undefined"
          @mouseleave="isCollapsed ? scheduleCloseFlyout() : undefined"
          @focus="isCollapsed ? openProfileFlyout($event) : undefined"
          @blur="isCollapsed ? scheduleCloseFlyout() : undefined"
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

    <Teleport to="body">
      <div
        v-if="isCollapsed && activeFlyout"
        data-test="collapsed-flyout"
        role="menu"
        :aria-label="activeFlyout.title"
        class="fixed z-50 w-56 bg-white border border-neutral-300 shadow-lg"
        :style="{ top: `${activeFlyout.top}px`, left: `${activeFlyout.left}px` }"
        @mouseenter="cancelCloseFlyout"
        @mouseleave="scheduleCloseFlyout"
      >
        <div
          class="bg-neutral-900 text-white px-3 py-2 flex items-center justify-between gap-2 text-xs font-semibold"
        >
          <span class="truncate">{{ activeFlyout.title }}</span>
          <span
            v-if="activeFlyout.activeItemLabel"
            class="text-[10px] font-medium text-neutral-300 truncate max-w-[110px]"
          >
            {{ activeFlyout.activeItemLabel }}
          </span>
          <span v-else class="text-[10px] font-mono text-neutral-300">
            {{ activeFlyout.metaText ?? activeFlyout.items.length }}
          </span>
        </div>
        <div class="p-1 space-y-0.5 max-h-72 overflow-y-auto">
          <button
            v-for="item in activeFlyout.items"
            :key="item.id"
            type="button"
            role="menuitem"
            :aria-current="item.isActive ? 'page' : undefined"
            class="w-full px-2.5 py-2 text-left text-xs font-medium flex items-center justify-between gap-2 transition-colors cursor-pointer"
            :class="
              item.isActive
                ? 'bg-neutral-900 text-white font-semibold'
                : 'text-neutral-700 hover:bg-neutral-100 hover:text-neutral-900'
            "
            @click="item.onSelect()"
          >
            <span class="flex items-center gap-2 min-w-0">
              <Icon
                :icon="item.icon"
                class="text-sm shrink-0"
                :class="item.isActive ? 'text-white' : 'text-neutral-500'"
              />
              <span class="truncate">{{ item.label }}</span>
            </span>
            <span
              v-if="item.badge"
              class="px-1.5 py-0.5 text-[10px] font-semibold shrink-0"
              :class="item.isActive ? 'bg-white text-neutral-900' : 'bg-neutral-900 text-white'"
            >
              {{ item.badge }}
            </span>
          </button>
        </div>
      </div>

      <div
        v-if="isCollapsed && collapsedTooltip && !activeFlyout"
        data-test="collapsed-tooltip"
        role="tooltip"
        class="fixed z-50 -translate-y-1/2 bg-neutral-900 text-white px-2.5 py-1.5 text-xs font-medium pointer-events-none shadow-sm"
        :style="{ top: `${collapsedTooltip.top}px`, left: `${collapsedTooltip.left}px` }"
      >
        {{ collapsedTooltip.label }}
      </div>
    </Teleport>
  </motion.aside>
</template>
