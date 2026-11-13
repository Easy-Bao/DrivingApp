import { createRouter, createWebHistory } from 'vue-router'
import { dashboardRoutes } from '@/app/router/routes/dashboard.routes'
import { usersRoutes } from '@/app/router/routes/users.routes'
import { documentsRoutes } from '@/app/router/routes/documents.routes'
import { tripsRoutes } from '@/app/router/routes/trips.routes'
import { paymentsRoutes } from '@/app/router/routes/payments.routes'
import { reportsRoutes } from '@/app/router/routes/reports.routes'
import { supportRoutes } from '@/app/router/routes/support.routes'
import { settingsRoutes } from '@/app/router/routes/settings.routes'
import { accountRoutes } from '@/app/router/routes/account.routes'
import { installRouterSecurityGuards } from '@/app/router/guards'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/dashboard/overview' },
    {
      path: '/auth/login',
      name: 'auth-login',
      component: () => import('@/app/pages/AuthLoginPage.vue'),
      meta: { public: true, hideChrome: true },
    },
    {
      path: '/unauthorized',
      name: 'unauthorized',
      component: () => import('@/app/pages/UnauthorizedPage.vue'),
      meta: { hideChrome: false },
    },
    ...dashboardRoutes,
    ...usersRoutes,
    ...documentsRoutes,
    ...tripsRoutes,
    ...paymentsRoutes,
    ...reportsRoutes,
    ...supportRoutes,
    ...settingsRoutes,
    ...accountRoutes,
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('@/app/pages/NotFoundPage.vue'),
    },
  ],
  scrollBehavior() {
    return { top: 0 }
  },
})

installRouterSecurityGuards(router)

export default router
