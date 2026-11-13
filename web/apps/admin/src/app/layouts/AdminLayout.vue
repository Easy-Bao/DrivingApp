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
  '/users/drivers': { section: 'Users & Fleet', sectionTo: '/users/drivers', item: 'Drivers' },
  '/users/driver-applications': {
    section: 'Users & Fleet',
    sectionTo: '/users/drivers',
    item: 'Driver Applications',
  },
  '/users/riders': { section: 'Users & Fleet', sectionTo: '/users/drivers', item: 'Riders' },
  '/users/admin-users': {
    section: 'Users & Fleet',
    sectionTo: '/users/drivers',
    item: 'Admin Users',
  },
  '/users/roles': {
    section: 'Users & Fleet',
    sectionTo: '/users/drivers',
    item: 'Staff Roles & RBAC',
  },
  '/documents/verification': {
    section: 'Documents',
    sectionTo: '/documents/verification',
    item: 'Document Verification',
  },
  '/documents/expiring': {
    section: 'Documents',
    sectionTo: '/documents/verification',
    item: 'Expiring Documents',
  },
  '/documents/rejected': {
    section: 'Documents',
    sectionTo: '/documents/verification',
    item: 'Rejected Documents',
  },
  '/trips/all': { section: 'Trips', sectionTo: '/trips/all', item: 'All Trips' },
  '/trips/bidding': { section: 'Trips', sectionTo: '/trips/all', item: 'Live Bidding Monitor' },
  '/trips/dispatch': { section: 'Trips', sectionTo: '/trips/all', item: 'Live Dispatch Radar' },
  '/trips/cancellations-disputes': {
    section: 'Trips',
    sectionTo: '/trips/all',
    item: 'Cancellations & Disputes',
  },
  '/trips/sos-alerts': { section: 'Trips', sectionTo: '/trips/all', item: 'SOS Emergency Alerts' },
  '/payments/topups': {
    section: 'Payment & Wallet',
    sectionTo: '/payments/topups',
    item: 'Driver Top-Ups (Verify)',
  },
  '/payments/transactions': {
    section: 'Payment & Wallet',
    sectionTo: '/payments/topups',
    item: 'Transactions',
  },
  '/payments/earnings': {
    section: 'Payment & Wallet',
    sectionTo: '/payments/topups',
    item: 'Driver Earnings',
  },
  '/payments/payout-requests': {
    section: 'Payment & Wallet',
    sectionTo: '/payments/topups',
    item: 'Payout Requests',
  },
  '/payments/wallet': {
    section: 'Payment & Wallet',
    sectionTo: '/payments/topups',
    item: 'Driver Wallet',
  },
  '/payments/refunds': {
    section: 'Payment & Wallet',
    sectionTo: '/payments/topups',
    item: 'Refunds',
  },
  '/payments/fare-pricing': {
    section: 'Payment & Wallet',
    sectionTo: '/payments/topups',
    item: 'Fare & Pricing',
  },
  '/payments/commission-settings': {
    section: 'Payment & Wallet',
    sectionTo: '/payments/topups',
    item: 'Commission Settings',
  },
  '/payments/methods': {
    section: 'Payment & Wallet',
    sectionTo: '/payments/topups',
    item: 'Company Bank & QR',
  },
  '/reports/trips': { section: 'Reports', sectionTo: '/reports/trips', item: 'Trip Reports' },
  '/reports/revenue': { section: 'Reports', sectionTo: '/reports/trips', item: 'Revenue Reports' },
  '/reports/driver-performance': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Driver Performance',
  },
  '/reports/rider-activity': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Rider Activity',
  },
  '/reports/cancellations': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Cancellation Report',
  },
  '/reports/peak-hours': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Peak Hours & Demand',
  },
  '/reports/payouts': { section: 'Reports', sectionTo: '/reports/trips', item: 'Payout Report' },
  '/reports/document-expiry': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Document Expiry Report',
  },
  '/reports/tax-invoices': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Tax / Invoice Reports',
  },
  '/reports/export-center': {
    section: 'Reports',
    sectionTo: '/reports/trips',
    item: 'Export Center',
  },
  '/support/tickets': {
    section: 'Support',
    sectionTo: '/support/tickets',
    item: 'Tickets / Complaints',
  },
  '/support/ratings-reviews': {
    section: 'Support',
    sectionTo: '/support/tickets',
    item: 'Ratings & Reviews',
  },
  '/support/lost-found': {
    section: 'Support',
    sectionTo: '/support/tickets',
    item: 'Lost & Found',
  },
  '/support/faqs': {
    section: 'Support',
    sectionTo: '/support/tickets',
    item: 'FAQs / Help Center',
  },
  '/settings/service-zones': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Service Areas / Zones',
  },
  '/settings/cities': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Cities / Regions',
  },
  '/settings/taxes': { section: 'Settings', sectionTo: '/settings/service-zones', item: 'Taxes' },
  '/settings/languages': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Languages',
  },
  '/settings/content': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Content Pages',
  },
  '/settings/app-settings': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'App Settings',
  },
  '/settings/audit-logs': {
    section: 'Settings',
    sectionTo: '/settings/service-zones',
    item: 'Audit Logs',
  },
  '/account/profile': { section: 'Account', sectionTo: '/account/profile', item: 'Profile' },
}

