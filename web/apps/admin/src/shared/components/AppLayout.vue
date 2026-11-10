<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import Sidebar from '@/shared/components/Sidebar.vue'

const route = useRoute()
const router = useRouter()

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
  '/users/admin-users-roles': {
    section: 'Users & Fleet',
    sectionTo: '/users/drivers',
    item: 'Admin Users & Roles',
  },
  '/users/roles': {
    section: 'Users & Fleet',
    sectionTo: '/users/drivers',
    item: 'Admin Users & Roles',
  },
  '/vehicle/vehicles': {
    section: 'Vehicles',
    sectionTo: '/vehicle/vehicles',
    item: 'Vehicles Roster',
  },
  '/vehicle/vehicle-types': {
    section: 'Vehicles',
    sectionTo: '/vehicle/vehicles',
    item: 'Vehicle Types',
  },
  '/documents/document-verification': {
    section: 'Documents',
    sectionTo: '/documents/document-verification',
    item: 'Document Verification',
  },
  '/documents/expiring-documents': {
    section: 'Documents',
    sectionTo: '/documents/document-verification',
    item: 'Expiring Documents',
  },
  '/documents/rejected-documents': {
    section: 'Documents',
    sectionTo: '/documents/document-verification',
    item: 'Rejected Documents',
  },
  '/trips/all-trips': { section: 'Trips', sectionTo: '/trips/all-trips', item: 'All Trips' },
  '/trips/scheduled-bookings': {
    section: 'Trips',
    sectionTo: '/trips/all-trips',
    item: 'Scheduled Bookings',
  },
  '/trips/dispatch': {
    section: 'Trips',
    sectionTo: '/trips/all-trips',
    item: 'Live Dispatch Radar',
  },
  '/trips/cancellations-disputes': {
    section: 'Trips',
    sectionTo: '/trips/all-trips',
    item: 'Cancellations & Disputes',
  },
  '/trips/sos-alerts': {
    section: 'Trips',
    sectionTo: '/trips/all-trips',
    item: 'SOS Emergency Alerts',
  },
  '/payment/driver-topups': {
    section: 'Payment & Wallet',
    sectionTo: '/payment/driver-topups',
    item: 'Driver Top-Ups (Verify)',
  },
  '/payment/transactions': {
    section: 'Payment & Wallet',
    sectionTo: '/payment/driver-topups',
    item: 'Transactions',
  },
  '/payment/driver-earnings': {
    section: 'Payment & Wallet',
    sectionTo: '/payment/driver-topups',
    item: 'Driver Earnings',
  },
  '/payment/payout-requests': {
    section: 'Payment & Wallet',
    sectionTo: '/payment/driver-topups',
    item: 'Payout Requests',
  },
  '/payment/wallet': {
    section: 'Payment & Wallet',
    sectionTo: '/payment/driver-topups',
    item: 'Driver Wallet',
  },
  '/payment/refunds': {
    section: 'Payment & Wallet',
    sectionTo: '/payment/driver-topups',
    item: 'Refunds',
  },
  '/payment/fare-pricing': {
    section: 'Payment & Wallet',
    sectionTo: '/payment/driver-topups',
    item: 'Fare & Pricing',
  },
  '/payment/commission-settings': {
    section: 'Payment & Wallet',
    sectionTo: '/payment/driver-topups',
    item: 'Commission Settings',
  },
  '/payment/payment-methods': {
    section: 'Payment & Wallet',
    sectionTo: '/payment/driver-topups',
    item: 'Company Bank & QR',
  },
  '/reports/trip-reports': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Trip Reports',
  },
  '/reports/revenue-reports': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Revenue Reports',
  },
  '/reports/driver-performance': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Driver Performance',
  },
  '/reports/rider-activity': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Rider Activity',
  },
  '/reports/cancellation-report': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Cancellation Report',
  },
  '/reports/peak-hours-demand': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Peak Hours & Demand',
  },
  '/reports/payout-report': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Payout Report',
  },
  '/reports/document-expiry-report': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Document Expiry Report',
  },
  '/reports/tax-invoice-reports': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Tax / Invoice Reports',
  },
  '/reports/export-center': {
    section: 'Reports',
    sectionTo: '/reports/trip-reports',
    item: 'Export Center',
  },
  '/support/tickets-complaints': {
    section: 'Support',
    sectionTo: '/support/tickets-complaints',
    item: 'Tickets / Complaints',
  },
  '/support/ratings-reviews': {
    section: 'Support',
    sectionTo: '/support/tickets-complaints',
    item: 'Ratings & Reviews',
  },
  '/support/lost-found': {
    section: 'Support',
    sectionTo: '/support/tickets-complaints',
    item: 'Lost & Found',
  },
  '/support/faqs-help-center': {
    section: 'Support',
    sectionTo: '/support/tickets-complaints',
    item: 'FAQs / Help Center',
  },
  '/settings/service-areas-zones': {
    section: 'Settings',
    sectionTo: '/settings/service-areas-zones',
    item: 'Service Areas / Zones',
  },
  '/settings/cities-regions': {
    section: 'Settings',
    sectionTo: '/settings/service-areas-zones',
    item: 'Cities / Regions',
  },
  '/settings/taxes': {
    section: 'Settings',
    sectionTo: '/settings/service-areas-zones',
    item: 'Taxes',
  },
  '/settings/languages': {
    section: 'Settings',
    sectionTo: '/settings/service-areas-zones',
    item: 'Languages',
  },
  '/settings/content-pages': {
    section: 'Settings',
    sectionTo: '/settings/service-areas-zones',
    item: 'Content Pages',
  },
  '/settings/app-settings': {
    section: 'Settings',
    sectionTo: '/settings/service-areas-zones',
    item: 'App Settings',
  },
  '/settings/audit-logs': {
    section: 'Settings',
    sectionTo: '/settings/service-areas-zones',
    item: 'Audit Logs',
  },
  '/profile': { section: 'Account', sectionTo: '/profile', item: 'Profile' },
}

