<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'

export interface SidebarSubItem {
  id: string
  label: string
  icon: string
  badge?: string | number
  badgeClass?: string
}

export interface SidebarNavGroup {
  id: string
  title: string
  icon: string
  items: SidebarSubItem[]
}

const isCollapsed = ref(false)
const searchQuery = ref('')
const activeItemId = ref('overview')

// Keep track of which groups are expanded in normal view
const expandedGroups = ref<Record<string, boolean>>({
  dashboard: true,
  users: true,
  trips: true,
  reports: false,
  payment: false,
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
    items: [{ id: 'overview', label: 'Overview', icon: 'lucide:gauge' }],
  },
  {
    id: 'users',
    title: 'Users',
    icon: 'lucide:users',
    items: [
      { id: 'drivers', label: 'Drivers', icon: 'lucide:id-card' },
      {
        id: 'driver-applications',
        label: 'Driver Applications',
        icon: 'lucide:user-plus',
        badge: '8',
        badgeClass: 'bg-amber-100 text-amber-800',
      },
      { id: 'riders', label: 'Riders', icon: 'lucide:user' },
      { id: 'admin-users-roles', label: 'Admin Users & Roles', icon: 'lucide:shield-check' },
    ],
  },
  {
    id: 'vehicle',
    title: 'Vehicle',
    icon: 'lucide:car-taxi-front',
    items: [
      { id: 'vehicles', label: 'Vehicles', icon: 'lucide:car' },
      { id: 'vehicle-types', label: 'Vehicle Types', icon: 'lucide:layers' },
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
        badge: '12',
        badgeClass: 'bg-blue-100 text-blue-800',
      },
      {
        id: 'expiring-documents',
        label: 'Expiring Documents',
        icon: 'lucide:file-clock',
        badge: '4',
        badgeClass: 'bg-amber-100 text-amber-800',
      },
      { id: 'rejected-documents', label: 'Rejected Documents', icon: 'lucide:file-x' },
    ],
  },
  {
    id: 'trips',
    title: 'Trips',
    icon: 'lucide:route',
    items: [
      { id: 'all-trips', label: 'All Trips', icon: 'lucide:navigation' },
      { id: 'scheduled-bookings', label: 'Scheduled Bookings', icon: 'lucide:calendar-clock' },
      {
        id: 'dispatch',
        label: 'Dispatch',
        icon: 'lucide:radio',
        badge: 'Live',
        badgeClass: 'bg-emerald-100 text-emerald-800',
      },
      {
        id: 'cancellations-disputes',
        label: 'Cancellations & Disputes',
        icon: 'lucide:alert-triangle',
      },
      {
        id: 'sos-alerts',
        label: 'SOS Alerts',
        icon: 'lucide:siren',
        badge: '2',
        badgeClass: 'bg-rose-500 text-white font-bold animate-pulse',
      },
    ],
  },
  {
    id: 'payment',
    title: 'Payment',
    icon: 'lucide:credit-card',
    items: [
      { id: 'transactions', label: 'Transactions', icon: 'lucide:receipt' },
      { id: 'driver-earnings', label: 'Driver Earnings', icon: 'lucide:banknote' },
      {
        id: 'payout-requests',
        label: 'Payout Requests',
        icon: 'lucide:arrow-up-right',
        badge: '5',
        badgeClass: 'bg-blue-100 text-blue-800',
      },
      { id: 'wallet', label: 'Wallet', icon: 'lucide:wallet' },
      { id: 'refunds', label: 'Refunds', icon: 'lucide:rotate-ccw' },
      { id: 'fare-pricing', label: 'Fare & Pricing', icon: 'lucide:calculator' },
      { id: 'commission-settings', label: 'Commission Settings', icon: 'lucide:percent' },
      { id: 'payment-methods', label: 'Payment Methods', icon: 'lucide:credit-card' },
    ],
  },
  {
    id: 'reports',
    title: 'Reports',
    icon: 'lucide:bar-chart-3',
    items: [
      { id: 'trip-reports', label: 'Trip Reports', icon: 'lucide:chart-pie' },
      { id: 'revenue-reports', label: 'Revenue Reports', icon: 'lucide:trending-up' },
      { id: 'driver-performance', label: 'Driver Performance', icon: 'lucide:award' },
      { id: 'rider-activity', label: 'Rider Activity', icon: 'lucide:activity' },
      { id: 'cancellation-report', label: 'Cancellation Report', icon: 'lucide:chart-bar' },
      { id: 'peak-hours-demand', label: 'Peak Hours & Demand', icon: 'lucide:flame' },
      { id: 'payout-report', label: 'Payout Report', icon: 'lucide:file-spreadsheet' },
      { id: 'document-expiry-report', label: 'Document Expiry Report', icon: 'lucide:calendar-x' },
      { id: 'tax-invoice-reports', label: 'Tax / Invoice Reports', icon: 'lucide:receipt-text' },
      {
        id: 'export-center',
        label: 'Export Center (CSV, PDF, Excel)',
        icon: 'lucide:download',
        badge: 'Export',
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
        badge: '3',
        badgeClass: 'bg-amber-100 text-amber-800',
      },
      { id: 'ratings-reviews', label: 'Ratings & Reviews', icon: 'lucide:star' },
      { id: 'lost-found', label: 'Lost & Found', icon: 'lucide:package-search' },
      { id: 'faqs-help-center', label: 'FAQs / Help Center', icon: 'lucide:help-circle' },
    ],
  },
  {
    id: 'settings',
    title: 'Settings',
    icon: 'lucide:settings-2',
    items: [
      { id: 'service-areas-zones', label: 'Service Areas / Zones', icon: 'lucide:map' },
      { id: 'cities-regions', label: 'Cities / Regions', icon: 'lucide:building-2' },
      { id: 'taxes', label: 'Taxes', icon: 'lucide:scale' },
      { id: 'languages', label: 'Languages', icon: 'lucide:languages' },
      { id: 'content-pages', label: 'Content Pages (Terms, Privacy)', icon: 'lucide:file-text' },
      { id: 'app-settings', label: 'App Settings', icon: 'lucide:sliders-horizontal' },
      { id: 'audit-logs', label: 'Audit Logs', icon: 'lucide:history' },
    ],
  },
]

