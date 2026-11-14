<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import {
  BaseSelect,
  ConfirmDialog,
  EmptyTableRow,
  ModalDialog,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  ToastBanner,
  useDataTable,
  type ToastTone,
} from '@/shared'
import { useOperators, type OperatorAccount } from '@/features/users'

const {
  operators,
  roleOptions,
  inviteOperator,
  updateOperatorRole,
  toggleOperatorMfa,
  suspendOperator,
  reactivateOperator,
} = useOperators()

const searchQuery = ref('')
const roleFilter = ref('ALL')
const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('success')

const showInviteModal = ref(false)
const inviteForm = reactive({
  name: '',
  email: '',
  role: roleOptions[1] ?? roleOptions[0]!,
})
const pendingToggleStatus = ref<OperatorAccount | null>(null)
const statusReason = ref('')

const filteredOperators = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return operators.value.filter((op) => {
    if (roleFilter.value !== 'ALL' && op.role !== roleFilter.value) return false
    if (!q) return true
    return (
      op.id.toLowerCase().includes(q) ||
      op.name.toLowerCase().includes(q) ||
      op.email.toLowerCase().includes(q) ||
      op.role.toLowerCase().includes(q)
    )
  })
})

const hasActiveFilters = computed(() =>
  Boolean(searchQuery.value.trim() || roleFilter.value !== 'ALL'),
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredOperators, {
  initialPageSize: 8,
  resetDeps: [searchQuery, roleFilter],
})

function resetFilters() {
  searchQuery.value = ''
  roleFilter.value = 'ALL'
}

function submitInvite() {
  const result = inviteOperator({
    name: inviteForm.name,
    email: inviteForm.email,
    role: inviteForm.role,
  })
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  toastTone.value = 'success'
  toastMessage.value = result.message
  inviteForm.name = ''
  inviteForm.email = ''
  showInviteModal.value = false
}

function handleRoleChange(id: string, nextRole: string) {
  const result = updateOperatorRole(id, nextRole)
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  toastTone.value = 'info'
  toastMessage.value = result.message
}

function handleToggleMfa(id: string) {
  const result = toggleOperatorMfa(id)
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  toastTone.value = 'warning'
  toastMessage.value = result.message
}

