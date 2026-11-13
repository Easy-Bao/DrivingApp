<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import EmptyTableRow from '@/shared/components/EmptyTableRow.vue'
import ModalDialog from '@/shared/components/ModalDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import SearchField from '@/shared/components/SearchField.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

interface OperatorAccount {
  id: string
  name: string
  email: string
  role: string
  department: string
  mfaEnabled: boolean
  lastActive: string
  status: 'Active' | 'Suspended'
}

const roleOptions = [
  'Root Operator',
  'Dispatch & Safety Supervisor',
  'Treasury & Settlements Officer',
  'Trust & Safety Lead',
]

const operators = ref<OperatorAccount[]>([
  {
    id: 'OPS-001',
    name: 'Operations Control Lead',
    email: 'ops@easyride.ph',
    role: 'Root Operator',
    department: 'Executive Operations',
    mfaEnabled: true,
    lastActive: 'Active now',
    status: 'Active',
  },
  {
    id: 'OPS-002',
    name: 'Marisol Lim',
    email: 'marisol.lim@easyride.ph',
    role: 'Dispatch & Safety Supervisor',
    department: 'Fleet Dispatch',
    mfaEnabled: true,
    lastActive: '12 mins ago',
    status: 'Active',
  },
  {
    id: 'OPS-003',
    name: 'Rafael Bautista',
    email: 'rafael.bautista@easyride.ph',
    role: 'Treasury & Settlements Officer',
    department: 'Treasury & Wallet QA',
    mfaEnabled: true,
    lastActive: '1 hour ago',
    status: 'Active',
  },
  {
    id: 'OPS-004',
    name: 'Kristine Villanueva',
    email: 'kristine.v@easyride.ph',
    role: 'Trust & Safety Lead',
    department: 'Compliance & Support',
    mfaEnabled: false,
    lastActive: 'Yesterday',
    status: 'Active',
  },
])

const searchQuery = ref('')
const toastMessage = ref<string | null>(null)
const toastTone = ref<'success' | 'warning' | 'error'>('success')

const showInviteModal = ref(false)
const inviteForm = ref({
  name: '',
  email: '',
  department: 'Fleet Dispatch',
  role: roleOptions[1]!,
  mfaEnabled: true,
})

const pendingStatusTarget = ref<OperatorAccount | null>(null)
const statusReason = ref('')

const filteredOperators = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) return operators.value
  return operators.value.filter(
    (operator) =>
      operator.name.toLowerCase().includes(query) ||
      operator.email.toLowerCase().includes(query) ||
      operator.role.toLowerCase().includes(query) ||
      operator.department.toLowerCase().includes(query),
  )
})

const activeCount = computed(
  () => operators.value.filter((operator) => operator.status === 'Active').length,
)

const openInviteModal = () => {
  inviteForm.value = {
    name: '',
    email: '',
    department: 'Fleet Dispatch',
    role: roleOptions[1]!,
    mfaEnabled: true,
  }
  showInviteModal.value = true
}

function resetFilters() {
  searchQuery.value = ''
}

const submitInvite = () => {
  if (!inviteForm.value.name.trim() || !inviteForm.value.email.includes('@')) {
    toastTone.value = 'error'
    toastMessage.value = 'Valid name and work email required.'
    return
  }
  const nextNumber = operators.value.length + 1
  operators.value.push({
    id: `OPS-${String(nextNumber).padStart(3, '0')}`,
    name: inviteForm.value.name.trim(),
    email: inviteForm.value.email.trim().toLowerCase(),
    role: inviteForm.value.role,
    department: inviteForm.value.department.trim() || 'Operations Support',
    mfaEnabled: inviteForm.value.mfaEnabled,
    lastActive: 'Invite sent',
    status: 'Active',
  })
  showInviteModal.value = false
  toastTone.value = 'success'
  toastMessage.value = `Invited ${inviteForm.value.name.trim()}.`
}

const updateRole = (operator: OperatorAccount, newRole: string) => {
  operator.role = newRole
  toastTone.value = 'success'
  toastMessage.value = `${operator.name} assigned to ${newRole}.`
}

const toggleMfa = (operator: OperatorAccount) => {
  operator.mfaEnabled = !operator.mfaEnabled
  toastTone.value = operator.mfaEnabled ? 'success' : 'warning'
  toastMessage.value = operator.mfaEnabled
    ? `MFA enabled for ${operator.name}.`
    : `MFA reset for ${operator.name}.`
}