function toggleCollapse() {
  isCollapsed.value = !isCollapsed.value
}

function toggleGroup(groupId: string) {
  expandedGroups.value[groupId] = !expandedGroups.value[groupId]
}

function selectItem(itemId: string) {
  activeItemId.value = itemId
}

// Filter items when search query is entered
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
  <aside
    class="bg-white border-r border-neutral-200 flex flex-col justify-between transition-all duration-300 ease-in-out shrink-0 select-none h-screen sticky top-0"
    :class="isCollapsed ? 'w-20' : 'w-72'"
    aria-label="Admin Navigation Sidebar"
  >
    <!-- Top Branding & Collapse Button -->
    <div class="shrink-0">
      <div class="h-16 flex items-center px-4 border-b border-neutral-100 justify-between">
        <div class="flex items-center space-x-3 overflow-hidden">
          <div
            class="w-10 h-10 rounded-lg bg-neutral-900 flex items-center justify-center text-white shrink-0 shadow-sm"
          >
            <Icon icon="lucide:car-taxi-front" class="text-xl" />
          </div>
          <div v-if="!isCollapsed" class="flex flex-col overflow-hidden whitespace-nowrap">
            <span class="font-bold text-base text-neutral-900 leading-tight">EasyRide</span>
            <span class="text-xs text-neutral-500 font-medium">Admin Portal</span>
          </div>
        </div>

        <button
          type="button"
          class="p-1.5 rounded-md text-neutral-500 hover:text-neutral-900 hover:bg-neutral-100 transition-colors"
          :aria-label="isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'"
          @click="toggleCollapse"
        >
          <Icon
            :icon="isCollapsed ? 'lucide:panel-left-open' : 'lucide:panel-left-close'"
            class="text-lg"
          />
        </button>
      </div>

      <!-- Quick Search (Shown only when expanded) -->
      <div v-if="!isCollapsed" class="p-3 border-b border-neutral-100">
        <div class="relative">
          <Icon icon="lucide:search" class="absolute left-2.5 top-2.5 text-neutral-400 text-sm" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search navigation..."
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

        <!-- Subitems (Visible when expanded or searching, or in collapsed mode) -->
        <div v-show="isCollapsed || expandedGroups[group.id] || searchQuery" class="space-y-0.5">
          <button
            v-for="item in group.items"
            :key="item.id"
            type="button"
            class="w-full flex items-center rounded-lg text-xs font-medium transition-all group relative"
            :class="[
              activeItemId === item.id
                ? 'bg-neutral-900 text-white shadow-sm'
                : 'text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900',
              isCollapsed ? 'justify-center p-2.5' : 'justify-between px-3 py-2',
            ]"
            :title="isCollapsed ? `${group.title}: ${item.label}` : undefined"
            @click="selectItem(item.id)"
          >
            <div class="flex items-center space-x-2.5 overflow-hidden">
              <Icon
                :icon="item.icon"
                class="text-base shrink-0"
                :class="
                  activeItemId === item.id
                    ? 'text-white'
                    : 'text-neutral-400 group-hover:text-neutral-900'
                "
              />
              <span v-if="!isCollapsed" class="truncate">{{ item.label }}</span>
            </div>

            <!-- Item Badge -->
            <span
              v-if="!isCollapsed && item.badge"
              class="text-[10px] px-1.5 py-0.5 rounded-full font-semibold"
              :class="item.badgeClass || 'bg-neutral-100 text-neutral-700'"
            >
              {{ item.badge }}
            </span>

            <!-- Compact Badge Indicator when Collapsed -->
            <span
              v-if="isCollapsed && item.badge"
              class="absolute top-1.5 right-1.5 w-2 h-2 rounded-full"
              :class="item.id === 'sos-alerts' ? 'bg-rose-500 animate-ping' : 'bg-neutral-800'"
            />
          </button>
        </div>
      </div>
    </nav>

    <!-- Bottom Account Section -->
    <div class="shrink-0 p-3 border-t border-neutral-100 bg-neutral-50/50">
      <div
        class="flex items-center rounded-lg p-2 hover:bg-neutral-100 transition-colors"
        :class="isCollapsed ? 'justify-center' : 'justify-between'"
      >
        <button
          type="button"
          class="flex items-center space-x-3 overflow-hidden text-left focus:outline-none"
          :title="isCollapsed ? 'Admin Profile' : undefined"
          @click="selectItem('profile')"
        >
          <div
            class="w-8 h-8 rounded-full bg-neutral-900 text-white flex items-center justify-center font-semibold text-xs shrink-0 shadow-sm"
          >
            AD
          </div>
          <div v-if="!isCollapsed" class="flex flex-col overflow-hidden whitespace-nowrap">
            <span class="text-xs font-semibold text-neutral-900 truncate">Admin User</span>
            <span class="text-[11px] text-neutral-500 truncate">Super Administrator</span>
          </div>
        </button>

        <!-- Logout Action Button -->
        <button
          v-if="!isCollapsed"
          type="button"
          class="text-neutral-400 hover:text-rose-600 p-1.5 rounded-md hover:bg-rose-50 transition-colors"
          title="Logout"
          aria-label="Logout"
          @click="selectItem('logout')"
        >
          <Icon icon="lucide:log-out" class="text-base" />
        </button>
      </div>
    </div>
  </aside>
</template>
