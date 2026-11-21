import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { routes, handleHotUpdate } from 'vue-router/auto-routes'
import { installRouterSecurityGuards } from '@/app/router/guards'

const SECTION_REDIRECTS: RouteRecordRaw[] = [
  { path: '/', redirect: '/dashboard/overview' },
  { path: '/dashboard', redirect: '/dashboard/overview' },
  { path: '/users', redirect: '/users/drivers' },
  { path: '/users/operators', redirect: '/admin/operators' },
  { path: '/users/roles', redirect: '/admin/roles' },
  { path: '/documents', redirect: '/documents/verification' },
  { path: '/trips', redirect: '/trips/all' },
  { path: '/payments', redirect: '/payments/topups' },
  { path: '/payment', redirect: '/payments/topups' },
  { path: '/payments/fare-pricing', redirect: '/config/fare-pricing' },
  { path: '/payments/commission-settings', redirect: '/config/commissions' },
  { path: '/payments/methods', redirect: '/config/payment-channels' },
  { path: '/reports', redirect: '/reports/trips' },
  { path: '/support', redirect: '/support/tickets' },
  { path: '/support/faqs', redirect: '/config/help-center' },
  { path: '/config', redirect: '/config/fare-pricing' },
  { path: '/settings', redirect: '/config/app-system' },
  { path: '/settings/service-zones', redirect: '/config/service-zones' },
  { path: '/settings/cities', redirect: '/config/cities' },
  { path: '/settings/content', redirect: '/config/legal-policies' },
  { path: '/settings/app-settings', redirect: '/config/app-system' },
  { path: '/settings/audit-logs', redirect: '/admin/audit-logs' },
  { path: '/admin', redirect: '/admin/operators' },
  { path: '/account', redirect: '/account/profile' },
  { path: '/profile', redirect: '/account/profile' },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [...SECTION_REDIRECTS, ...routes],
  scrollBehavior() {
    return { top: 0 }
  },
})

if (import.meta.hot?.data) {
  handleHotUpdate(router)
}

installRouterSecurityGuards(router)

export default router
