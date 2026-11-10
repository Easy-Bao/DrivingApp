<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const reviews = ref([
  {
    id: 'REV-881',
    tripId: 'TRP-1092',
    rating: 5,
    author: 'Alexander Wright (Rider)',
    target: 'Marcus Miller (Driver)',
    comment:
      'Immaculately clean car, smooth highway driving, arrived 3 minutes ahead of time. Exemplary chauffeur!',
    date: '14 mins ago',
  },
  {
    id: 'REV-880',
    tripId: 'TRP-1090',
    rating: 5,
    author: 'Carlos Mendez (Rider)',
    target: 'David Kim (Driver)',
    comment: 'Great family-friendly SUV. Helped us with our luggage bags without asking.',
    date: '1 hour ago',
  },
  {
    id: 'REV-879',
    tripId: 'TRP-1082',
    rating: 2,
    author: 'Jessica Patel (Rider)',
    target: 'Javier Santos (Driver)',
    comment: 'Driver took a long detour and did not use air conditioning on a hot day.',
    date: 'Yesterday',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Ratings & Feedback Audits
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Review passenger feedback, driver star ratings, and investigate flagged negative service
          reviews.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span
          class="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg bg-amber-50 border border-amber-200 text-xs font-bold text-amber-900"
        >
          <Icon icon="lucide:star" class="text-amber-500" />
          <span>Platform Fleet Average: 4.88 ★</span>
        </span>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Passenger Star Reviews & Comments</h2>
        <span class="text-xs text-neutral-400"
          >All submissions verified against completed trips</span
        >
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Review ID</th>
            <th class="py-3 px-4">Rating</th>
            <th class="py-3 px-4">Rider</th>
            <th class="py-3 px-4">Rated Driver</th>
            <th class="py-3 px-4">Commentary</th>
            <th class="py-3 px-4 text-right">Trip & Date</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr v-for="r in reviews" :key="r.id" class="hover:bg-neutral-50/70 transition-colors">
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ r.id }}</td>
            <td class="py-3 px-4">
              <span
                class="font-bold font-mono px-2 py-0.5 rounded-md text-[11px]"
                :class="
                  r.rating >= 4 ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'
                "
              >
                ★ {{ r.rating }}.0
              </span>
            </td>
            <td class="py-3 px-4 font-medium text-neutral-900">{{ r.author }}</td>
            <td class="py-3 px-4 text-neutral-800 font-medium">{{ r.target }}</td>
            <td class="py-3 px-4 text-neutral-600 max-w-sm">{{ r.comment }}</td>
            <td class="py-3 px-4 text-right">
              <div class="font-mono text-neutral-700 font-medium">{{ r.tripId }}</div>
              <div class="text-[11px] text-neutral-400">{{ r.date }}</div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
