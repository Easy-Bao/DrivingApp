<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { motion, AnimatePresence } from 'motion-v'

export interface SidebarSubItem {
  id: string
  label: string
  icon: string
  path: string
  badge?: string | number
  badgeClass?: string
}

export interface SidebarNavGroup {
  id: string
  title: string
  icon: string
  items: SidebarSubItem[]
}

const route = useRoute()
const router = useRouter()

const isCollapsed = ref(false)
const searchQuery = ref('')

const expandedGroups = ref<Record<string, boolean>>({
  dashboard: true,
  users: true,
  trips: true,
  payment: true,
  reports: false,
  vehicle: false,
  documents: false,
  support: false,
  settings: false,
})

const navigationGroups: SidebarNavGroup[] = [
  {
    id: 'dashboard',
    title: 'Dashboard',
    icon: 'lucide:layout-dashboard',
    items: [
      { id: 'overview', label: 'Overview', icon: 'lucide:gauge', path: '/dashboard/overview' },
    ],
  },
  {
    id: 'users',
    title: 'Users',
    icon: 'lucide:users',
    items: [
      { id: 'drivers', label: 'Drivers', icon: 'lucide:id-card', path: '/users/drivers' },
      {
        id: 'driver-applications',
        label: 'Driver Applications',
        icon: 'lucide:user-plus',
        path: '/users/driver-applications',
        badge: '8',
        badgeClass: 'bg-amber-100 text-amber-800',
      },
      { id: 'riders', label: 'Riders', icon: 'lucide:user', path: '/users/riders' },
      {
        id: 'admin-users-roles',
        label: 'Admin Users & Roles',
        icon: 'lucide:shield-check',
        path: '/users/admin-users-roles',
      },
    ],
  },
  {
    id: 'vehicle',
    title: 'Vehicle',
    icon: 'lucide:car-taxi-front',
    items: [
      { id: 'vehicles', label: 'Vehicles', icon: 'lucide:car', path: '/vehicle/vehicles' },
      {
        id: 'vehicle-types',
        label: 'Vehicle Types',
        icon: 'lucide:layers',
        path: '/vehicle/vehicle-types',
      },
    ],
  },
  {
    id: 'documents',
    title: 'Documents',
    icon: 'lucide:file-check',
    items: [
      {
        id: 'document-verification',
        label: 'Document Verification',
        icon: 'lucide:file-badge',
        path: '/documents/document-verification',
        badge: '12',
        badgeClass: 'bg-blue-100 text-blue-800',
      },
      {
        id: 'expiring-documents',
        label: 'Expiring Documents',
        icon: 'lucide:file-clock',
        path: '/documents/expiring-documents',
        badge: '4',
        badgeClass: 'bg-amber-100 text-amber-800',
      },
      {
        id: 'rejected-documents',
        label: 'Rejected Documents',
        icon: 'lucide:file-x',
        path: '/documents/rejected-documents',
      },
    ],
  },
  {
    id: 'trips',
    title: 'Trips',
    icon: 'lucide:route',
    items: [
      {
        id: 'all-trips',
        label: 'All Trips',
        icon: 'lucide:navigation',
        path: '/trips/all-trips',
      },
      {
        id: 'scheduled-bookings',
        label: 'Scheduled Bookings',
        icon: 'lucide:calendar-clock',
        path: '/trips/scheduled-bookings',
      },
      {
        id: 'dispatch',
        label: 'Dispatch',
        icon: 'lucide:radio',
        path: '/trips/dispatch',
        badge: 'Live',
        badgeClass: 'bg-emerald-100 text-emerald-800',
      },
      {
        id: 'cancellations-disputes',
        label: 'Cancellations & Disputes',
        icon: 'lucide:alert-triangle',
        path: '/trips/cancellations-disputes',
      },
      {
        id: 'sos-alerts',
        label: 'SOS Alerts',
        icon: 'lucide:siren',
        path: '/trips/sos-alerts',
        badge: '2',
        badgeClass: 'bg-rose-500 text-white font-bold animate-pulse',
      },
    ],
  },
  {
    id: 'payment',
    title: 'Payment & Wallet',
    icon: 'lucide:credit-card',
    items: [
      {
        id: 'driver-topups',
        label: 'Driver Top-Ups (Verify)',
        icon: 'lucide:wallet',
        path: '/payment/driver-topups',
        badge: '3',
        badgeClass: 'bg-amber-100 text-amber-800 font-bold',
      },
      {
        id: 'transactions',
        label: 'Transactions',
        icon: 'lucide:receipt',
        path: '/payment/transactions',
      },
      {
        id: 'driver-earnings',
        label: 'Driver Earnings',
        icon: 'lucide:banknote',
        path: '/payment/driver-earnings',
      },
      {
        id: 'payout-requests',
        label: 'Payout Requests',
        icon: 'lucide:arrow-up-right',
        path: '/payment/payout-requests',
        badge: '5',
        badgeClass: 'bg-blue-100 text-blue-800',
      },
      {
        id: 'wallet',
        label: 'Driver Wallet',
        icon: 'lucide:wallet-cards',
        path: '/payment/wallet',
      },
      { id: 'refunds', label: 'Refunds', icon: 'lucide:rotate-ccw', path: '/payment/refunds' },
      {
        id: 'fare-pricing',
        label: 'Fare & Pricing',
        icon: 'lucide:calculator',
        path: '/payment/fare-pricing',
      },
      {
        id: 'commission-settings',
        label: 'Commission Settings',
        icon: 'lucide:percent',
        path: '/payment/commission-settings',
      },
      {
        id: 'payment-methods',
        label: 'Company Bank & QR',
        icon: 'lucide:qr-code',
        path: '/payment/payment-methods',
      },
    ],
  },
  {
    id: 'reports',
    title: 'Reports',
    icon: 'lucide:bar-chart-3',
    items: [
      {
        id: 'trip-reports',
        label: 'Trip Reports',
        icon: 'lucide:chart-pie',
        path: '/reports/trip-reports',
      },
      {
        id: 'revenue-reports',
        label: 'Revenue Reports',
        icon: 'lucide:trending-up',
        path: '/reports/revenue-reports',
      },
      {
        id: 'driver-performance',
        label: 'Driver Performance',
        icon: 'lucide:award',
        path: '/reports/driver-performance',
      },
      {
        id: 'rider-activity',
        label: 'Rider Activity',
        icon: 'lucide:activity',
        path: '/reports/rider-activity',
      },
      {
        id: 'cancellation-report',
        label: 'Cancellation Report',
        icon: 'lucide:chart-bar',
        path: '/reports/cancellation-report',
      },
      {
        id: 'peak-hours-demand',
        label: 'Peak Hours & Demand',
        icon: 'lucide:flame',
        path: '/reports/peak-hours-demand',
      },
      {
        id: 'payout-report',
        label: 'Payout Report',
        icon: 'lucide:file-spreadsheet',
        path: '/reports/payout-report',
      },
      {
        id: 'document-expiry-report',
        label: 'Document Expiry Report',
        icon: 'lucide:calendar-x',
        path: '/reports/document-expiry-report',
      },
      {
        id: 'tax-invoice-reports',
        label: 'Tax / Invoice Reports',
        icon: 'lucide:receipt-text',
        path: '/reports/tax-invoice-reports',
      },
      {
        id: 'export-center',
        label: 'Export Center (CSV, PDF, Excel)',
        icon: 'lucide:download',
        path: '/reports/export-center',
        badge: 'Auto',
        badgeClass: 'bg-purple-100 text-purple-800',
      },
    ],
  },
  {
    id: 'support',
    title: 'Support',
    icon: 'lucide:headset',
    items: [
      {
        id: 'tickets-complaints',
        label: 'Tickets / Complaints',
        icon: 'lucide:message-square-warning',
        path: '/support/tickets-complaints',
        badge: '3',
        badgeClass: 'bg-amber-100 text-amber-800',
      },
      {
        id: 'ratings-reviews',
        label: 'Ratings & Reviews',
        icon: 'lucide:star',
        path: '/support/ratings-reviews',
      },
      {
        id: 'lost-found',
        label: 'Lost & Found',
        icon: 'lucide:package-search',
        path: '/support/lost-found',
      },
      {
        id: 'faqs-help-center',
        label: 'FAQs / Help Center',
        icon: 'lucide:help-circle',
        path: '/support/faqs-help-center',
      },
    ],
  },
  {
    id: 'settings',
    title: 'Settings',
    icon: 'lucide:settings-2',
    items: [
      {
        id: 'service-areas-zones',
        label: 'Service Areas / Zones',
        icon: 'lucide:map',
        path: '/settings/service-areas-zones',
      },
      {
        id: 'cities-regions',
        label: 'Cities / Regions',
        icon: 'lucide:building-2',
        path: '/settings/cities-regions',
      },
      { id: 'taxes', label: 'Taxes', icon: 'lucide:scale', path: '/settings/taxes' },
      {
        id: 'languages',
        label: 'Languages',
        icon: 'lucide:languages',
        path: '/settings/languages',
      },
      {
        id: 'content-pages',
        label: 'Content Pages (Terms, Privacy)',
        icon: 'lucide:file-text',
        path: '/settings/content-pages',
      },
      {
        id: 'app-settings',
        label: 'App Settings',
        icon: 'lucide:sliders-horizontal',
        path: '/settings/app-settings',
      },
      {
        id: 'audit-logs',
        label: 'Audit Logs',
        icon: 'lucide:history',
        path: '/settings/audit-logs',
      },
    ],
  },
]

