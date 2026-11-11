<script setup lang="ts">
import { ref } from 'vue'

const roles = ref([
  {
    id: 'ROLE-1',
    name: 'Super Administrator',
    usersCount: 2,
    permissions: 'Full Access across platform, finances, and system settings',
  },
  {
    id: 'ROLE-2',
    name: 'Dispatch & Safety Supervisor',
    usersCount: 6,
    permissions: 'Live dispatch override, SOS intervention, driver trip reassignment',
  },
  {
    id: 'ROLE-3',
    name: 'Finance & Compliance Officer',
    usersCount: 3,
    permissions: 'Driver top-up verification, payout approval, tax reporting, audit ledger',
  },
  {
    id: 'ROLE-4',
    name: 'Customer Support Agent',
    usersCount: 14,
    permissions: 'Dispute arbitration, ticket resolution, refund drafting',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Staff Roles & Permissions (RBAC)
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Manage role-based access control, security scopes, and staff member authorizations.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800"
      >
        + Create Custom Role
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="r in roles"
        :key="r.id"
        class="p-5 bg-white border border-neutral-200 space-y-3"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <h3 class="font-bold text-sm text-neutral-900">{{ r.name }}</h3>
          </div>
          <span
            class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-neutral-100 text-neutral-700"
            >{{ r.usersCount }} Users Assigned</span
          >
        </div>
        <p class="text-xs text-neutral-600 leading-relaxed">{{ r.permissions }}</p>
        <div class="pt-2 border-t border-neutral-100 flex justify-between items-center text-xs">
          <button type="button" class="text-neutral-600 hover:text-neutral-900 font-medium">
            Edit Permissions
          </button>
          <button type="button" class="text-neutral-400 hover:text-neutral-700">
            Audit History
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
