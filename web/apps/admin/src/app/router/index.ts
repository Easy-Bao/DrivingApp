import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { routes, handleHotUpdate } from 'vue-router/auto-routes'
import { installRouterSecurityGuards } from '@/app/router/guards'

const SECTION_REDIRECTS: RouteRecordRaw[] = [
  { path: '/', redirect: '/dashboard/overview' },
  { path: '/dashboard', redirect: '/dashboard/overview' },
  { path: '/users', redirect: '/users/drivers' },
  { path: '/documents', redirect: '/documents/verification' },
  { path: '/trips', redirect: '/trips/all' },
  { path: '/payments', redirect: '/payments/topups' },
  { path: '/payment', redirect: '/payments/topups' },
  { path: '/reports', redirect: '/reports/trips' },
  { path: '/support', redirect: '/support/tickets' },
  { path: '/settings', redirect: '/settings/service-zones' },
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
