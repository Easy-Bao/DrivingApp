import type { RouteRecordRaw } from 'vue-router'

export const dashboardRoutes: RouteRecordRaw[] = [
  { path: '/dashboard', redirect: '/dashboard/overview' },
  {
    path: '/dashboard/overview',
    name: 'dashboard-overview',
    component: () => import('@/features/dashboard/pages/OverviewPage.vue'),
  },
]
