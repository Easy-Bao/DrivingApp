import type { RouteRecordRaw } from 'vue-router'

export const tripsRoutes: RouteRecordRaw[] = [
  { path: '/trips', redirect: '/trips/all' },
  {
    path: '/trips/all',
    name: 'trips-all',
    component: () => import('@/features/trips/pages/AllTripsPage.vue'),
  },
  {
    path: '/trips/bidding',
    name: 'trips-bidding',
    component: () => import('@/features/trips/pages/BiddingSessionsPage.vue'),
  },
  {
    path: '/trips/dispatch',
    name: 'trips-dispatch',
    component: () => import('@/features/trips/pages/DispatchPage.vue'),
  },
  {
    path: '/trips/cancellations-disputes',
    name: 'trips-cancellations-disputes',
    component: () => import('@/features/trips/pages/CancellationsDisputesPage.vue'),
  },
  {
    path: '/trips/sos-alerts',
    name: 'trips-sos-alerts',
    component: () => import('@/features/trips/pages/SosAlertsPage.vue'),
  },
  {
    path: '/trips/safety-reports',
    name: 'trips-safety-reports',
    component: () => import('@/features/trips/pages/SafetyReportsPage.vue'),
  },
]
