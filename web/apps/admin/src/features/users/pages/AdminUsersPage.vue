<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

interface AdminOperator {
  id: string
  name: string
  email: string
  role: string
  department: string
  mfaEnabled: boolean
  lastActive: string
  status: 'Active' | 'Suspended'
}

const availableRoles = [
  'Super Administrator',
  'Dispatch & Safety Supervisor',
  'Treasury & Settlements Officer',
  'Trust & Safety Lead',
]

const adminUsers = ref<AdminOperator[]>([
  {
    id: 'ADM-001',
    name: 'Operations Control Lead',
    email: 'ops@easyride.ph',
    role: 'Super Administrator',
    department: 'Executive Operations',
    mfaEnabled: true,
    lastActive: 'Active now',
    status: 'Active',
  },
  {
    id: 'ADM-002',
    name: 'Marisol Lim',
    email: 'marisol.lim@easyride.ph',
    role: 'Dispatch & Safety Supervisor',
    department: 'Pagadian Fleet Dispatch',
    mfaEnabled: true,
    lastActive: '12 mins ago',
    status: 'Active',
  },
  {
    id: 'ADM-003',
    name: 'Rafael Bautista',
    email: 'rafael.bautista@easyride.ph',
    role: 'Treasury & Settlements Officer',
    department: 'Treasury & Wallet QA',
    mfaEnabled: true,
    lastActive: '1 hour ago',
    status: 'Active',
  },
  {
    id: 'ADM-004',
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
  department: 'Pagadian Fleet Dispatch',
  role: availableRoles[1]!,
  mfaEnabled: true,
})

const pendingStatusTarget = ref<AdminOperator | null>(null)
const statusReason = ref('')

const filteredUsers = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return adminUsers.value
  return adminUsers.value.filter(
    (user) =>
      user.name.toLowerCase().includes(q) ||
      user.email.toLowerCase().includes(q) ||
      user.role.toLowerCase().includes(q) ||
      user.department.toLowerCase().includes(q),
  )
})

const activeCount = computed(
  () => adminUsers.value.filter((user) => user.status === 'Active').length,
)

const openInviteModal = () => {
  inviteForm.value = {
    name: '',
    email: '',
    department: 'Pagadian Fleet Dispatch',
    role: availableRoles[1]!,
    mfaEnabled: true,
  }
  showInviteModal.value = true
}

