import type { RouteRecordRaw } from 'vue-router'

export const paymentsRoutes: RouteRecordRaw[] = [
  { path: '/payments', redirect: '/payments/topups' },
  {
    path: '/payments/topups',
    name: 'payments-topups',
    component: () => import('@/features/payments/pages/TopupsPage.vue'),
  },
  {
    path: '/payments/topups/:id',
    name: 'payments-topup-details',
    component: () => import('@/features/payments/pages/TopupDetailsPage.vue'),
    meta: { isDetail: true },
  },
  {
    path: '/payments/transactions',
    name: 'payments-transactions',
    component: () => import('@/features/payments/pages/TransactionsPage.vue'),
  },
  {
    path: '/payments/earnings',
    name: 'payments-earnings',
    component: () => import('@/features/payments/pages/DriverEarningsPage.vue'),
  },
  {
    path: '/payments/wallet',
    name: 'payments-wallet',
    component: () => import('@/features/payments/pages/WalletPage.vue'),
  },
  {
    path: '/payments/refunds',
    name: 'payments-refunds',
    component: () => import('@/features/payments/pages/RefundsPage.vue'),
  },
  {
    path: '/payments/fare-pricing',
    name: 'payments-fare-pricing',
    component: () => import('@/features/payments/pages/FarePricingPage.vue'),
  },
  {
    path: '/payments/commission-settings',
    name: 'payments-commission-settings',
    component: () => import('@/features/payments/pages/CommissionSettingsPage.vue'),
  },
  {
    path: '/payments/methods',
    name: 'payments-methods',
    component: () => import('@/features/payments/pages/PaymentMethodsPage.vue'),
  },
  { path: '/payment', redirect: '/payments/topups' },
]
