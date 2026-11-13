import type { RouteRecordRaw } from 'vue-router'

export const accountRoutes: RouteRecordRaw[] = [
  { path: '/account', redirect: '/account/profile' },
  {
    path: '/account/profile',
    name: 'account-profile',
    component: () => import('@/features/account/pages/ProfilePage.vue'),
  },
  { path: '/profile', redirect: '/account/profile' },
]