const currentBreadcrumb = computed(() => {
  const match = routeMap[route.path]
  if (match) return match

  if (route.path.startsWith('/payments/topups/')) {
    const id = (route.params.id as string) || 'Details'
    return {
      section: 'Payment & Wallet',
      sectionTo: '/payments/topups',
      item: `Top-Up Request #${id}`,
    }
  }

  if (route.path.startsWith('/payments/payout-requests/')) {
    const id = (route.params.id as string) || 'Details'
    return {
      section: 'Payment & Wallet',
      sectionTo: '/payments/payout-requests',
      item: `Payout Withdrawal #${id}`,
    }
  }

  if (route.path.startsWith('/users/driver-applications/')) {
    const id = (route.params.id as string) || 'Details'
    return {
      section: 'Users & Fleet',
      sectionTo: '/users/driver-applications',
      item: `Application #${id}`,
    }
  }

  const parts = route.path.split('/').filter(Boolean)
  const sec = parts[0] ? parts[0].charAt(0).toUpperCase() + parts[0].slice(1) : 'Dashboard'
  const itm = parts[1]
    ? parts[1].replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
    : 'Overview'
  return {
    section: sec,
    sectionTo: `/${parts[0] || 'dashboard/overview'}`,
    item: itm,
  }
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

    <!-- Left Navigation Sidebar -->
    <Sidebar :mobile-open="mobileNavOpen" @close-mobile="mobileNavOpen = false" />

    <!-- Right Workspace Pane -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      <!-- Top Navigation Header: Exactly h-16 (64px) border-b border-neutral-200 matching sidebar header -->
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

          <!-- Interactive Clickable Breadcrumbs -->
          <nav aria-label="Breadcrumb" class="flex items-center space-x-2 text-xs min-w-0 truncate">
            <!-- Home Link -->
            <RouterLink
              to="/dashboard/overview"
              class="text-neutral-400 hover:text-neutral-900 transition-colors flex items-center shrink-0"
              title="Dashboard Overview"
              aria-label="Dashboard Overview"
            >
              <Icon icon="lucide:home" class="text-sm" aria-hidden="true" />
            </RouterLink>

            <Icon
              icon="lucide:chevron-right"
              class="text-[11px] text-neutral-300 shrink-0"
              aria-hidden="true"
            />

            <!-- Parent Section Link -->
            <RouterLink
              :to="currentBreadcrumb.sectionTo"
              class="font-semibold text-neutral-500 hover:text-neutral-900 transition-colors truncate"
            >
              {{ currentBreadcrumb.section }}
            </RouterLink>

            <Icon
              v-if="currentBreadcrumb.item !== currentBreadcrumb.section"
              icon="lucide:chevron-right"
              class="text-[11px] text-neutral-300 shrink-0"
              aria-hidden="true"
            />

            <!-- Current Active Page -->
            <span
              v-if="currentBreadcrumb.item !== currentBreadcrumb.section"
              class="font-bold text-neutral-900 truncate"
              aria-current="page"
            >
              {{ currentBreadcrumb.item }}
            </span>
          </nav>
        </div>

        <div class="hidden sm:flex items-center gap-2 shrink-0">
          <span
            class="px-2.5 py-1 bg-neutral-100 border border-neutral-200 text-[11px] font-mono font-semibold text-neutral-700"
          >
            Pagadian · 7016
          </span>
          <RouterLink
            to="/payments/topups"
            class="px-2.5 py-1 bg-amber-50 hover:bg-amber-100 border border-amber-200 text-[11px] font-semibold text-amber-800 transition-colors"
          >
            Top-Ups
          </RouterLink>
          <RouterLink
            to="/trips/sos-alerts"
            class="px-2.5 py-1 bg-rose-50 hover:bg-rose-100 border border-rose-200 text-[11px] font-semibold text-rose-700 transition-colors"
          >
            SOS
          </RouterLink>
        </div>
      </header>

      <!-- Main Scrollable Content Area -->
      <main class="flex-1 overflow-y-auto p-4 sm:p-6 bg-neutral-50">
        <slot />
      </main>
    </div>
  </div>
</template>
