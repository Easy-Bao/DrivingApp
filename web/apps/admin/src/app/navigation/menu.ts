export type NavSectionId = 'operations' | 'configuration' | 'administration'

export interface NavItem {
  id: string
  label: string
  icon: string
  path: string
  badge?: string | number
  badgeClass?: string
  keywords?: readonly string[]
}

export interface NavGroup {
  id: string
  section: NavSectionId
  title: string
  icon: string
  items: NavItem[]
  defaultExpanded?: boolean
}

export interface NavSection {
  id: NavSectionId
  label: string
}

export const pinnedNavItems: readonly NavItem[] = [
  {
    id: 'overview',
    label: 'Overview',
    icon: 'lucide:layout-dashboard',
    path: '/dashboard/overview',
    keywords: ['dashboard', 'home', 'kpi', 'metrics', 'summary', 'executive'],
  },
]

export const navigationSections: readonly NavSection[] = [
  { id: 'operations', label: 'Operations' },
  { id: 'configuration', label: 'Configuration' },
  { id: 'administration', label: 'Administration' },
]

export const navigationGroups: NavGroup[] = [
  {
    id: 'users',
    section: 'operations',
    title: 'Users & Fleet',
    icon: 'lucide:users',
    defaultExpanded: true,
    items: [
      {
        id: 'drivers',
        label: 'Drivers',
        icon: 'lucide:id-card',
        path: '/users/drivers',
        keywords: ['fleet', 'toda', 'bao-bao', 'suspend'],
      },
      {
        id: 'driver-applications',
        label: 'Driver Applications',
        icon: 'lucide:user-plus',
        path: '/users/driver-applications',
        keywords: ['onboarding', 'kyc', 'applicants', 'review'],
      },
      {
        id: 'riders',
        label: 'Riders',
        icon: 'lucide:user',
        path: '/users/riders',
        keywords: ['passengers', 'customers', 'commuters'],
      },
    ],
  },
  {
    id: 'documents',
    section: 'operations',
    title: 'Compliance',
    icon: 'lucide:file-check',
    defaultExpanded: false,
    items: [
      {
        id: 'document-verification',
        label: 'Verification',
        icon: 'lucide:file-badge',
        path: '/documents/verification',
        keywords: ['kyc', 'lto', 'license', 'orcr', 'mtop', 'pending'],
      },
      {
        id: 'expiring-documents',
        label: 'Expiring',
        icon: 'lucide:file-clock',
        path: '/documents/expiring',
        keywords: ['renewal', 'expiry', 'documents'],
      },
      {
        id: 'rejected-documents',
        label: 'Rejected',
        icon: 'lucide:file-x',
        path: '/documents/rejected',
        keywords: ['declined', 'documents', 'compliance'],
      },
    ],
  },
  {
    id: 'trips',
    section: 'operations',
    title: 'Trips & Safety',
    icon: 'lucide:route',
    defaultExpanded: false,
    items: [
      {
        id: 'all-trips',
        label: 'All Trips',
        icon: 'lucide:navigation',
        path: '/trips/all',
        keywords: ['rides', 'bookings', 'history'],
      },
      {
        id: 'bidding-sessions',
        label: 'Live Bidding',
        icon: 'lucide:gavel',
        path: '/trips/bidding',
        keywords: ['offers', 'bids', 'marketplace'],
      },
      {
        id: 'dispatch',
        label: 'Dispatch',
        icon: 'lucide:radio',
        path: '/trips/dispatch',
        keywords: ['live', 'assign', 'surge', 'supply'],
      },
      {
        id: 'cancellations-disputes',
        label: 'Disputes',
        icon: 'lucide:alert-triangle',
        path: '/trips/cancellations-disputes',
        keywords: ['cancellations', 'fault', 'fee waiver'],
      },
      {
        id: 'sos-alerts',
        label: 'SOS Alerts',
        icon: 'lucide:siren',
        path: '/trips/sos-alerts',
        badgeClass: 'bg-neutral-900 text-white',
        keywords: ['emergency', '911', 'cdrrmo', 'panic'],
      },
      {
        id: 'safety-reports',
        label: 'Safety Reports',
        icon: 'lucide:shield-alert',
        path: '/trips/safety-reports',
        keywords: ['incidents', 'moderation', 'conduct'],
      },
    ],
  },
  {
    id: 'payments',
    section: 'operations',
    title: 'Finance',
    icon: 'lucide:credit-card',
    defaultExpanded: false,
    items: [
      {
        id: 'topups',
        label: 'Top-Ups',
        icon: 'lucide:wallet',
        path: '/payments/topups',
        keywords: ['deposits', 'qrph', 'receipts', 'prepaid'],
      },
      {
        id: 'settlements',
        label: 'Settlements',
        icon: 'lucide:coins',
        path: '/payments/settlements',
        keywords: ['cash', 'shortfall', 'reconcile'],
      },
      {
        id: 'transactions',
        label: 'Transactions',
        icon: 'lucide:receipt',
        path: '/payments/transactions',
        keywords: ['ledger', 'credits', 'debits'],
      },
      {
        id: 'driver-earnings',
        label: 'Earnings',
        icon: 'lucide:banknote',
        path: '/payments/earnings',
        keywords: ['take-home', 'gross', 'payout'],
      },
      {
        id: 'wallet',
        label: 'Wallets',
        icon: 'lucide:wallet-cards',
        path: '/payments/wallet',
        keywords: ['balances', 'prepaid', 'credit', 'adjust'],
      },
      {
        id: 'refunds',
        label: 'Refunds',
        icon: 'lucide:rotate-ccw',
        path: '/payments/refunds',
        keywords: ['rebates', 'adjustments', 'waivers', 'claims'],
      },
    ],
  },
  {
    id: 'support',
    section: 'operations',
    title: 'Support',
    icon: 'lucide:headset',
    defaultExpanded: false,
    items: [
      {
        id: 'tickets-complaints',
        label: 'Tickets',
        icon: 'lucide:message-square-warning',
        path: '/support/tickets',
        keywords: ['inquiries', 'complaints', 'desk'],
      },
      {
        id: 'ratings-reviews',
        label: 'Reviews',
        icon: 'lucide:star',
        path: '/support/ratings-reviews',
        keywords: ['ratings', 'feedback', 'moderation'],
      },
      {
        id: 'lost-found',
        label: 'Lost Items',
        icon: 'lucide:package-search',
        path: '/support/lost-found',
        keywords: ['property', 'recovery', 'found'],
      },
    ],
  },
  {
    id: 'reports',
    section: 'operations',
    title: 'Reports',
    icon: 'lucide:bar-chart-3',
    defaultExpanded: false,
    items: [
      {
        id: 'trip-reports',
        label: 'Trips',
        icon: 'lucide:chart-pie',
        path: '/reports/trips',
        keywords: ['analytics', 'volume'],
      },
      {
        id: 'revenue-reports',
        label: 'Revenue',
        icon: 'lucide:trending-up',
        path: '/reports/revenue',
        keywords: ['income', 'commission', 'gmv'],
      },
      {
        id: 'driver-performance',
        label: 'Performance',
        icon: 'lucide:award',
        path: '/reports/driver-performance',
        keywords: ['drivers', 'acceptance', 'leaderboard'],
      },
      {
        id: 'rider-activity',
        label: 'Activity',
        icon: 'lucide:activity',
        path: '/reports/rider-activity',
        keywords: ['cohorts', 'retention', 'passengers'],
      },
      {
        id: 'cancellation-report',
        label: 'Cancellations',
        icon: 'lucide:chart-bar',
        path: '/reports/cancellations',
        keywords: ['abort', 'faults'],
      },
      {
        id: 'peak-hours-demand',
        label: 'Peak Demand',
        icon: 'lucide:flame',
        path: '/reports/peak-hours',
        keywords: ['rush hour', 'heatmap', 'demand'],
      },
      {
        id: 'document-expiry-report',
        label: 'Expiry Forecast',
        icon: 'lucide:calendar-x',
        path: '/reports/document-expiry',
        keywords: ['renewals', 'forecast', 'compliance'],
      },
      {
        id: 'export-center',
        label: 'Exports',
        icon: 'lucide:download',
        path: '/reports/export-center',
        keywords: ['csv', 'scheduled', 'downloads'],
      },
    ],
  },

  {
    id: 'pricing-config',
    section: 'configuration',
    title: 'Pricing & Billing',
    icon: 'lucide:calculator',
    defaultExpanded: true,
    items: [
      {
        id: 'fare-pricing',
        label: 'Fare Configuration',
        icon: 'lucide:receipt-text',
        path: '/config/fare-pricing',
        keywords: [
          'tariff',
          'rates',
          'base fare',
          'per km',
          'surge',
          'rating bonus',
          'cancellation',
          'discounts',
          'senior',
          'pwd',
          'student',
          'night differential',
        ],
      },
      {
        id: 'commission-settings',
        label: 'Commissions',
        icon: 'lucide:percent',
        path: '/config/commissions',
        keywords: ['bps', 'basis points', 'platform fee', 'booking fee', 'tiers'],
      },
      {
        id: 'wallet-rules',
        label: 'Wallet & Top-Up Rules',
        icon: 'lucide:wallet-minimal',
        path: '/config/wallet-rules',
        keywords: [
          'minimum balance',
          'dispatch threshold',
          'auto-lock',
          'top-up limit',
          'prepaid',
          'sla',
        ],
      },
      {
        id: 'payment-methods',
        label: 'Payment Channels',
        icon: 'lucide:qr-code',
        path: '/config/payment-channels',
        keywords: ['qrph', 'gcash', 'maya', 'bdo', 'bpi', 'bank', 'depository', 'collection'],
      },
    ],
  },
  {
    id: 'dispatch-config',
    section: 'configuration',
    title: 'Dispatch & Coverage',
    icon: 'lucide:map-pinned',
    defaultExpanded: false,
    items: [
      {
        id: 'dispatch-policy',
        label: 'Dispatch & Ride Policy',
        icon: 'lucide:radar',
        path: '/config/dispatch-policy',
        keywords: [
          'bidding window',
          'gps',
          'telemetry',
          'no-show',
          'arrival radius',
          'completion radius',
          'geofence',
          'search radius',
          'bid bounds',
        ],
      },
      {
        id: 'service-areas-zones',
        label: 'Service Zones',
        icon: 'lucide:map',
        path: '/config/service-zones',
        keywords: ['geofence', 'polygons', 'barangays', 'corridors', 'surge'],
      },
      {
        id: 'cities-regions',
        label: 'Cities & Markets',
        icon: 'lucide:building-2',
        path: '/config/cities',
        keywords: ['municipalities', 'regions', 'zip', 'launch', 'min fare'],
      },
    ],
  },
  {
    id: 'fleet-config',
    section: 'configuration',
    title: 'Fleet & Safety',
    icon: 'lucide:shield-check',
    defaultExpanded: false,
    items: [
      {
        id: 'vehicle-classes',
        label: 'Vehicle Classes',
        icon: 'lucide:car-front',
        path: '/config/vehicle-classes',
        keywords: ['bao-bao', 'service types', 'electric', 'eco', 'capacity', 'express'],
      },
      {
        id: 'document-rules',
        label: 'Document Rules',
        icon: 'lucide:clipboard-check',
        path: '/config/document-rules',
        keywords: ['lto', 'toda', 'mtop', 'orcr', 'compliance gate', 'expiry', 'grace period'],
      },
      {
        id: 'safety-sos',
        label: 'Safety & SOS Config',
        icon: 'lucide:phone-call',
        path: '/config/safety-sos',
        keywords: ['911', 'cdrrmo', 'pnp', 'hotlines', 'emergency', 'escalation'],
      },
    ],
  },
  {
    id: 'content-system',
    section: 'configuration',
    title: 'Content & System',
    icon: 'lucide:sliders-horizontal',
    defaultExpanded: false,
    items: [
      {
        id: 'content-pages',
        label: 'Legal Policies',
        icon: 'lucide:file-text',
        path: '/config/legal-policies',
        keywords: ['terms', 'privacy', 'charter', 'dpa', 'tos'],
      },
      {
        id: 'faqs-help-center',
        label: 'Help Center',
        icon: 'lucide:help-circle',
        path: '/config/help-center',
        keywords: ['faqs', 'articles', 'knowledge base', 'support content'],
      },
      {
        id: 'app-system',
        label: 'App & System',
        icon: 'lucide:settings-2',
        path: '/config/app-system',
        keywords: [
          'preferences',
          'maintenance',
          'version',
          'force update',
          'timezone',
          'hub',
          'settings',
        ],
      },
    ],
  },

  {
    id: 'governance',
    section: 'administration',
    title: 'Access & Audit',
    icon: 'lucide:lock-keyhole',
    defaultExpanded: false,
    items: [
      {
        id: 'operators',
        label: 'Operators',
        icon: 'lucide:user-cog',
        path: '/admin/operators',
        keywords: ['staff', 'admins', 'mfa', '2fa', 'invite'],
      },
      {
        id: 'roles',
        label: 'Roles & Permissions',
        icon: 'lucide:key-round',
        path: '/admin/roles',
        keywords: ['rbac', 'scopes', 'access control'],
      },
      {
        id: 'audit-logs',
        label: 'Audit Logs',
        icon: 'lucide:history',
        path: '/admin/audit-logs',
        keywords: ['trail', 'events', 'security', 'changes'],
      },
    ],
  },
]

export const allNavigationItems: readonly NavItem[] = [
  ...pinnedNavItems,
  ...navigationGroups.flatMap((group) => group.items),
]
