import type { RouteRecordRaw } from 'vue-router'
import VehiclesPage from '@/features/vehicles/pages/VehiclesPage.vue'
import VehicleTypesPage from '@/features/vehicles/pages/VehicleTypesPage.vue'

export const vehiclesRoutes: RouteRecordRaw[] = [
  { path: '/vehicles', name: 'vehicles-list', component: VehiclesPage },
  { path: '/vehicles/types', name: 'vehicles-types', component: VehicleTypesPage },
  { path: '/vehicle', redirect: '/vehicles' },
  { path: '/vehicle/vehicles', redirect: '/vehicles' },
  { path: '/vehicle/vehicle-types', redirect: '/vehicles/types' },
]