const currentBreadcrumb = computed(() => {
  const match = routeMap[route.path]
  if (match) return match

  // Fallback heuristic for unlisted paths
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

function goBack() {
  if (window.history.length > 1) {
    router.back()
  } else {
    void router.push('/dashboard/overview')
  }
}
</script>

<template>
  <div class="h-screen bg-neutral-50 flex overflow-hidden font-sans text-neutral-900">
    <!-- Left Navigation Sidebar -->
    <Sidebar />

    <!-- Right Workspace Pane -->
    <div class="flex-1 flex flex-col min-w-0 h-full overflow-hidden">
      <!-- Top Navigation Header: Exactly h-16 (64px) border-b border-neutral-200 matching sidebar header -->
      <header
        class="h-16 border-b border-neutral-200 bg-white px-6 flex items-center justify-between shrink-0 select-none"
      >
        <!-- Interactive Clickable Breadcrumbs with Back Button -->
        <nav aria-label="Breadcrumb" class="flex items-center space-x-2 text-xs">
          <!-- Back Button -->
          <button
            type="button"
            class="p-1.5 rounded-lg text-neutral-400 hover:text-neutral-900 hover:bg-neutral-100 transition-colors mr-1 flex items-center justify-center"
            title="Navigate back"
            aria-label="Navigate back"
            @click="goBack"
          >
            <Icon icon="lucide:arrow-left" class="text-sm" />
          </button>

          <!-- Home Link -->
          <RouterLink
            to="/dashboard/overview"
            class="text-neutral-400 hover:text-neutral-900 transition-colors flex items-center"
            title="Dashboard Overview"
          >
            <Icon icon="lucide:home" class="text-sm" />
          </RouterLink>

          <Icon icon="lucide:chevron-right" class="text-[11px] text-neutral-300 shrink-0" />

          <!-- Parent Section Link -->
          <RouterLink
            :to="currentBreadcrumb.sectionTo"
            class="font-semibold text-neutral-500 hover:text-neutral-900 transition-colors"
          >
            {{ currentBreadcrumb.section }}
          </RouterLink>

          <Icon
            v-if="currentBreadcrumb.item !== currentBreadcrumb.section"
            icon="lucide:chevron-right"
            class="text-[11px] text-neutral-300 shrink-0"
          />

          <!-- Current Active Page -->
          <span
            v-if="currentBreadcrumb.item !== currentBreadcrumb.section"
            class="font-bold text-neutral-900"
            aria-current="page"
          >
            {{ currentBreadcrumb.item }}
          </span>
        </nav>

        <div class="flex items-center space-x-4">
          <!-- Pending Driver Top-Ups Badge (Direct link to verification queue) -->
          <RouterLink
            to="/payment/driver-topups"
            class="hidden sm:flex items-center space-x-2 px-3 py-1.5 rounded-lg bg-amber-50 border border-amber-200 text-xs font-semibold text-amber-900 hover:bg-amber-100 transition-colors shadow-2xs"
          >
            <Icon icon="lucide:wallet" class="text-amber-600 text-sm" />
            <span>3 Driver Top-Ups Pending</span>
            <span class="w-2 h-2 rounded-full bg-amber-500 animate-ping" />
          </RouterLink>

          <!-- System Status Indicator -->
          <div
            class="flex items-center space-x-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-xs font-semibold text-emerald-800"
          >
            <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>Dispatch System Online</span>
          </div>
        </div>
      </header>

      <!-- Main Scrollable Content Area -->
      <main class="flex-1 overflow-y-auto p-6 bg-neutral-50">
        <slot />
      </main>
    </div>
  </div>
</template>
