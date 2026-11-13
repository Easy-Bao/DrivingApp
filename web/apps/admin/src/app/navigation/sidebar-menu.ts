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

export const navigationGroups: SidebarNavGroup[] = [
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
        id: 'admin-users',
        label: 'Admin Users',
        icon: 'lucide:user-cog',
        path: '/users/admin-users',
      },
      {
        id: 'roles',
        label: 'Staff Roles & RBAC',
        icon: 'lucide:shield-check',
        path: '/users/roles',
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
        path: '/documents/verification',
        badge: '12',
        badgeClass: 'bg-blue-100 text-blue-800',
      },
      {
        id: 'expiring-documents',
        label: 'Expiring Documents',
        icon: 'lucide:file-clock',
        path: '/documents/expiring',
        badge: '4',
        badgeClass: 'bg-amber-100 text-amber-800',
      },
      {
        id: 'rejected-documents',
        label: 'Rejected Documents',
        icon: 'lucide:file-x',
        path: '/documents/rejected',
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
        path: '/trips/all',
      },
      {
        id: 'bidding-sessions',
        label: 'Live Bidding Monitor',
        icon: 'lucide:gavel',
        path: '/trips/bidding',
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
    id: 'payments',
    title: 'Payments & Wallet',
    icon: 'lucide:credit-card',
    items: [
      {
        id: 'topups',
        label: 'Driver Top-Ups',
        icon: 'lucide:wallet',
        path: '/payments/topups',
        badge: '3',
        badgeClass: 'bg-amber-100 text-amber-800 font-bold',
      },
      {
        id: 'settlements',
        label: 'Cash Settlements',
        icon: 'lucide:coins',
        path: '/payments/settlements',
        badge: '3',
        badgeClass: 'bg-rose-100 text-rose-800 font-bold',
      },
      {
        id: 'transactions',
        label: 'Transactions',
        icon: 'lucide:receipt',
        path: '/payments/transactions',
      },
      {
        id: 'driver-earnings',
        label: 'Driver Earnings',
        icon: 'lucide:banknote',
        path: '/payments/earnings',
      },
      {
        id: 'wallet',
        label: 'Driver Wallet',
        icon: 'lucide:wallet-cards',
        path: '/payments/wallet',
      },
      { id: 'refunds', label: 'Refunds', icon: 'lucide:rotate-ccw', path: '/payments/refunds' },
      {
        id: 'fare-pricing',
        label: 'Fare & Pricing',
        icon: 'lucide:calculator',
        path: '/payments/fare-pricing',
      },
      {
        id: 'commission-settings',
        label: 'Commission Settings',
        icon: 'lucide:percent',
        path: '/payments/commission-settings',
      },
      {
        id: 'payment-methods',
        label: 'Company Bank & QR',
        icon: 'lucide:qr-code',
        path: '/payments/methods',
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
        path: '/reports/trips',
      },
      {
        id: 'revenue-reports',
        label: 'Revenue Reports',
        icon: 'lucide:trending-up',
        path: '/reports/revenue',
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
        path: '/reports/cancellations',
      },
      {
        id: 'peak-hours-demand',
        label: 'Peak Hours & Demand',
        icon: 'lucide:flame',
        path: '/reports/peak-hours',
      },
      {
        id: 'document-expiry-report',
        label: 'Document Expiry Report',
        icon: 'lucide:calendar-x',
        path: '/reports/document-expiry',
      },
      {
        id: 'export-center',
        label: 'Export Center',
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
        label: 'Support Tickets',
        icon: 'lucide:message-square-warning',
        path: '/support/tickets',
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
        label: 'Help Center',
        icon: 'lucide:help-circle',
        path: '/support/faqs',
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
        label: 'Service Zones',
        icon: 'lucide:map',
        path: '/settings/service-zones',
      },
      {
        id: 'cities-regions',
        label: 'Operating Cities',
        icon: 'lucide:building-2',
        path: '/settings/cities',
      },
      {
        id: 'content-pages',
        label: 'Legal & Content',
        icon: 'lucide:file-text',
        path: '/settings/content',
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
