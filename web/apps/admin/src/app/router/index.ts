import { createRouter, createWebHistory } from 'vue-router'

// Dashboard
import OverviewPage from '@/pages/OverviewPage.vue'

// Users
import DriversPage from '@/pages/users/DriversPage.vue'
import DriverApplicationsPage from '@/pages/users/DriverApplicationsPage.vue'
import RidersPage from '@/pages/users/RidersPage.vue'
import RolesPage from '@/pages/users/RolesPage.vue'

// Vehicle
import VehiclesPage from '@/pages/vehicles/VehiclesPage.vue'
import VehicleTypesPage from '@/pages/vehicles/VehicleTypesPage.vue'

// Documents
import DocumentVerificationPage from '@/pages/documents/DocumentVerificationPage.vue'
import ExpiringDocumentsPage from '@/pages/documents/ExpiringDocumentsPage.vue'
import RejectedDocumentsPage from '@/pages/documents/RejectedDocumentsPage.vue'

// Trips
import AllTripsPage from '@/pages/trips/AllTripsPage.vue'
import ScheduledBookingsPage from '@/pages/trips/ScheduledBookingsPage.vue'
import DispatchPage from '@/pages/trips/DispatchPage.vue'
import CancellationsDisputesPage from '@/pages/trips/CancellationsDisputesPage.vue'
import SosAlertsPage from '@/pages/trips/SosAlertsPage.vue'

// Payment
import DriverTopupsPage from '@/pages/payment/DriverTopupsPage.vue'
import TransactionsPage from '@/pages/payment/TransactionsPage.vue'
import DriverEarningsPage from '@/pages/payment/DriverEarningsPage.vue'
import PayoutRequestsPage from '@/pages/payment/PayoutRequestsPage.vue'
import DriverWalletPage from '@/pages/payment/DriverWalletPage.vue'
import RefundsPage from '@/pages/payment/RefundsPage.vue'
import FarePricingPage from '@/pages/payment/FarePricingPage.vue'
import CommissionSettingsPage from '@/pages/payment/CommissionSettingsPage.vue'
import CompanyPaymentMethodsPage from '@/pages/payment/CompanyPaymentMethodsPage.vue'

// Reports
import TripReportsPage from '@/pages/reports/TripReportsPage.vue'
import RevenueReportsPage from '@/pages/reports/RevenueReportsPage.vue'
import DriverPerformancePage from '@/pages/reports/DriverPerformancePage.vue'
import RiderActivityPage from '@/pages/reports/RiderActivityPage.vue'
import CancellationReportPage from '@/pages/reports/CancellationReportPage.vue'
import PeakHoursDemandPage from '@/pages/reports/PeakHoursDemandPage.vue'
import PayoutReportPage from '@/pages/reports/PayoutReportPage.vue'
import DocumentExpiryReportPage from '@/pages/reports/DocumentExpiryReportPage.vue'
import TaxInvoiceReportsPage from '@/pages/reports/TaxInvoiceReportsPage.vue'
import ExportCenterPage from '@/pages/reports/ExportCenterPage.vue'

// Support
import TicketsPage from '@/pages/support/TicketsPage.vue'
import RatingsPage from '@/pages/support/RatingsPage.vue'
import LostFoundPage from '@/pages/support/LostFoundPage.vue'
import FaqsPage from '@/pages/support/FaqsPage.vue'

// Settings
import ServiceZonesPage from '@/pages/settings/ServiceZonesPage.vue'
import CitiesPage from '@/pages/settings/CitiesPage.vue'
import TaxesPage from '@/pages/settings/TaxesPage.vue'
import LanguagesPage from '@/pages/settings/LanguagesPage.vue'
import ContentPagesPage from '@/pages/settings/ContentPagesPage.vue'
import AppSettingsPage from '@/pages/settings/AppSettingsPage.vue'
import AuditLogsPage from '@/pages/settings/AuditLogsPage.vue'

