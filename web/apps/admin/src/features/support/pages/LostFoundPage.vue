<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const lostItems = ref([
  {
    id: 'LF-101',
    itemDescription: 'Black leather briefcase containing laptop & documents',
    reportedBy: 'Carlos Mendez (Rider)',
    contactPhone: '+1 (555) 918-2831',
    tripId: 'TRP-1090',
    driver: 'David Kim',
    driverPhone: '+1 (555) 345-6789',
    status: 'Driver Confirmed Found',
    reportedAt: 'Yesterday',
  },
  {
    id: 'LF-102',
    itemDescription: 'iPhone 15 Pro with navy blue silicone case',
    reportedBy: 'Jessica Patel (Rider)',
    contactPhone: '+1 (555) 482-1920',
    tripId: 'TRP-1082',
    driver: 'Elena Rostova',
    driverPhone: '+1 (555) 876-5432',
    status: 'Returned to Owner',
    reportedAt: '2 days ago',
  },
  {
    id: 'LF-103',
    itemDescription: 'Prescription reading glasses in brown leather case',
    reportedBy: 'Samuel Vance (Rider)',
    contactPhone: '+1 (555) 881-2244',
    tripId: 'TRP-1070',
    driver: 'Marcus Miller',
    driverPhone: '+1 (555) 234-5678',
    status: 'Searching Vehicle',
    reportedAt: '3 days ago',
  },
])

const actionToast = ref<string | null>(null)

function markReturned(item: (typeof lostItems.value)[0]) {
  item.status = 'Returned to Owner'
  actionToast.value = `Item ${item.id} logged as returned to passenger. Case closed.`
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Lost & Found Property Registry
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Facilitate lost item claims between passengers and drivers, coordinate returns, and log
          resolutions.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span class="px-3 py-1.5 bg-neutral-100 text-neutral-800 text-xs font-semibold">
          3 Items Tracked
        </span>
      </div>
    </div>

    <div
      v-if="actionToast"
      class="p-4 bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Reported In-Cabin Property</h2>
        <span class="text-xs text-neutral-400"
          >Driver compensation fee (₱15) applied for drop-off return</span
        >
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Claim ID</th>
            <th class="py-3 px-4">Item Description</th>
            <th class="py-3 px-4">Rider</th>
            <th class="py-3 px-4">Matched Driver</th>
            <th class="py-3 px-4">Trip ID</th>
            <th class="py-3 px-4">Status</th>
            <th class="py-3 px-4 text-right">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="item in lostItems"
            :key="item.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ item.id }}</td>
            <td class="py-3 px-4 font-medium text-neutral-900 max-w-xs">
              {{ item.itemDescription }}
            </td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ item.reportedBy }}</div>
              <div class="text-[11px] text-neutral-400">{{ item.contactPhone }}</div>
            </td>
            <td class="py-3 px-4">
              <div class="font-medium text-neutral-900">{{ item.driver }}</div>
              <div class="text-[11px] text-neutral-400">{{ item.driverPhone }}</div>
            </td>
            <td class="py-3 px-4 font-mono text-neutral-700 font-medium">{{ item.tripId }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  item.status === 'Returned to Owner'
                    ? 'bg-emerald-100 text-emerald-800'
                    : item.status === 'Driver Confirmed Found'
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-amber-100 text-amber-800'
                "
              >
                {{ item.status }}
              </span>
            </td>
            <td class="py-3 px-4 text-right">
              <button
                v-if="item.status !== 'Returned to Owner'"
                type="button"
                class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors"
                @click="markReturned(item)"
              >
                Confirm Return
              </button>
              <span v-else class="text-neutral-400 text-xs">Closed</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
