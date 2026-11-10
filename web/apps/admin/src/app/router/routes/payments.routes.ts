import type { RouteRecordRaw } from 'vue-router'
import TopupsPage from '@/features/payments/pages/TopupsPage.vue'
import TopupDetailsPage from '@/features/payments/pages/TopupDetailsPage.vue'
import TransactionsPage from '@/features/payments/pages/TransactionsPage.vue'
import DriverEarningsPage from '@/features/payments/pages/DriverEarningsPage.vue'
import PayoutRequestsPage from '@/features/payments/pages/PayoutRequestsPage.vue'
import PayoutDetailsPage from '@/features/payments/pages/PayoutDetailsPage.vue'
import WalletPage from '@/features/payments/pages/WalletPage.vue'
import RefundsPage from '@/features/payments/pages/RefundsPage.vue'
import FarePricingPage from '@/features/payments/pages/FarePricingPage.vue'
import CommissionSettingsPage from '@/features/payments/pages/CommissionSettingsPage.vue'
import PaymentMethodsPage from '@/features/payments/pages/PaymentMethodsPage.vue'

export const paymentsRoutes: RouteRecordRaw[] = [
  { path: '/payments', redirect: '/payments/topups' },
  { path: '/payments/topups', name: 'payments-topups', component: TopupsPage },
  {
    path: '/payments/topups/:id',
    name: 'payments-topup-details',
    component: TopupDetailsPage,
  },
  { path: '/payments/transactions', name: 'payments-transactions', component: TransactionsPage },
  { path: '/payments/earnings', name: 'payments-earnings', component: DriverEarningsPage },
  {
    path: '/payments/payout-requests',
    name: 'payments-payout-requests',
    component: PayoutRequestsPage,
  },
  {
    path: '/payments/payout-requests/:id',
    name: 'payments-payout-details',
    component: PayoutDetailsPage,
  },
  { path: '/payments/wallet', name: 'payments-wallet', component: WalletPage },
  { path: '/payments/refunds', name: 'payments-refunds', component: RefundsPage },
  { path: '/payments/fare-pricing', name: 'payments-fare-pricing', component: FarePricingPage },
  {
    path: '/payments/commission-settings',
    name: 'payments-commission-settings',
    component: CommissionSettingsPage,
  },
  { path: '/payments/methods', name: 'payments-methods', component: PaymentMethodsPage },
  { path: '/payment', redirect: '/payments/topups' },
]
