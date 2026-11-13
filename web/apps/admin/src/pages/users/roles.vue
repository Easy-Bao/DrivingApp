<script setup lang="ts">
import { ref } from 'vue'
import ModalDialog from '@/shared/components/ModalDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

interface RbacRole {
  id: string
  name: string
  usersCount: number
  summary: string
  scopes: string[]
}

const permissionCatalog = [
  'Dispatch Override',
  'SOS Escalation',
  'Safety Moderation',
  'Top-Up Verification',
  'Settlement Ledger',
  'Driver Vetting',
  'Tariff & Surge',
  'Operator Access',
]

const roles = ref<RbacRole[]>([
  {
    id: 'ROLE-1',
    name: 'Root Operator',
    usersCount: 2,
    summary: 'Full configuration, ledger, and policy control.',
    scopes: [...permissionCatalog],
  },
  {
    id: 'ROLE-2',
    name: 'Fleet Ops',
    usersCount: 6,
    summary: 'Dispatch queues, SOS response, and safety moderation.',
    scopes: ['Dispatch Override', 'SOS Escalation', 'Safety Moderation'],
  },
  {
    id: 'ROLE-3',
    name: 'Finance Ops',
    usersCount: 3,
    summary: 'Top-up checks, settlements, and ledger exports.',
    scopes: ['Top-Up Verification', 'Settlement Ledger'],
  },
  {
    id: 'ROLE-4',
    name: 'Support Lead',
    usersCount: 8,
    summary: 'Driver vetting, ticket resolution, and moderation.',
    scopes: ['Driver Vetting', 'Safety Moderation'],
  },
])

const toastMessage = ref<string | null>(null)
const showRoleModal = ref(false)
const editingRoleId = ref<string | null>(null)
const formName = ref('')
const formSummary = ref('')
const formScopes = ref<string[]>([])

const openCreateModal = () => {
  editingRoleId.value = null
  formName.value = ''
  formSummary.value = ''
  formScopes.value = ['Safety Moderation']
  showRoleModal.value = true
}

const openEditModal = (role: RbacRole) => {
  editingRoleId.value = role.id
  formName.value = role.name
  formSummary.value = role.summary
  formScopes.value = [...role.scopes]
  showRoleModal.value = true
}

const toggleScope = (scope: string) => {
  if (formScopes.value.includes(scope)) {
    formScopes.value = formScopes.value.filter((item) => item !== scope)
  } else {
    formScopes.value = [...formScopes.value, scope]
  }
}

const saveRoleModal = () => {
  if (!formName.value.trim() || formScopes.value.length === 0) return

  if (editingRoleId.value) {
    const existing = roles.value.find((item) => item.id === editingRoleId.value)
    if (existing) {
      existing.name = formName.value.trim()
      existing.summary = formSummary.value.trim() || existing.summary
      existing.scopes = [...formScopes.value]
      toastMessage.value = `Updated permissions for ${existing.name}.`
    }
  } else {
    roles.value.push({
      id: `ROLE-${roles.value.length + 1}`,
      name: formName.value.trim(),
      usersCount: 0,
      summary: formSummary.value.trim() || 'Custom role scope.',
      scopes: [...formScopes.value],
    })
    toastMessage.value = `Created role "${formName.value.trim()}".`
  }

  showRoleModal.value = false
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader title="Staff Roles" description="Manage role permissions and access scopes.">
      <template #actions>
        <button
          type="button"
          class="px-3.5 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 transition-colors cursor-pointer"
          @click="openCreateModal"
        >
          + Create Role
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" tone="success" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="role in roles"
        :key="role.id"
        class="p-5 bg-white border border-neutral-200 space-y-3 flex flex-col justify-between"
      >
        <div class="space-y-3">
          <div class="flex items-center justify-between gap-2">
            <h3 class="font-bold text-sm text-neutral-900">{{ role.name }}</h3>
            <StatusBadge :label="`${role.usersCount} Users`" tone="neutral" />
          </div>
          <p class="text-xs text-neutral-600 leading-relaxed">{{ role.summary }}</p>
          <div class="flex flex-wrap gap-1.5">
            <span
              v-for="scope in role.scopes"
              :key="scope"
              class="px-2 py-0.5 bg-neutral-100 text-neutral-700 text-[11px] font-medium"
            >
              {{ scope }}
            </span>
          </div>
        </div>
        <div class="pt-3 border-t border-neutral-100 flex justify-between items-center text-xs">
          <button
            type="button"
            @click="openEditModal(role)"
            class="text-neutral-700 hover:text-neutral-900 font-semibold cursor-pointer"
          >
            Edit Permissions
          </button>
          <RouterLink
            to="/settings/audit-logs"
            class="text-neutral-500 hover:text-neutral-900 font-medium"
          >
            Audit Logs →
          </RouterLink>
        </div>
      </div>
    </div>

    <ModalDialog
      v-model:open="showRoleModal"
      :title="editingRoleId ? 'Edit Role Permissions' : 'Create Role'"
      size="lg"
      close-label="Close modal"
    >
      <form class="space-y-4 text-xs" @submit.prevent="saveRoleModal">
        <div class="space-y-3">
          <div>
            <label class="block font-semibold text-neutral-700 mb-1">Role Name</label>
            <input
              v-model="formName"
              type="text"
              required
              placeholder="e.g. Dispatch Reviewer"
              class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <div>
            <label class="block font-semibold text-neutral-700 mb-1">Summary</label>
            <input
              v-model="formSummary"
              type="text"
              placeholder="Role responsibilities..."
              class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <div>
            <span class="block font-semibold text-neutral-700 mb-2">Permissions</span>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
              <label
                v-for="scope in permissionCatalog"
                :key="scope"
                class="flex items-center space-x-2 p-2 border border-neutral-200 cursor-pointer hover:bg-neutral-50"
              >
                <input
                  type="checkbox"
                  :checked="formScopes.includes(scope)"
                  class="accent-neutral-900"
                  @change="toggleScope(scope)"
                />
                <span class="text-neutral-800 font-medium">{{ scope }}</span>
              </label>
            </div>
          </div>
        </div>

        <div class="flex items-center justify-end gap-2 pt-3 border-t border-neutral-100">
          <button
            type="button"
            class="px-4 py-2 bg-white border border-neutral-200 text-xs font-semibold text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            @click="showRoleModal = false"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="formScopes.length === 0"
            class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 disabled:opacity-40 cursor-pointer"
          >
            {{ editingRoleId ? 'Save' : 'Create' }}
          </button>
        </div>
      </form>
    </ModalDialog>
  </div>
</template>
