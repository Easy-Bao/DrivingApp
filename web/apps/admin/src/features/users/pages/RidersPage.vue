<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const mockRiders = ref([
  {
    id: 'RDR-201',
    name: 'Sophia Chen',
    email: 'sophia.c@example.com',
    totalTrips: 84,
    spent: '₱1,892.00',
    rating: 4.98,
    status: 'Good Standing',
  },
  {
    id: 'RDR-202',
    name: 'Liam O’Connor',
    email: 'liam.oc@example.com',
    totalTrips: 32,
    spent: '₱640.50',
    rating: 4.85,
    status: 'Good Standing',
  },
  {
    id: 'RDR-203',
    name: 'Amina Idris',
    email: 'amina.i@example.com',
    totalTrips: 119,
    spent: '₱2,740.00',
    rating: 5.0,
    status: 'VIP Rider',
  },
  {
    id: 'RDR-204',
    name: 'Lucas Vance',
    email: 'lucas.v@example.com',
    totalTrips: 12,
    spent: '₱210.00',
    rating: 4.2,
    status: 'Flagged (Dispute)',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">Riders Management</h1>
      <p class="text-sm text-neutral-500 mt-1">
        Review passenger activity, customer lifetime value, ratings, and account standings.
      </p>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <table class="w-full text-left text-xs">
        <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
          <tr>
            <th class="py-3 px-4">Rider ID</th>
            <th class="py-3 px-4">Customer Name</th>
            <th class="py-3 px-4">Email</th>
            <th class="py-3 px-4">Total Trips</th>
            <th class="py-3 px-4">Lifetime Spend</th>
            <th class="py-3 px-4">Rating</th>
            <th class="py-3 px-4">Status</th>
            <th class="py-3 px-4 text-right">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100 text-neutral-700">
          <tr v-for="r in mockRiders" :key="r.id" class="hover:bg-neutral-50/50">
            <td class="py-3 px-4 font-mono font-bold">{{ r.id }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ r.name }}</td>
            <td class="py-3 px-4">{{ r.email }}</td>
            <td class="py-3 px-4">{{ r.totalTrips }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ r.spent }}</td>
            <td class="py-3 px-4 font-bold text-neutral-900">★ {{ r.rating }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                :class="
                  r.status.includes('Good') || r.status.includes('VIP')
                    ? 'bg-emerald-100 text-emerald-800'
                    : 'bg-rose-100 text-rose-800'
                "
              >
                {{ r.status }}
              </span>
            </td>
            <td class="py-3 px-4 text-right">
              <button
                type="button"
                class="text-xs text-neutral-600 hover:text-neutral-900 font-medium"
              >
                Inspect
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