const confirmStatusToggle = () => {
  const target = pendingStatusTarget.value
  if (!target) return
  if (target.status === 'Suspended') {
    target.status = 'Active'
    toastTone.value = 'success'
    toastMessage.value = `${target.name} restored.`
  } else {
    if (!statusReason.value.trim()) return
    target.status = 'Suspended'
    toastTone.value = 'warning'
    toastMessage.value = `${target.name} suspended.`
  }
  pendingStatusTarget.value = null
  statusReason.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader title="Operators" description="Staff accounts, roles, and MFA." />

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col lg:flex-row lg:items-center justify-between gap-3"
      >
        <div class="flex flex-wrap items-center gap-2">
          <div class="w-full sm:w-64">
            <SearchField
              v-model="searchQuery"
              placeholder="Search name, email, role..."
              aria-label="Search operators"
            />
          </div>
          <span
            class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold tabular-nums text-neutral-800"
          >
            Active: {{ activeCount }}
          </span>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <RouterLink
            to="/users/roles"
            class="px-3.5 py-1.5 bg-white border border-neutral-300 hover:bg-neutral-50 text-neutral-900 text-xs font-semibold transition-colors"
          >
            Staff Roles
          </RouterLink>
          <button
            type="button"
            class="px-3.5 py-1.5 bg-neutral-900 text-white hover:bg-neutral-800 text-xs font-semibold transition-colors cursor-pointer"
            @click="openInviteModal"
          >
            + Invite
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[840px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Operator</th>
              <th class="py-3 px-4">Department</th>
              <th class="py-3 px-4">Role</th>
              <th class="py-3 px-4">MFA</th>
              <th class="py-3 px-4">Activity</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="operator in filteredOperators"
              :key="operator.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-bold text-neutral-900">{{ operator.name }}</div>
                <div class="text-[11px] text-neutral-500 font-mono">{{ operator.email }}</div>
              </td>
              <td class="py-3 px-4 text-neutral-700 font-medium">{{ operator.department }}</td>
              <td class="py-3 px-4">
                <BaseSelect
                  :model-value="operator.role"
                  :disabled="operator.id === 'OPS-001'"
                  aria-label="Assign operator role"
                  :full-width="true"
                  :options="roleOptions"
                  @update:model-value="updateRole(operator, $event)"
                />
              </td>
              <td class="py-3 px-4">
                <button
                  type="button"
                  class="inline-flex items-center space-x-1 px-2 py-0.5 text-[10px] font-semibold cursor-pointer border"
                  :class="
                    operator.mfaEnabled
                      ? 'bg-neutral-900 text-white border-neutral-900 hover:bg-neutral-800'
                      : 'bg-white text-neutral-700 border-neutral-300 hover:bg-neutral-100'
                  "
                  @click="toggleMfa(operator)"
                >
                  <Icon
                    :icon="operator.mfaEnabled ? 'lucide:shield-check' : 'lucide:shield-alert'"
                    class="text-xs"
                  />
                  <span>{{ operator.mfaEnabled ? 'Hardware MFA' : 'Pending' }}</span>
                </button>
              </td>
              <td class="py-3 px-4 text-neutral-500">{{ operator.lastActive }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="operator.status"
                  :tone="operator.status === 'Active' ? 'success' : 'danger'"
                />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  v-if="operator.id !== 'OPS-001'"
                  type="button"
                  class="text-xs font-semibold text-neutral-700 hover:text-neutral-900 cursor-pointer"
                  @click="((statusReason = ''), (pendingStatusTarget = operator))"
                >
                  {{ operator.status === 'Suspended' ? 'Reactivate' : 'Suspend' }}
                </button>
                <span v-else class="text-[11px] font-mono text-neutral-400">Root</span>
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredOperators.length === 0"
              :colspan="7"
              title="No operators match your filter"
              :show-reset="Boolean(searchQuery)"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>

    <ModalDialog
      v-model:open="showInviteModal"
      title="Invite Operator"
      size="md"
      close-label="Close modal"
    >
      <form class="space-y-4 text-xs" @submit.prevent="submitInvite">
        <div class="space-y-3">
          <div>
            <label class="block font-semibold text-neutral-700 mb-1">Full Name</label>
            <input
              v-model="inviteForm.name"
              type="text"
              required
              placeholder="Marco Dela Cruz"
              class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <div>
            <label class="block font-semibold text-neutral-700 mb-1">Work Email</label>
            <input
              v-model="inviteForm.email"
              type="email"
              required
              placeholder="marco.delacruz@easyride.ph"
              class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <div>
            <label class="block font-semibold text-neutral-700 mb-1">Department</label>
            <input
              v-model="inviteForm.department"
              type="text"
              required
              class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <div>
            <label class="block font-semibold text-neutral-700 mb-1">Role</label>
            <BaseSelect
              v-model="inviteForm.role"
              aria-label="Select role"
              :full-width="true"
              :options="roleOptions"
            />
          </div>
          <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer pt-1">
            <input v-model="inviteForm.mfaEnabled" type="checkbox" class="accent-neutral-900" />
            <span>Require MFA on first sign-in</span>
          </label>
        </div>

        <div class="flex items-center justify-end gap-2 pt-3 border-t border-neutral-100">
          <button
            type="button"
            class="px-4 py-2 bg-white border border-neutral-200 text-xs font-semibold text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            @click="showInviteModal = false"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          >
            Send Invite
          </button>
        </div>
      </form>
    </ModalDialog>

    <ConfirmDialog
      :open="Boolean(pendingStatusTarget)"
      v-model:reason="statusReason"
      :title="pendingStatusTarget?.status === 'Suspended' ? 'Restore Operator' : 'Suspend Operator'"
      :description="
        pendingStatusTarget?.status === 'Suspended'
          ? `Restore console access for ${pendingStatusTarget?.name}.`
          : `Revoke console session access for ${pendingStatusTarget?.name}.`
      "
      :confirm-label="pendingStatusTarget?.status === 'Suspended' ? 'Restore' : 'Suspend'"
      tone="neutral"
      :require-reason="pendingStatusTarget?.status !== 'Suspended'"
      reason-label="Reason"
      reason-placeholder="Enter access change reason..."
      @cancel="pendingStatusTarget = null"
      @confirm="confirmStatusToggle"
    />
  </div>
</template>
