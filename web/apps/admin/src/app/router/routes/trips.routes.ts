import type { RouteRecordRaw } from 'vue-router'
import AllTripsPage from '@/features/trips/pages/AllTripsPage.vue'
import ScheduledBookingsPage from '@/features/trips/pages/ScheduledBookingsPage.vue'
import DispatchPage from '@/features/trips/pages/DispatchPage.vue'
import CancellationsDisputesPage from '@/features/trips/pages/CancellationsDisputesPage.vue'
import SosAlertsPage from '@/features/trips/pages/SosAlertsPage.vue'

export const tripsRoutes: RouteRecordRaw[] = [
  { path: '/trips', redirect: '/trips/all' },
  { path: '/trips/all', name: 'trips-all', component: AllTripsPage },
  { path: '/trips/scheduled', name: 'trips-scheduled', component: ScheduledBookingsPage },
  { path: '/trips/dispatch', name: 'trips-dispatch', component: DispatchPage },
  {
    path: '/trips/cancellations-disputes',
    name: 'trips-cancellations-disputes',
    component: CancellationsDisputesPage,
  },
  { path: '/trips/sos-alerts', name: 'trips-sos-alerts', component: SosAlertsPage },
]
