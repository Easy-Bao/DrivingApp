import type { RouteRecordRaw } from 'vue-router'
import OverviewPage from '@/features/dashboard/pages/OverviewPage.vue'

export const dashboardRoutes: RouteRecordRaw[] = [
  { path: '/dashboard', redirect: '/dashboard/overview' },
  { path: '/dashboard/overview', name: 'dashboard-overview', component: OverviewPage },
]
