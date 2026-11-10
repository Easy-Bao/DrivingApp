import type { RouteRecordRaw } from 'vue-router'
import TripReportsPage from '@/features/reports/pages/TripReportsPage.vue'
import RevenueReportsPage from '@/features/reports/pages/RevenueReportsPage.vue'
import DriverPerformancePage from '@/features/reports/pages/DriverPerformancePage.vue'
import RiderActivityPage from '@/features/reports/pages/RiderActivityPage.vue'
import CancellationReportPage from '@/features/reports/pages/CancellationReportPage.vue'
import PeakHoursDemandPage from '@/features/reports/pages/PeakHoursDemandPage.vue'
import PayoutReportPage from '@/features/reports/pages/PayoutReportPage.vue'
import DocumentExpiryReportPage from '@/features/reports/pages/DocumentExpiryReportPage.vue'
import TaxInvoiceReportsPage from '@/features/reports/pages/TaxInvoiceReportsPage.vue'
import ExportCenterPage from '@/features/reports/pages/ExportCenterPage.vue'

export const reportsRoutes: RouteRecordRaw[] = [
  { path: '/reports', redirect: '/reports/trips' },
  { path: '/reports/trips', name: 'reports-trips', component: TripReportsPage },
  { path: '/reports/revenue', name: 'reports-revenue', component: RevenueReportsPage },
  {
    path: '/reports/driver-performance',
    name: 'reports-driver-performance',
    component: DriverPerformancePage,
  },
  { path: '/reports/rider-activity', name: 'reports-rider-activity', component: RiderActivityPage },
  {
    path: '/reports/cancellations',
    name: 'reports-cancellations',
    component: CancellationReportPage,
  },
  { path: '/reports/peak-hours', name: 'reports-peak-hours', component: PeakHoursDemandPage },
  { path: '/reports/payouts', name: 'reports-payouts', component: PayoutReportPage },
  {
    path: '/reports/document-expiry',
    name: 'reports-document-expiry',
    component: DocumentExpiryReportPage,
  },
  { path: '/reports/tax-invoices', name: 'reports-tax-invoices', component: TaxInvoiceReportsPage },
  { path: '/reports/export-center', name: 'reports-export-center', component: ExportCenterPage },
]
