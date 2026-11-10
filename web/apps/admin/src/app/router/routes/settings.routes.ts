import type { RouteRecordRaw } from 'vue-router'
import ServiceZonesPage from '@/features/settings/pages/ServiceZonesPage.vue'
import CitiesPage from '@/features/settings/pages/CitiesPage.vue'
import TaxesPage from '@/features/settings/pages/TaxesPage.vue'
import LanguagesPage from '@/features/settings/pages/LanguagesPage.vue'
import ContentPage from '@/features/settings/pages/ContentPage.vue'
import AppSettingsPage from '@/features/settings/pages/AppSettingsPage.vue'
import AuditLogsPage from '@/features/settings/pages/AuditLogsPage.vue'

export const settingsRoutes: RouteRecordRaw[] = [
  { path: '/settings', redirect: '/settings/service-zones' },
  {
    path: '/settings/service-zones',
    name: 'settings-service-zones',
    component: ServiceZonesPage,
  },
  { path: '/settings/cities', name: 'settings-cities', component: CitiesPage },
  { path: '/settings/taxes', name: 'settings-taxes', component: TaxesPage },
  { path: '/settings/languages', name: 'settings-languages', component: LanguagesPage },
  { path: '/settings/content', name: 'settings-content', component: ContentPage },
  { path: '/settings/app-settings', name: 'settings-app', component: AppSettingsPage },
  { path: '/settings/audit-logs', name: 'settings-audit-logs', component: AuditLogsPage },
]
