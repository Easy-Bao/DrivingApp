import type { RouteRecordRaw } from 'vue-router'

export const usersRoutes: RouteRecordRaw[] = [
  { path: '/users', redirect: '/users/drivers' },
  {
    path: '/users/drivers',
    name: 'users-drivers',
    component: () => import('@/features/users/pages/DriversPage.vue'),
  },
  {
    path: '/users/driver-applications',
    name: 'users-driver-applications',
    component: () => import('@/features/users/pages/DriverApplicationsPage.vue'),
  },
  {
    path: '/users/driver-applications/:id',
    name: 'users-driver-application-details',
    component: () => import('@/features/users/pages/DriverApplicationDetailsPage.vue'),
    meta: { isDetail: true },
  },
  {
    path: '/users/riders',
    name: 'users-riders',
    component: () => import('@/features/users/pages/RidersPage.vue'),
  },
  {
    path: '/users/operators',
    name: 'users-operators',
    component: () => import('@/features/users/pages/OperatorsPage.vue'),
  },
  {
    path: '/users/roles',
    name: 'users-roles',
    component: () => import('@/features/users/pages/RolesPage.vue'),
  },
]
