export interface NavItem {
  id: string
  label: string
  icon: string
  path: string
  badge?: string | number
  badgeClass?: string
}

export interface NavGroup {
  id: string
  title: string
  icon: string
  items: NavItem[]
}

export const navigationGroups: NavGroup[] = [
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
        label: 'Applications',
        icon: 'lucide:user-plus',
        path: '/users/driver-applications',
        badge: '8',
        badgeClass: 'bg-neutral-100 text-neutral-700',
      },
      { id: 'riders', label: 'Riders', icon: 'lucide:user', path: '/users/riders' },
      {
        id: 'operators',
        label: 'Operators',
        icon: 'lucide:user-cog',
        path: '/users/operators',
      },
      {
        id: 'roles',
        label: 'Staff Roles',
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
        label: 'Verification',
        icon: 'lucide:file-badge',
        path: '/documents/verification',
        badge: '12',
        badgeClass: 'bg-neutral-100 text-neutral-700',
      },
      {
        id: 'expiring-documents',
        label: 'Expiring Docs',
        icon: 'lucide:file-clock',
        path: '/documents/expiring',
        badge: '4',
        badgeClass: 'bg-neutral-100 text-neutral-700',
      },
      {
        id: 'rejected-documents',
        label: 'Rejected Docs',
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
        label: 'Live Bidding',
        icon: 'lucide:gavel',
        path: '/trips/bidding',
      },
      {
        id: 'dispatch',
        label: 'Dispatch',
        icon: 'lucide:radio',
        path: '/trips/dispatch',
        badge: 'Live',
        badgeClass: 'bg-neutral-100 text-neutral-700',
      },
      {
        id: 'cancellations-disputes',
        label: 'Disputes',
        icon: 'lucide:alert-triangle',
        path: '/trips/cancellations-disputes',
      },
      {
        id: 'sos-alerts',
        label: 'SOS Alerts',
        icon: 'lucide:siren',
        path: '/trips/sos-alerts',
        badge: '2',
        badgeClass: 'bg-neutral-900 text-white font-semibold',
      },
      {
        id: 'safety-reports',
        label: 'Safety Reports',
        icon: 'lucide:shield-alert',
        path: '/trips/safety-reports',
        badge: '2',
        badgeClass: 'bg-neutral-100 text-neutral-700',
      },
    ],
  },
  {
    id: 'payments',
    title: 'Payments',
    icon: 'lucide:credit-card',
    items: [
      {
        id: 'topups',
        label: 'Top-Ups',
        icon: 'lucide:wallet',
        path: '/payments/topups',
        badge: '3',
        badgeClass: 'bg-neutral-100 text-neutral-700 font-semibold',
      },
      {
        id: 'settlements',
        label: 'Settlements',
        icon: 'lucide:coins',
        path: '/payments/settlements',
        badge: '3',
        badgeClass: 'bg-neutral-100 text-neutral-700 font-semibold',
      },
      {
        id: 'transactions',
        label: 'Transactions',
        icon: 'lucide:receipt',
        path: '/payments/transactions',
      },
      {
        id: 'driver-earnings',
        label: 'Earnings',
        icon: 'lucide:banknote',
        path: '/payments/earnings',
      },
      {
        id: 'wallet',
        label: 'Wallets',
        icon: 'lucide:wallet-cards',
        path: '/payments/wallet',
      },
      { id: 'refunds', label: 'Refunds', icon: 'lucide:rotate-ccw', path: '/payments/refunds' },
      {
        id: 'fare-pricing',
        label: 'Tariff Rates',
        icon: 'lucide:calculator',
        path: '/payments/fare-pricing',
      },
      {
        id: 'commission-settings',
        label: 'Commissions',
        icon: 'lucide:percent',
        path: '/payments/commission-settings',
      },
      {
        id: 'payment-methods',
        label: 'Channels',
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
        label: 'Trips',
        icon: 'lucide:chart-pie',
        path: '/reports/trips',
      },
      {
        id: 'revenue-reports',
        label: 'Revenue',
        icon: 'lucide:trending-up',
        path: '/reports/revenue',
      },
      {
        id: 'driver-performance',
        label: 'Driver Stats',
        icon: 'lucide:award',
        path: '/reports/driver-performance',
      },
      {
        id: 'rider-activity',
        label: 'Rider Stats',
        icon: 'lucide:activity',
        path: '/reports/rider-activity',
      },
      {
        id: 'cancellation-report',
        label: 'Cancellations',
        icon: 'lucide:chart-bar',
        path: '/reports/cancellations',
      },
      {
        id: 'peak-hours-demand',
        label: 'Peak Demand',
        icon: 'lucide:flame',
        path: '/reports/peak-hours',
      },
      {
        id: 'document-expiry-report',
        label: 'Expiry Forecast',
        icon: 'lucide:calendar-x',
        path: '/reports/document-expiry',
      },
      {
        id: 'export-center',
        label: 'Exports',
        icon: 'lucide:download',
        path: '/reports/export-center',
        badge: 'Auto',
        badgeClass: 'bg-neutral-100 text-neutral-700',
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
        label: 'Tickets',
        icon: 'lucide:message-square-warning',
        path: '/support/tickets',
        badge: '3',
        badgeClass: 'bg-neutral-100 text-neutral-700',
      },
      {
        id: 'ratings-reviews',
        label: 'Reviews',
        icon: 'lucide:star',
        path: '/support/ratings-reviews',
      },
      {
        id: 'lost-found',
        label: 'Lost Items',
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
        label: 'Cities',
        icon: 'lucide:building-2',
        path: '/settings/cities',
      },
      {
        id: 'content-pages',
        label: 'Policies',
        icon: 'lucide:file-text',
        path: '/settings/content',
      },
      {
        id: 'app-settings',
        label: 'Preferences',
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
