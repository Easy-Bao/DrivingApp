import type { RouteRecordRaw } from 'vue-router'

export const reportsRoutes: RouteRecordRaw[] = [
  { path: '/reports', redirect: '/reports/trips' },
  {
    path: '/reports/trips',
    name: 'reports-trips',
    component: () => import('@/features/reports/pages/TripReportsPage.vue'),
  },
  {
    path: '/reports/revenue',
    name: 'reports-revenue',
    component: () => import('@/features/reports/pages/RevenueReportsPage.vue'),
  },
  {
    path: '/reports/driver-performance',
    name: 'reports-driver-performance',
    component: () => import('@/features/reports/pages/DriverPerformancePage.vue'),
  },
  {
    path: '/reports/rider-activity',
    name: 'reports-rider-activity',
    component: () => import('@/features/reports/pages/RiderActivityPage.vue'),
  },
  {
    path: '/reports/cancellations',
    name: 'reports-cancellations',
    component: () => import('@/features/reports/pages/CancellationReportPage.vue'),
  },
  {
    path: '/reports/peak-hours',
    name: 'reports-peak-hours',
    component: () => import('@/features/reports/pages/PeakHoursDemandPage.vue'),
  },
  {
    path: '/reports/document-expiry',
    name: 'reports-document-expiry',
    component: () => import('@/features/reports/pages/DocumentExpiryReportPage.vue'),
  },
  {
    path: '/reports/export-center',
    name: 'reports-export-center',
    component: () => import('@/features/reports/pages/ExportCenterPage.vue'),
  },
]
