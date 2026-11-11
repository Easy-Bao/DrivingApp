<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const tickets = ref([
  {
    id: 'TCK-201',
    user: 'Jessica Patel',
    role: 'Rider',
    subject: 'Fare calculated incorrectly after unexpected bridge detour',
    category: 'Billing & Charges',
    priority: 'High',
    status: 'Open',
    createdAt: '1 hour ago',
  },
  {
    id: 'TCK-200',
    user: 'David Kim',
    role: 'Driver',
    subject: 'Toll fee not reimbursed automatically on Trip #1090',
    category: 'Driver Earnings',
    priority: 'Medium',
    status: 'In Review',
    createdAt: '3 hours ago',
  },
  {
    id: 'TCK-199',
    user: 'Carlos Mendez',
    role: 'Rider',
    subject: 'Driver arrived in vehicle with mismatched color',
    category: 'Safety & Trust',
    priority: 'High',
    status: 'Investigating',
    createdAt: 'Yesterday',
  },
])

const actionToast = ref<string | null>(null)

function resolveTicket(t: (typeof tickets.value)[0]) {
  t.status = 'Resolved'
  actionToast.value = `Ticket ${t.id} marked as resolved. Response notification sent.`
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
          Customer & Driver Support Tickets
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Triage passenger complaints, driver payout inquiries, and platform service escalation
          tickets.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span
          class="px-3 py-1.5 bg-amber-50 border border-amber-200 text-xs font-semibold text-amber-800"
        >
          3 Open Support Inquiries
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
        <h2 class="font-bold text-sm text-neutral-900">Active Support Ticket Inbox</h2>
        <span class="text-xs text-neutral-400">Target first response time: &lt; 15 mins</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Ticket ID</th>
            <th class="py-3 px-4">Complainant</th>
            <th class="py-3 px-4">Subject</th>
            <th class="py-3 px-4">Category</th>
            <th class="py-3 px-4">Priority</th>
            <th class="py-3 px-4">Status</th>
            <th class="py-3 px-4 text-right">Action</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr v-for="t in tickets" :key="t.id" class="hover:bg-neutral-50/70 transition-colors">
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ t.id }}</td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ t.user }}</div>
              <div class="text-[11px] text-neutral-400">{{ t.role }}</div>
            </td>
            <td class="py-3 px-4 text-neutral-800 font-medium max-w-xs">{{ t.subject }}</td>
            <td class="py-3 px-4 text-neutral-600">{{ t.category }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  t.priority === 'High'
                    ? 'bg-rose-100 text-rose-800'
                    : 'bg-neutral-100 text-neutral-700'
                "
              >
                {{ t.priority }}
              </span>
            </td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  t.status === 'Resolved'
                    ? 'bg-emerald-100 text-emerald-800'
                    : t.status === 'In Review'
                      ? 'bg-amber-100 text-amber-800'
                      : 'bg-blue-100 text-blue-800'
                "
              >
                {{ t.status }}
              </span>
            </td>
            <td class="py-3 px-4 text-right">
              <button
                v-if="t.status !== 'Resolved'"
                type="button"
                class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors"
                @click="resolveTicket(t)"
              >
                Resolve
              </button>
              <span v-else class="text-neutral-400 text-xs">Closed</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
