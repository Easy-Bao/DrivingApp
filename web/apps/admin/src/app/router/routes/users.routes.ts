import type { RouteRecordRaw } from 'vue-router'
import DriversPage from '@/features/users/pages/DriversPage.vue'
import DriverApplicationsPage from '@/features/users/pages/DriverApplicationsPage.vue'
import DriverApplicationDetailsPage from '@/features/users/pages/DriverApplicationDetailsPage.vue'
import RidersPage from '@/features/users/pages/RidersPage.vue'
import AdminUsersPage from '@/features/users/pages/AdminUsersPage.vue'
import RolesPage from '@/features/users/pages/RolesPage.vue'

export const usersRoutes: RouteRecordRaw[] = [
  { path: '/users', redirect: '/users/drivers' },
  { path: '/users/drivers', name: 'users-drivers', component: DriversPage },
  {
    path: '/users/driver-applications',
    name: 'users-driver-applications',
    component: DriverApplicationsPage,
  },
  {
    path: '/users/driver-applications/:id',
    name: 'users-driver-application-details',
    component: DriverApplicationDetailsPage,
  },
  { path: '/users/riders', name: 'users-riders', component: RidersPage },
  { path: '/users/admin-users', name: 'users-admin-users', component: AdminUsersPage },
  { path: '/users/roles', name: 'users-roles', component: RolesPage },
]
