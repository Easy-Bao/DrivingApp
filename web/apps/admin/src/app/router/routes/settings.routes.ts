import type { RouteRecordRaw } from 'vue-router'

export const settingsRoutes: RouteRecordRaw[] = [
  { path: '/settings', redirect: '/settings/service-zones' },
  {
    path: '/settings/service-zones',
    name: 'settings-service-zones',
    component: () => import('@/features/settings/pages/ServiceZonesPage.vue'),
  },
  {
    path: '/settings/cities',
    name: 'settings-cities',
    component: () => import('@/features/settings/pages/CitiesPage.vue'),
  },
  {
    path: '/settings/content',
    name: 'settings-content',
    component: () => import('@/features/settings/pages/ContentPage.vue'),
  },
  {
    path: '/settings/app-settings',
    name: 'settings-app',
    component: () => import('@/features/settings/pages/AppSettingsPage.vue'),
  },
  {
    path: '/settings/audit-logs',
    name: 'settings-audit-logs',
    component: () => import('@/features/settings/pages/AuditLogsPage.vue'),
  },
]