const submitInvite = () => {
  if (!inviteForm.value.name.trim() || !inviteForm.value.email.includes('@')) {
    toastTone.value = 'error'
    toastMessage.value = 'Provide valid operator name and work email address.'
    return
  }
  const nextNumber = adminUsers.value.length + 1
  adminUsers.value.push({
    id: `ADM-${String(nextNumber).padStart(3, '0')}`,
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
  toastMessage.value = `Provisioned operator account for ${inviteForm.value.name.trim()}.`
}

const updateRole = (operator: AdminOperator, newRole: string) => {
  operator.role = newRole
  toastTone.value = 'success'
  toastMessage.value = `${operator.name} reassigned to ${newRole}.`
}

const toggleMfa = (operator: AdminOperator) => {
  operator.mfaEnabled = !operator.mfaEnabled
  toastTone.value = operator.mfaEnabled ? 'success' : 'warning'
  toastMessage.value = operator.mfaEnabled
    ? `Hardware MFA enforced for ${operator.name}.`
    : `Hardware MFA reset requested for ${operator.name}.`
}

const confirmStatusToggle = () => {
  const target = pendingStatusTarget.value
  if (!target) return
  if (target.status === 'Suspended') {
    target.status = 'Active'
    toastTone.value = 'success'
    toastMessage.value = `${target.name} restored to Active operator status.`
  } else {
    if (!statusReason.value.trim()) return
    target.status = 'Suspended'
    toastTone.value = 'warning'
    toastMessage.value = `${target.name} session suspended (${statusReason.value.trim()}).`
  }
  pendingStatusTarget.value = null
  statusReason.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Admin Users &amp; Operators
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Manage Pagadian operations staff accounts, RBAC role assignments, and MFA enforcement.
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <RouterLink
          to="/users/roles"
          class="px-3.5 py-2 bg-neutral-100 hover:bg-neutral-200 text-neutral-900 rounded-md text-xs font-semibold transition-colors"
        >
          Roles &amp; RBAC Matrix →
        </RouterLink>
        <button
          type="button"
          @click="openInviteModal"
          class="px-3.5 py-2 bg-neutral-900 text-white hover:bg-neutral-800 rounded-md text-xs font-semibold transition-colors cursor-pointer"
        >
          + Add Operator
        </button>
      </div>
    </div>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="bg-white rounded-lg border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <h2 class="font-bold text-sm text-neutral-900">
          Active Staff Administrators ({{ activeCount }})
        </h2>
        <div class="relative w-full sm:w-64">
          <Icon
            icon="lucide:search"
            class="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400 text-sm"
          />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search staff name, email, role..."
            class="w-full pl-9 pr-3 py-1.5 bg-white border border-neutral-200 rounded-md text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
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
              <th class="py-3 px-4">Assigned Role</th>
              <th class="py-3 px-4">MFA Security</th>
              <th class="py-3 px-4">Last Activity</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="user in filteredUsers"
              :key="user.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-bold text-neutral-900">{{ user.name }}</div>
                <div class="text-[11px] text-neutral-500 font-mono">{{ user.email }}</div>
              </td>
              <td class="py-3 px-4 text-neutral-700 font-medium">{{ user.department }}</td>
              <td class="py-3 px-4">
                <BaseSelect
                  :model-value="user.role"
                  :disabled="user.id === 'ADM-001'"
                  aria-label="Assign operator role"
                  :full-width="true"
                  :options="availableRoles"
                  @update:model-value="updateRole(user, $event)"
                />
              </td>
              <td class="py-3 px-4">
                <button
                  type="button"
                  @click="toggleMfa(user)"
                  class="inline-flex items-center space-x-1 px-2 py-0.5 rounded-full text-[10px] font-semibold cursor-pointer"
                  :class="
                    user.mfaEnabled
                      ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
                      : 'bg-amber-100 text-amber-800 hover:bg-amber-200'
                  "
                >
                  <Icon
                    :icon="user.mfaEnabled ? 'lucide:shield-check' : 'lucide:shield-alert'"
                    class="text-xs"
                  />
                  <span>{{ user.mfaEnabled ? 'Hardware MFA' : 'MFA Pending' }}</span>
                </button>
              </td>
              <td class="py-3 px-4 text-neutral-500">{{ user.lastActive }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="user.status"
                  :tone="user.status === 'Active' ? 'success' : 'danger'"
                />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  v-if="user.id !== 'ADM-001'"
                  type="button"
                  @click="((statusReason = ''), (pendingStatusTarget = user))"
                  class="text-xs font-semibold cursor-pointer"
                  :class="
                    user.status === 'Suspended'
                      ? 'text-emerald-700 hover:text-emerald-900'
                      : 'text-rose-600 hover:text-rose-800'
                  "
                >
                  {{ user.status === 'Suspended' ? 'Reactivate' : 'Suspend' }}
                </button>
                <span v-else class="text-[11px] font-mono text-neutral-400">Primary Root</span>
              </td>
            </tr>
            <tr v-if="filteredUsers.length === 0">
              <td colspan="7" class="py-8 text-center text-xs text-neutral-500">
                No staff operators match your search filter.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <Teleport to="body">
      <div
        v-if="showInviteModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/50 backdrop-blur-[1px] p-4"
        role="dialog"
        aria-modal="true"
        @click.self="showInviteModal = false"
      >
        <form
          class="bg-white rounded-lg border border-neutral-200 shadow-2xl w-full max-w-md p-6 space-y-4"
          @submit.prevent="submitInvite"
        >
          <div class="flex items-center justify-between border-b border-neutral-100 pb-3">
            <h3 class="text-base font-bold text-neutral-900">Provision Staff Operator</h3>
            <button
              type="button"
              aria-label="Close modal"
              @click="showInviteModal = false"
              class="text-neutral-400 hover:text-neutral-700 cursor-pointer"
            >
              <Icon icon="lucide:x" class="w-4 h-4" />
            </button>
          </div>

          <div class="space-y-3 text-xs">
            <div>
              <label class="block font-semibold text-neutral-700 mb-1">Full Name</label>
              <input
                v-model="inviteForm.name"
                type="text"
                required
                placeholder="e.g. Marco Dela Cruz"
                class="w-full px-3 py-2 border border-neutral-200 rounded-md focus:outline-none focus:border-neutral-900"
              />
            </div>
            <div>
              <label class="block font-semibold text-neutral-700 mb-1"
                >Work Email (@easyride.ph)</label
              >
              <input
                v-model="inviteForm.email"
                type="email"
                required
                placeholder="marco.delacruz@easyride.ph"
                class="w-full px-3 py-2 border border-neutral-200 rounded-md focus:outline-none focus:border-neutral-900"
              />
            </div>
            <div>
              <label class="block font-semibold text-neutral-700 mb-1">Department</label>
              <input
                v-model="inviteForm.department"
                type="text"
                required
                class="w-full px-3 py-2 border border-neutral-200 rounded-md focus:outline-none focus:border-neutral-900"
              />
            </div>
            <div>
              <label class="block font-semibold text-neutral-700 mb-1">RBAC Role</label>
              <BaseSelect
                v-model="inviteForm.role"
                aria-label="Select RBAC role"
                :full-width="true"
                :options="availableRoles"
              />
            </div>
            <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer pt-1">
              <input v-model="inviteForm.mfaEnabled" type="checkbox" class="accent-neutral-900" />
              <span>Require hardware FIDO2 / TOTP on first sign-in</span>
            </label>
          </div>

          <div class="flex items-center justify-end gap-2 pt-2 border-t border-neutral-100">
            <button
              type="button"
              @click="showInviteModal = false"
              class="px-4 py-2 bg-white border border-neutral-200 rounded-md text-xs font-semibold text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="px-4 py-2 bg-neutral-900 text-white rounded-md text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            >
              Send Operator Invite
            </button>
          </div>
        </form>
      </div>
    </Teleport>

    <ConfirmDialog
      :open="Boolean(pendingStatusTarget)"
      v-model:reason="statusReason"
      :title="
        pendingStatusTarget?.status === 'Suspended'
          ? 'Restore Operator Access'
          : 'Suspend Operator Access'
      "
      :description="
        pendingStatusTarget?.status === 'Suspended'
          ? `Re-enable console authentication for ${pendingStatusTarget?.name}.`
          : `Immediately revoke console session tokens for ${pendingStatusTarget?.name}.`
      "
      :confirm-label="
        pendingStatusTarget?.status === 'Suspended' ? 'Restore Operator' : 'Suspend Operator'
      "
      :tone="pendingStatusTarget?.status === 'Suspended' ? 'emerald' : 'rose'"
      :require-reason="pendingStatusTarget?.status !== 'Suspended'"
      reason-label="Audit justification (mandatory)"
      reason-placeholder="Specify access revocation reason or staff transition..."
      @cancel="pendingStatusTarget = null"
      @confirm="confirmStatusToggle"
    />
  </div>
</template>
