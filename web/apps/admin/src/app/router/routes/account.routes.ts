import type { RouteRecordRaw } from 'vue-router'
import ProfilePage from '@/features/account/pages/ProfilePage.vue'

export const accountRoutes: RouteRecordRaw[] = [
  { path: '/account', redirect: '/account/profile' },
  { path: '/account/profile', name: 'account-profile', component: ProfilePage },
  { path: '/profile', redirect: '/account/profile' },
]
