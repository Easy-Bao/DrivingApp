<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const expiringDocs = ref([
  {
    id: 'EXP-101',
    driver: 'Javier Santos',
    driverPhone: '+1 (555) 987-6543',
    docType: 'Vehicle Roadworthiness Certificate',
    expiryDate: '2026-11-15',
    daysLeft: 5,
    status: 'Action Required',
  },
  {
    id: 'EXP-102',
    driver: 'Tyler Brooks',
    driverPhone: '+1 (555) 777-8899',
    docType: 'Commercial Liability Insurance',
    expiryDate: '2026-11-20',
    daysLeft: 10,
    status: 'Notice Sent',
  },
  {
    id: 'EXP-103',
    driver: 'Anthony Stark',
    driverPhone: '+1 (555) 345-6789',
    docType: "Driver's License Medical Clearance",
    expiryDate: '2026-11-28',
    daysLeft: 18,
    status: 'Notice Sent',
  },
  {
    id: 'EXP-104',
    driver: 'Elena Rostova',
    driverPhone: '+1 (555) 876-5432',
    docType: 'Airport Zone Permit',
    expiryDate: '2026-12-05',
    daysLeft: 25,
    status: 'Grace Period',
  },
])

const actionToast = ref<string | null>(null)

function sendUrgentReminder(doc: (typeof expiringDocs.value)[0]) {
  actionToast.value = `Urgent push notification & SMS alert sent to ${doc.driver} (${doc.driverPhone}).`
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Expiring Driver Documents
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Monitor certificates expiring within the next 30 days and issue compliance warnings before
          dispatch lockout.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span
          class="px-3 py-1.5 rounded-lg bg-amber-50 border border-amber-200 text-xs font-semibold text-amber-800"
        >
          4 Documents Expiring Soon
        </span>
      </div>
    </div>

    <div
      v-if="actionToast"
      class="p-4 rounded-xl bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:bell-ring" class="text-amber-400 text-base" />
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">30-Day Expiry Watchlist</h2>
        <span class="text-xs text-neutral-400">Automatic suspension triggers upon expiration</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Watch ID</th>
            <th class="py-3 px-4">Driver</th>
            <th class="py-3 px-4">Document</th>
            <th class="py-3 px-4">Expiry Date</th>
            <th class="py-3 px-4">Time Remaining</th>
            <th class="py-3 px-4">Status</th>
            <th class="py-3 px-4 text-right">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="doc in expiringDocs"
            :key="doc.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ doc.id }}</td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ doc.driver }}</div>
              <div class="text-[11px] text-neutral-400">{{ doc.driverPhone }}</div>
            </td>
            <td class="py-3 px-4 font-medium text-neutral-800">{{ doc.docType }}</td>
            <td class="py-3 px-4 font-mono font-medium">{{ doc.expiryDate }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                :class="
                  doc.daysLeft <= 7 ? 'bg-rose-100 text-rose-800' : 'bg-amber-100 text-amber-800'
                "
              >
                {{ doc.daysLeft }} days left
              </span>
            </td>
            <td class="py-3 px-4 text-neutral-600">{{ doc.status }}</td>
            <td class="py-3 px-4 text-right">
              <button
                type="button"
                class="px-2.5 py-1 bg-amber-50 hover:bg-amber-100 text-amber-900 border border-amber-200 rounded-md text-xs font-semibold transition-colors"
                @click="sendUrgentReminder(doc)"
              >
                Send SMS Notice
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