function confirmOperatorStatus() {
  const target = pendingToggleStatus.value
  if (!target) return

  const result =
    target.status === 'Suspended'
      ? reactivateOperator(target.id)
      : suspendOperator(target.id, statusReason.value)

  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  toastTone.value = target.status === 'Suspended' ? 'success' : 'warning'
  toastMessage.value = result.message
  pendingToggleStatus.value = null
  statusReason.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Operators"
      description="Manage admin staff accounts, role permissions, and security settings."
    >
      <template #actions>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="showInviteModal = true"
        >
          + Invite Operator
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col md:flex-row md:items-center md:justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="w-full sm:w-64">
            <SearchField
              v-model="searchQuery"
              placeholder="Search name, email, role..."
              aria-label="Search operators"
            />
          </div>
          <BaseSelect
            v-model="roleFilter"
            aria-label="Filter operators by role"
            :options="[
              { label: 'All Roles', value: 'ALL' },
              ...roleOptions.map((role) => ({ label: role, value: role })),
            ]"
          />
        </div>
        <span
          class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold text-neutral-800 tabular-nums self-start md:self-auto"
        >
          Staff Accounts: {{ filteredOperators.length }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[820px] text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">ID</th>
              <th class="py-3 px-4">Operator</th>
              <th class="py-3 px-4">Assigned Role</th>
              <th class="py-3 px-4">MFA</th>
              <th class="py-3 px-4">Last Active</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr v-for="op in paginatedItems" :key="op.id" class="hover:bg-neutral-50/50">
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ op.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ op.name }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ op.email }}</div>
              </td>
              <td class="py-3 px-4">
                <BaseSelect
                  :model-value="op.role"
                  :disabled="op.id === 'OPS-001'"
                  :aria-label="`Assigned role for ${op.name}`"
                  :options="roleOptions.map((role) => ({ label: role, value: role }))"
                  @update:model-value="handleRoleChange(op.id, $event)"
                />
              </td>
              <td class="py-3 px-4">
                <button
                  type="button"
                  :disabled="op.id === 'OPS-001'"
                  class="px-2 py-1 text-[11px] font-semibold border cursor-pointer disabled:opacity-50"
                  :class="
                    op.mfaEnabled
                      ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                      : 'bg-amber-50 text-amber-700 border-amber-200'
                  "
                  @click="handleToggleMfa(op.id)"
                >
                  {{ op.mfaEnabled ? '2FA Enabled' : '2FA Disabled' }}
                </button>
              </td>
              <td class="py-3 px-4 text-neutral-500">{{ op.lastActive }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="op.status"
                  :tone="op.status === 'Active' ? 'success' : 'danger'"
                />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  :disabled="op.id === 'OPS-001'"
                  class="text-xs font-semibold cursor-pointer disabled:opacity-40"
                  :class="op.status === 'Suspended' ? 'text-emerald-700' : 'text-rose-700'"
                  @click="((statusReason = ''), (pendingToggleStatus = op))"
                >
                  {{ op.status === 'Suspended' ? 'Reactivate' : 'Suspend' }}
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="7"
              title="No matching operators"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredOperators.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="showInviteModal"
      title="Invite Staff Operator"
      subtitle="Provision admin console access with hardware or TOTP 2FA enabled."
      size="md"
      close-label="Close modal"
      @update:open="showInviteModal = $event"
    >
      <form class="space-y-4 text-xs" @submit.prevent="submitInvite">
        <div>
          <label class="block text-[11px] font-semibold text-neutral-500 uppercase mb-1">
            Full Name
          </label>
          <input
            v-model="inviteForm.name"
            type="text"
            required
            placeholder="e.g. Lorraine Bautista"
            class="w-full px-3 py-2 border border-neutral-300 text-xs focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label class="block text-[11px] font-semibold text-neutral-500 uppercase mb-1">
            Corporate Email
          </label>
          <input
            v-model="inviteForm.email"
            type="email"
            required
            placeholder="operator@pagadian.ph"
            class="w-full px-3 py-2 border border-neutral-300 text-xs focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label class="block text-[11px] font-semibold text-neutral-500 uppercase mb-1">
            Console Role
          </label>
          <BaseSelect
            v-model="inviteForm.role"
            aria-label="Console Role"
            :options="roleOptions.map((role) => ({ label: role, value: role }))"
          />
        </div>
        <div class="flex justify-end gap-2 pt-2 border-t border-neutral-100">
          <button
            type="button"
            class="px-4 py-2 border border-neutral-300 text-neutral-700 text-xs font-semibold cursor-pointer"
            @click="showInviteModal = false"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold cursor-pointer"
          >
            Send Invite
          </button>
        </div>
      </form>
    </ModalDialog>

    <ConfirmDialog
      v-model:reason="statusReason"
      :open="Boolean(pendingToggleStatus)"
      :title="
        pendingToggleStatus?.status === 'Suspended' ? 'Reactivate Operator' : 'Suspend Operator'
      "
      :description="
        pendingToggleStatus
          ? pendingToggleStatus.status === 'Suspended'
            ? `Restore console sign-in access for ${pendingToggleStatus.name}.`
            : `Revoke console sign-in access for ${pendingToggleStatus.name}.`
          : ''
      "
      :tone="pendingToggleStatus?.status === 'Suspended' ? 'emerald' : 'rose'"
      :confirm-label="
        pendingToggleStatus?.status === 'Suspended' ? 'Reactivate Operator' : 'Suspend Operator'
      "
      @update:open="!$event && (pendingToggleStatus = null)"
      @confirm="confirmOperatorStatus"
    />
  </div>
</template>