function toggleCollapse() {
  isCollapsed.value = !isCollapsed.value
}

function toggleGroup(groupId: string) {
  expandedGroups.value[groupId] = !expandedGroups.value[groupId]
}

function navigateTo(path: string) {
  void router.push(path)
}

function isItemActive(item: SidebarSubItem): boolean {
  if (route.path === '/dashboard/overview' && item.id === 'overview') return true
  return route.path === item.path
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
    class="bg-white border-r border-neutral-200 flex flex-col justify-between shrink-0 select-none h-screen sticky top-0 z-20 overflow-hidden"
    :class="isCollapsed ? 'w-20' : 'w-72'"
    aria-label="Navigation Sidebar"
  >
    <!-- Top Header: Exactly h-16 (64px) with border-b border-neutral-200 to align flush with top bar -->
    <div class="shrink-0">
      <div
        class="h-16 flex items-center border-b border-neutral-200 transition-all duration-300"
        :class="isCollapsed ? 'justify-center px-2' : 'justify-between px-4'"
      >
        <!-- Expanded Brand Display -->
        <div v-if="!isCollapsed" class="flex items-center space-x-3 overflow-hidden min-w-0">
          <div
            class="w-9 h-9 rounded-lg bg-neutral-900 flex items-center justify-center text-white shrink-0 shadow-sm"
          >
            <Icon icon="lucide:car-taxi-front" class="text-lg" />
          </div>
          <div class="flex flex-col overflow-hidden whitespace-nowrap">
            <span class="font-bold text-sm text-neutral-900 leading-tight">EasyRide</span>
            <span class="text-[11px] text-neutral-500 font-medium">Fleet Administration</span>
          </div>
        </div>

        <!-- Toggle Button: Centered in collapsed mode (w-10 h-10), on right in expanded mode -->
        <button
          type="button"
          class="rounded-lg text-neutral-600 hover:text-neutral-900 hover:bg-neutral-100 transition-colors flex items-center justify-center shrink-0"
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

      <!-- Quick Search Filter (Expanded only) -->
      <div v-if="!isCollapsed" class="p-3 border-b border-neutral-100">
        <div class="relative">
          <Icon icon="lucide:search" class="absolute left-2.5 top-2.5 text-neutral-400 text-sm" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search all 40+ sections..."
            class="w-full pl-8 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 rounded-lg text-xs placeholder:text-neutral-400 focus:outline-none focus:ring-1 focus:ring-neutral-900 focus:bg-white transition-all"
          />
        </div>
      </div>
    </div>

    <!-- Scrollable Navigation Groups -->
    <nav class="flex-1 overflow-y-auto px-3 py-3 space-y-3">
      <div v-for="group in filteredGroups" :key="group.id" class="space-y-1">
        <!-- Group Header Button (Accordion) -->
        <button
          v-if="!isCollapsed"
          type="button"
          class="w-full flex items-center justify-between px-2.5 py-1.5 text-xs font-semibold uppercase tracking-wider text-neutral-400 hover:text-neutral-700 rounded-md transition-colors"
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

        <!-- Divider in Collapsed Mode -->
        <div v-else class="h-px bg-neutral-100 my-2 mx-2" :title="group.title" />

        <!-- Subitems with motion-v expansion animation -->
        <AnimatePresence>
          <motion.div
            v-if="isCollapsed || expandedGroups[group.id] || searchQuery"
            :initial="{ opacity: 0, height: 0 }"
            :animate="{ opacity: 1, height: 'auto' }"
            :exit="{ opacity: 0, height: 0 }"
            :transition="{ duration: 0.2, ease: 'easeInOut' }"
            class="overflow-hidden space-y-0.5"
          >
            <button
              v-for="item in group.items"
              :key="item.id"
              type="button"
              class="w-full flex items-center rounded-lg text-xs font-medium transition-colors group relative"
              :class="[
                isItemActive(item)
                  ? 'text-white'
                  : 'text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900',
                isCollapsed ? 'justify-center p-2.5' : 'justify-between px-3 py-2',
              ]"
              :title="isCollapsed ? `${group.title}: ${item.label}` : undefined"
              @click="navigateTo(item.path)"
            >
              <!-- motion-v active indicator pill -->
              <motion.span
                v-if="isItemActive(item)"
                layoutId="activeSidebarIndicator"
                class="absolute inset-0 bg-neutral-900 rounded-lg shadow-sm"
                :transition="{ type: 'spring', stiffness: 380, damping: 30 }"
              />

              <div class="relative z-10 flex items-center space-x-2.5 overflow-hidden">
                <Icon
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

              <!-- Item Badge -->
              <span
                v-if="!isCollapsed && item.badge"
                class="relative z-10 text-[10px] px-1.5 py-0.5 rounded-full font-semibold transition-colors"
                :class="
                  isItemActive(item)
                    ? 'bg-neutral-800 text-white'
                    : item.badgeClass || 'bg-neutral-100 text-neutral-700'
                "
              >
                {{ item.badge }}
              </span>

              <!-- Compact Dot Badge in Collapsed Mode -->
              <span
                v-if="isCollapsed && item.badge"
                class="relative z-10 absolute top-1.5 right-1.5 w-2 h-2 rounded-full"
                :class="
                  item.id === 'sos-alerts'
                    ? 'bg-rose-500 animate-ping'
                    : item.id === 'driver-topups'
                      ? 'bg-amber-500'
                      : 'bg-neutral-800'
                "
              />
            </button>
          </motion.div>
        </AnimatePresence>
      </div>
    </nav>

    <!-- Bottom Account Section -->
    <div class="shrink-0 p-3 border-t border-neutral-200 bg-neutral-50/50">
      <div
        class="flex items-center rounded-lg p-2 hover:bg-neutral-100 transition-colors"
        :class="isCollapsed ? 'justify-center' : 'justify-between'"
      >
        <button
          type="button"
          class="flex items-center space-x-3 overflow-hidden text-left focus:outline-none"
          :title="isCollapsed ? 'Profile' : undefined"
          @click="navigateTo('/profile')"
        >
          <div
            class="w-8 h-8 rounded-full bg-neutral-900 text-white flex items-center justify-center font-semibold text-xs shrink-0 shadow-sm"
          >
            AD
          </div>
          <div v-if="!isCollapsed" class="flex flex-col overflow-hidden whitespace-nowrap">
            <span class="text-xs font-semibold text-neutral-900 truncate">Admin User</span>
            <span class="text-[11px] text-neutral-500 truncate">Super Admin</span>
          </div>
        </button>

        <!-- Logout Action Button -->
        <button
          v-if="!isCollapsed"
          type="button"
          class="text-neutral-400 hover:text-rose-600 p-1.5 rounded-md hover:bg-rose-50 transition-colors"
          title="Sign out"
          aria-label="Sign out"
          @click="navigateTo('/profile')"
        >
          <Icon icon="lucide:log-out" class="text-base" />
        </button>
      </div>
    </div>
  </motion.aside>
</template>
