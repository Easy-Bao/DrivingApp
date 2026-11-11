<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const searchQuery = ref('')
const filterTier = ref('all')

const mockVehicles = ref([
  {
    id: 'V-501',
    makeModel: 'Toyota Camry Hybrid',
    plate: '7XYZ892',
    year: 2023,
    driver: 'Marcus Miller',
    driverPhone: '+1 (555) 234-5678',
    tier: 'Comfort',
    status: 'In Service',
    inspection: 'Valid',
    expiry: '2027-11-01',
  },
  {
    id: 'V-502',
    makeModel: 'Hyundai Ioniq 5',
    plate: 'EV-4491',
    year: 2024,
    driver: 'Elena Rostova',
    driverPhone: '+1 (555) 876-5432',
    tier: 'Comfort',
    status: 'In Service',
    inspection: 'Valid',
    expiry: '2028-03-15',
  },
  {
    id: 'V-503',
    makeModel: 'Chevrolet Suburban',
    plate: 'XL-9081',
    year: 2022,
    driver: 'Anthony Stark',
    driverPhone: '+1 (555) 345-6789',
    tier: 'XL Executive',
    status: 'Maintenance Due',
    inspection: 'Due in 5 days',
    expiry: '2026-11-15',
  },
  {
    id: 'V-504',
    makeModel: 'Nissan Leaf',
    plate: 'GR-1120',
    year: 2021,
    driver: 'Unassigned',
    driverPhone: '—',
    tier: 'Economy',
    status: 'Inactive',
    inspection: 'Expired',
    expiry: '2026-10-30',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">Vehicle Fleet Roster</h1>
        <p class="text-sm text-neutral-500 mt-1">
          Registered fleet vehicles, safety compliance certificates, and driver assignments.
        </p>
      </div>
      <div class="flex items-center space-x-3">
        <RouterLink
          to="/vehicle/vehicle-types"
          class="px-3.5 py-2 bg-neutral-100 hover:bg-neutral-200 text-neutral-900 text-xs font-semibold transition-colors"
        >
          Manage Vehicle Tiers →
        </RouterLink>
      </div>
    </div>

    <!-- Fleet Overview Stats -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Total Registered</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">1,420</div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Active in Service</span>
        <div class="text-xl font-bold tabular-nums text-emerald-600 mt-1">1,280</div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Inspection Due Soon</span>
        <div class="text-xl font-bold tabular-nums text-amber-600 mt-1">14</div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Electric / Hybrid</span>
        <div class="text-xl font-bold tabular-nums text-blue-600 mt-1">42%</div>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="relative w-full sm:w-72">
          <Icon icon="lucide:search" class="absolute left-3 top-2.5 text-neutral-400 text-sm" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search vehicle plate, model, driver..."
            class="w-full pl-9 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 text-xs focus:ring-1 focus:ring-neutral-900 focus:bg-white transition-all"
          />
        </div>
        <div class="flex items-center space-x-2">
          <select
            v-model="filterTier"
            class="px-3 py-1.5 bg-neutral-50 border border-neutral-200 text-xs text-neutral-700"
          >
            <option value="all">All Tiers</option>
            <option value="Economy">Economy</option>
            <option value="Comfort">Comfort</option>
            <option value="XL Executive">XL Executive</option>
          </select>
        </div>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Vehicle ID</th>
            <th class="py-3 px-4">Make & Model</th>
            <th class="py-3 px-4">License Plate</th>
            <th class="py-3 px-4">Assigned Driver</th>
            <th class="py-3 px-4">Tier</th>
            <th class="py-3 px-4">Inspection</th>
            <th class="py-3 px-4 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="v in mockVehicles"
            :key="v.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ v.id }}</td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ v.makeModel }}</div>
              <div class="text-[11px] text-neutral-400">{{ v.year }} model</div>
            </td>
            <td class="py-3 px-4 font-mono font-medium">{{ v.plate }}</td>
            <td class="py-3 px-4">
              <div class="text-neutral-800 font-medium">{{ v.driver }}</div>
              <div class="text-[11px] text-neutral-400">{{ v.driverPhone }}</div>
            </td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-neutral-100 text-neutral-800"
              >
                {{ v.tier }}
              </span>
            </td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  v.inspection === 'Valid'
                    ? 'bg-emerald-100 text-emerald-800'
                    : v.inspection === 'Expired'
                      ? 'bg-rose-100 text-rose-800'
                      : 'bg-amber-100 text-amber-800'
                "
              >
                {{ v.inspection }}
              </span>
            </td>
            <td class="py-3 px-4 text-right">
              <button
                type="button"
                class="text-xs text-neutral-600 hover:text-neutral-900 font-medium"
              >
                Audit Record
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
