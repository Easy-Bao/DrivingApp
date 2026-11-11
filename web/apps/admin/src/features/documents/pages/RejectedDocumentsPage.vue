<script setup lang="ts">
import { ref } from 'vue'

const rejectedDocs = ref([
  {
    id: 'REJ-401',
    driver: 'Javier Santos',
    driverPhone: '+1 (555) 987-6543',
    docType: "Driver's License Photo",
    rejectionReason: 'Image blurred; expiration date unreadable',
    rejectedBy: 'Admin User',
    rejectedAt: 'Yesterday 14:20',
    resubmitted: false,
  },
  {
    id: 'REJ-402',
    driver: 'Fatima Al-Mansoor',
    driverPhone: '+1 (555) 444-5566',
    docType: 'Insurance Policy Certificate',
    rejectionReason: 'Policyholder name does not match applicant identity',
    rejectedBy: 'Super Admin',
    rejectedAt: '3 days ago',
    resubmitted: true,
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">Rejected Driver Documents</h1>
      <p class="text-sm text-neutral-500 mt-1">
        Audit log of failed document submissions, regulatory rejection grounds, and driver
        resubmissions.
      </p>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Rejected Regulatory Documents</h2>
        <span class="text-xs text-neutral-400">Maintained for legal compliance audits</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Log ID</th>
            <th class="py-3 px-4">Driver</th>
            <th class="py-3 px-4">Document</th>
            <th class="py-3 px-4">Rejection Grounds</th>
            <th class="py-3 px-4">Auditor</th>
            <th class="py-3 px-4">Date</th>
            <th class="py-3 px-4 text-right">Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="item in rejectedDocs"
            :key="item.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ item.id }}</td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ item.driver }}</div>
              <div class="text-[11px] text-neutral-400">{{ item.driverPhone }}</div>
            </td>
            <td class="py-3 px-4 font-medium text-neutral-800">{{ item.docType }}</td>
            <td class="py-3 px-4 text-rose-700 font-medium">
              <div class="flex items-center space-x-1.5">
                <span>{{ item.rejectionReason }}</span>
              </div>
            </td>
            <td class="py-3 px-4 text-neutral-600">{{ item.rejectedBy }}</td>
            <td class="py-3 px-4 text-neutral-500">{{ item.rejectedAt }}</td>
            <td class="py-3 px-4 text-right">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  item.resubmitted ? 'bg-blue-100 text-blue-800' : 'bg-neutral-100 text-neutral-600'
                "
              >
                {{ item.resubmitted ? 'Resubmitted' : 'Awaiting Driver' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
