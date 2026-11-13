<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import Sidebar from '@/app/layouts/Sidebar.vue'

const route = useRoute()
const mobileNavOpen = ref(false)

watch(
  () => route.path,
  () => {
    mobileNavOpen.value = false
  },
)

const routeMap: Record<string, { section: string; sectionTo: string; item: string }> = {
  '/dashboard/overview': {
    section: 'Dashboard',
    sectionTo: '/dashboard/overview',
    item: 'Overview',
  },
  '/users/drivers': { section: 'Users', sectionTo: '/users/drivers', item: 'Drivers' },
  '/users/driver-applications': {
    section: 'Users',
    sectionTo: '/users/drivers',
    item: 'Applications',
  },
  '/users/riders': { section: 'Users', sectionTo: '/users/drivers', item: 'Riders' },
  '/users/operators': {
    section: 'Users',
    sectionTo: '/users/drivers',
    item: 'Operators',
  },
  '/users/roles': {
    section: 'Users',
    sectionTo: '/users/drivers',
    item: 'Staff Roles',
  },
  '/documents/verification': {
    section: 'Documents',
    sectionTo: '/documents/verification',
    item: 'Verification',
  },
  '/documents/expiring': {
    section: 'Documents',
    sectionTo: '/documents/verification',
    item: 'Expiring Docs',
  },
  '/documents/rejected': {
    section: 'Documents',
    sectionTo: '/documents/verification',
    item: 'Rejected Docs',
  },
  '/trips/all': { section: 'Trips', sectionTo: '/trips/all', item: 'All Trips' },
  '/trips/bidding': { section: 'Trips', sectionTo: '/trips/all', item: 'Live Bidding' },
  '/trips/dispatch': { section: 'Trips', sectionTo: '/trips/all', item: 'Dispatch' },
  '/trips/cancellations-disputes': {
    section: 'Trips',
    sectionTo: '/trips/all',
    item: 'Disputes',
  },
  '/trips/sos-alerts': { section: 'Trips', sectionTo: '/trips/all', item: 'SOS Alerts' },
  '/trips/safety-reports': { section: 'Trips', sectionTo: '/trips/all', item: 'Safety Reports' },
  '/payments/topups': {
    section: 'Payments',
    sectionTo: '/payments/topups',
    item: 'Top-Ups',
  },
  '/payments/settlements': {
    section: 'Payments',
    sectionTo: '/payments/topups',
    item: 'Settlements',
  },
  '/payments/transactions': {
    section: 'Payments',
    sectionTo: '/payments/topups',
    item: 'Transactions',
  },
  '/payments/earnings': {
    section: 'Payments',
    sectionTo: '/payments/topups',
    item: 'Earnings',
  },
  '/payments/wallet': {
    section: 'Payments',
    sectionTo: '/payments/topups',
    item: 'Wallets',
  },
  '/payments/refunds': {
    section: 'Payments',
    sectionTo: '/payments/topups',
    item: 'Refunds',
  },
  '/payments/fare-pricing': {
    section: 'Payments',
    sectionTo: '/payments/topups',
    item: 'Tariff Rates',
  },
  '/payments/commission-settings': {
    section: 'Payments',
    sectionTo: '/payments/topups',
    item: 'Commissions',
  },
  '/payments/methods': {
    section: 'Payments',
    sectionTo: '/payments/topups',
    item: 'Channels',
  },
  '/reports/trips': { section: 'Reports', sectionTo: '/reports/trips', item: 'Trips' },
  '/reports/revenue': { section: 'Reports', sectionTo: '/reports/trips', item: 'Revenue' },
  '/reports/driver-performance': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Driver Stats',
  },
  '/reports/rider-activity': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Rider Stats',
  },
  '/reports/cancellations': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Cancellations',
  },
  '/reports/peak-hours': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Peak Demand',
  },
  '/reports/document-expiry': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Expiry Forecast',
  },
  '/reports/export-center': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Exports',
  },
  '/support/tickets': {
    section: 'Support',
    sectionTo: '/support/tickets',
    item: 'Tickets',
  },
  '/support/ratings-reviews': {
    section: 'Support',
    sectionTo: '/support/tickets',
    item: 'Reviews',
  },
  '/support/lost-found': {
    section: 'Support',
    sectionTo: '/support/tickets',
    item: 'Lost Items',
  },
  '/support/faqs': {
    section: 'Support',
    sectionTo: '/support/tickets',
    item: 'Help Center',
  },
  '/settings/service-zones': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Service Zones',
  },
  '/settings/cities': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Cities',
  },
  '/settings/content': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Policies',
  },
  '/settings/app-settings': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Preferences',
  },
  '/settings/audit-logs': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Audit Logs',
  },
  '/account/profile': { section: 'Account', sectionTo: '/account/profile', item: 'Profile' },
  '/unauthorized': {
    section: 'Security',
    sectionTo: '/dashboard/overview',
    item: 'Restricted Access',
  },
}

interface BreadcrumbItem {
  label: string
  to?: string
}

const breadcrumbs = computed<BreadcrumbItem[]>(() => {
  const match = routeMap[route.path]
  if (match) {
    if (match.item === match.section) {
      return [{ label: match.section }]
    }
    return [{ label: match.section, to: match.sectionTo }, { label: match.item }]
  }

  const parts = route.path.split('/').filter(Boolean)
  if (parts.length >= 3) {
    const parentPath = `/${parts[0]}/${parts[1]}`
    const parentMatch = routeMap[parentPath]
    const detailId = (route.params.id as string) || parts.slice(2).join('/')
    if (parentMatch) {
      return [
        { label: parentMatch.section, to: parentMatch.sectionTo },
        { label: parentMatch.item, to: parentPath },
        { label: `#${detailId}` },
      ]
    }
  }

  const sec = parts[0] ? parts[0].charAt(0).toUpperCase() + parts[0].slice(1) : 'Dashboard'
  const itm = parts[1]
    ? parts[1].replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
    : 'Overview'
  if (sec === itm) {
    return [{ label: sec }]
  }
  return [{ label: sec, to: `/${parts[0] || 'dashboard/overview'}` }, { label: itm }]
})
</script>

<template>
  <div class="h-screen bg-neutral-50 flex overflow-hidden font-sans text-neutral-900">
    <div
      v-if="mobileNavOpen"
      class="fixed inset-0 z-30 bg-black/40 lg:hidden"
      aria-hidden="true"
      @click="mobileNavOpen = false"
    />

    <Sidebar :mobile-open="mobileNavOpen" @close-mobile="mobileNavOpen = false" />

    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      <header
        class="h-16 border-b border-neutral-200 bg-white px-4 sm:px-6 flex items-center justify-between gap-4 shrink-0 select-none"
      >
        <div class="flex items-center gap-3 min-w-0">
          <button
            type="button"
            class="lg:hidden p-1.5 border border-neutral-200 text-neutral-700 hover:bg-neutral-100 transition-colors cursor-pointer"
            aria-label="Open navigation menu"
            @click="mobileNavOpen = true"
          >
            <Icon icon="lucide:menu" class="text-base" aria-hidden="true" />
          </button>

          <nav aria-label="Breadcrumb" class="flex items-center space-x-2 text-xs min-w-0 truncate">
            <RouterLink
              to="/dashboard/overview"
              class="text-neutral-400 hover:text-neutral-900 transition-colors flex items-center shrink-0"
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

      <main class="flex-1 min-w-0 overflow-y-auto overflow-x-hidden p-4 sm:p-6 bg-neutral-50">
        <slot />
      </main>
    </div>
  </div>
</template>
