<script setup lang="ts">
import { ref } from 'vue'

const auditEvents = ref([
  {
    id: 'LOG-991',
    actor: 'Admin User (super_admin)',
    ipAddress: '192.168.1.104',
    action: 'Verified Driver Top-Up (₱50.00)',
    target: 'Driver Marcus Miller (TOP-8921)',
    timestamp: '14 mins ago',
    severity: 'Normal',
  },
  {
    id: 'LOG-990',
    actor: 'Operations Lead (fleet_ops)',
    ipAddress: '10.0.4.12',
    action: 'Approved Driver Document (CDL)',
    target: 'Brandon Lee (DOC-901)',
    timestamp: '1 hour ago',
    severity: 'Normal',
  },
  {
    id: 'LOG-989',
    actor: 'Finance Director (finance_admin)',
    ipAddress: '192.168.1.210',
    action: 'Updated Commission Rate (Green Fleet → 10%)',
    target: 'Pricing Matrix',
    timestamp: '3 hours ago',
    severity: 'Audit Warning',
  },
  {
    id: 'LOG-988',
    actor: 'Admin User (super_admin)',
    ipAddress: '192.168.1.104',
    action: 'Waived Cancellation Fee (₱5.00)',
    target: 'Trip TRP-1089 (Sarah Jenkins)',
    timestamp: 'Yesterday',
    severity: 'Normal',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Security Audit Logs & Compliance Trail
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Immutable event log of administrator actions, wallet adjustments, permission changes, and
          security events.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span class="px-3 py-1.5 bg-neutral-100 text-neutral-800 text-xs font-semibold">
          Retention: 365 Days
        </span>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Platform Administrative Audit Log</h2>
        <span class="text-xs text-neutral-400">Cryptographically hashed and tamper-evident</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Event ID</th>
            <th class="py-3 px-4">Administrator / Role</th>
            <th class="py-3 px-4">Action Taken</th>
            <th class="py-3 px-4">Target Entity</th>
            <th class="py-3 px-4">IP Address</th>
            <th class="py-3 px-4">Timestamp</th>
            <th class="py-3 px-4 text-right">Severity</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="log in auditEvents"
            :key="log.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ log.id }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ log.actor }}</td>
            <td class="py-3 px-4 font-medium text-neutral-800">{{ log.action }}</td>
            <td class="py-3 px-4 text-neutral-600">{{ log.target }}</td>
            <td class="py-3 px-4 font-mono text-[11px] text-neutral-400">{{ log.ipAddress }}</td>
            <td class="py-3 px-4 text-neutral-500">{{ log.timestamp }}</td>
            <td class="py-3 px-4 text-right">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  log.severity === 'Normal'
                    ? 'bg-neutral-100 text-neutral-700'
                    : 'bg-amber-100 text-amber-800'
                "
              >
                {{ log.severity }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
