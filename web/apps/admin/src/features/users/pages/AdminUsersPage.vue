<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const adminUsers = ref([
  {
    id: 'ADM-001',
    name: 'Admin User',
    email: 'admin@easyride.io',
    role: 'Super Administrator',
    department: 'Executive Operations',
    mfaEnabled: true,
    lastActive: 'Active now',
    status: 'Active',
  },
  {
    id: 'ADM-002',
    name: 'Sarah Chen',
    email: 'sarah.chen@easyride.io',
    role: 'Dispatch & Safety Supervisor',
    department: 'Fleet Dispatch',
    mfaEnabled: true,
    lastActive: '12 mins ago',
    status: 'Active',
  },
  {
    id: 'ADM-003',
    name: 'Michael Torres',
    email: 'michael.torres@easyride.io',
    role: 'Finance & Compliance Officer',
    department: 'Treasury & Settlements',
    mfaEnabled: true,
    lastActive: '1 hour ago',
    status: 'Active',
  },
  {
    id: 'ADM-004',
    name: 'Jessica Wu',
    email: 'jessica.wu@easyride.io',
    role: 'Customer Support Lead',
    department: 'Trust & Safety',
    mfaEnabled: false,
    lastActive: 'Yesterday',
    status: 'Active',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">Admin Users & Operators</h1>
        <p class="text-sm text-neutral-500 mt-1">
          Manage corporate administrator accounts, staff department assignments, and security
          authentication credentials.
        </p>
      </div>
      <div class="flex items-center space-x-3">
        <RouterLink
          to="/users/roles"
          class="px-3.5 py-2 bg-neutral-100 hover:bg-neutral-200 text-neutral-900 rounded-lg text-xs font-semibold transition-colors"
        >
          View Roles & RBAC Matrix →
        </RouterLink>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Active Staff Administrators (4)</h2>
        <span class="text-xs text-neutral-400"
          >All sessions protected by multi-factor authentication</span
        >
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Operator</th>
            <th class="py-3 px-4">Department</th>
            <th class="py-3 px-4">Assigned Role</th>
            <th class="py-3 px-4">MFA Security</th>
            <th class="py-3 px-4">Last Activity</th>
            <th class="py-3 px-4 text-right">Account Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="user in adminUsers"
            :key="user.id"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4">
              <div class="font-bold text-neutral-900">{{ user.name }}</div>
              <div class="text-[11px] text-neutral-500 font-mono">{{ user.email }}</div>
            </td>
            <td class="py-3 px-4 text-neutral-700 font-medium">{{ user.department }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-neutral-100 text-neutral-800"
              >
                {{ user.role }}
              </span>
            </td>
            <td class="py-3 px-4">
              <span
                class="inline-flex items-center space-x-1 px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  user.mfaEnabled
                    ? 'bg-emerald-100 text-emerald-800'
                    : 'bg-amber-100 text-amber-800'
                "
              >
                <Icon
                  :icon="user.mfaEnabled ? 'lucide:shield-check' : 'lucide:shield-alert'"
                  class="text-xs"
                />
                <span>{{ user.mfaEnabled ? 'Hardware MFA' : 'MFA Pending' }}</span>
              </span>
            </td>
            <td class="py-3 px-4 text-neutral-500">{{ user.lastActive }}</td>
            <td class="py-3 px-4 text-right">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 text-emerald-800"
              >
                {{ user.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