// Account
import ProfilePage from '@/pages/ProfilePage.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/dashboard/overview' },
    { path: '/dashboard', redirect: '/dashboard/overview' },
    { path: '/dashboard/overview', name: 'dashboard-overview', component: OverviewPage },

    // Users
    { path: '/users', redirect: '/users/drivers' },
    { path: '/users/drivers', name: 'users-drivers', component: DriversPage },
    {
      path: '/users/driver-applications',
      name: 'users-driver-applications',
      component: DriverApplicationsPage,
    },
    { path: '/users/riders', name: 'users-riders', component: RidersPage },
    { path: '/users/admin-users-roles', name: 'users-roles', component: RolesPage },
    { path: '/users/roles', redirect: '/users/admin-users-roles' },

    // Vehicle
    { path: '/vehicle', redirect: '/vehicle/vehicles' },
    { path: '/vehicle/vehicles', name: 'vehicle-vehicles', component: VehiclesPage },
    { path: '/vehicle/vehicle-types', name: 'vehicle-types', component: VehicleTypesPage },

    // Documents
    { path: '/documents', redirect: '/documents/document-verification' },
    {
      path: '/documents/document-verification',
      name: 'documents-verification',
      component: DocumentVerificationPage,
    },
    {
      path: '/documents/expiring-documents',
      name: 'documents-expiring',
      component: ExpiringDocumentsPage,
    },
    {
      path: '/documents/rejected-documents',
      name: 'documents-rejected',
      component: RejectedDocumentsPage,
    },

    // Trips
    { path: '/trips', redirect: '/trips/all-trips' },
    { path: '/trips/all-trips', name: 'trips-all', component: AllTripsPage },
    {
      path: '/trips/scheduled-bookings',
      name: 'trips-scheduled',
      component: ScheduledBookingsPage,
    },
    { path: '/trips/dispatch', name: 'trips-dispatch', component: DispatchPage },
    {
      path: '/trips/cancellations-disputes',
      name: 'trips-cancellations-disputes',
      component: CancellationsDisputesPage,
    },
    { path: '/trips/sos-alerts', name: 'trips-sos-alerts', component: SosAlertsPage },

    // Payment
    { path: '/payment', redirect: '/payment/driver-topups' },
    { path: '/payment/driver-topups', name: 'payment-driver-topups', component: DriverTopupsPage },
    { path: '/payment/transactions', name: 'payment-transactions', component: TransactionsPage },
    {
      path: '/payment/driver-earnings',
      name: 'payment-driver-earnings',
      component: DriverEarningsPage,
    },
    {
      path: '/payment/payout-requests',
      name: 'payment-payout-requests',
      component: PayoutRequestsPage,
    },
    { path: '/payment/wallet', name: 'payment-wallet', component: DriverWalletPage },
    { path: '/payment/refunds', name: 'payment-refunds', component: RefundsPage },
    { path: '/payment/fare-pricing', name: 'payment-fare-pricing', component: FarePricingPage },
    {
      path: '/payment/commission-settings',
      name: 'payment-commission-settings',
      component: CommissionSettingsPage,
    },
    {
      path: '/payment/payment-methods',
      name: 'payment-methods',
      component: CompanyPaymentMethodsPage,
    },

    // Reports
    { path: '/reports', redirect: '/reports/trip-reports' },
    { path: '/reports/trip-reports', name: 'reports-trips', component: TripReportsPage },
    { path: '/reports/revenue-reports', name: 'reports-revenue', component: RevenueReportsPage },
    {
      path: '/reports/driver-performance',
      name: 'reports-driver-performance',
      component: DriverPerformancePage,
    },
    {
      path: '/reports/rider-activity',
      name: 'reports-rider-activity',
      component: RiderActivityPage,
    },
    {
      path: '/reports/cancellation-report',
      name: 'reports-cancellation',
      component: CancellationReportPage,
    },
    {
      path: '/reports/peak-hours-demand',
      name: 'reports-peak-hours',
      component: PeakHoursDemandPage,
    },
    { path: '/reports/payout-report', name: 'reports-payout', component: PayoutReportPage },
    {
      path: '/reports/document-expiry-report',
      name: 'reports-document-expiry',
      component: DocumentExpiryReportPage,
    },
    {
      path: '/reports/tax-invoice-reports',
      name: 'reports-tax-invoices',
      component: TaxInvoiceReportsPage,
    },
    { path: '/reports/export-center', name: 'reports-export-center', component: ExportCenterPage },

    // Support
    { path: '/support', redirect: '/support/tickets-complaints' },
    { path: '/support/tickets-complaints', name: 'support-tickets', component: TicketsPage },
    { path: '/support/ratings-reviews', name: 'support-ratings', component: RatingsPage },
    { path: '/support/lost-found', name: 'support-lost-found', component: LostFoundPage },
    { path: '/support/faqs-help-center', name: 'support-faqs', component: FaqsPage },

    // Settings
    { path: '/settings', redirect: '/settings/service-areas-zones' },
    {
      path: '/settings/service-areas-zones',
      name: 'settings-service-areas',
      component: ServiceZonesPage,
    },
    { path: '/settings/cities-regions', name: 'settings-cities', component: CitiesPage },
    { path: '/settings/taxes', name: 'settings-taxes', component: TaxesPage },
    { path: '/settings/languages', name: 'settings-languages', component: LanguagesPage },
    {
      path: '/settings/content-pages',
      name: 'settings-content-pages',
      component: ContentPagesPage,
    },
    { path: '/settings/app-settings', name: 'settings-app', component: AppSettingsPage },
    { path: '/settings/audit-logs', name: 'settings-audit-logs', component: AuditLogsPage },

    // Account
    { path: '/profile', name: 'profile', component: ProfilePage },
  ],
})

export default router
