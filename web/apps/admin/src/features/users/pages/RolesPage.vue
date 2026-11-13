<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'
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
  'Live Dispatch Override',
  'SOS Incident Escalation',
  'Safety Reports Moderation',
  'Driver Top-Up Verification',
  'Cash Settlement Reconciliation',
  'Driver Compliance Vetting',
  'Tariff & Surge Configuration',
  'Staff & RBAC Management',
]

const roles = ref<RbacRole[]>([
  {
    id: 'ROLE-1',
    name: 'Super Administrator',
    usersCount: 2,
    summary: 'Unrestricted platform operations, treasury sign-off, and security policies.',
    scopes: [...permissionCatalog],
  },
  {
    id: 'ROLE-2',
    name: 'Dispatch & Safety Supervisor',
    usersCount: 6,
    summary: 'Real-time dispatch queue intervention, SOS emergency response, and safety reports.',
    scopes: ['Live Dispatch Override', 'SOS Incident Escalation', 'Safety Reports Moderation'],
  },
  {
    id: 'ROLE-3',
    name: 'Treasury & Settlements Officer',
    usersCount: 3,
    summary: 'Manual QRPh top-up verification, cash settlement waivers, and ledger exports.',
    scopes: ['Driver Top-Up Verification', 'Cash Settlement Reconciliation'],
  },
  {
    id: 'ROLE-4',
    name: 'Trust & Safety Lead',
    usersCount: 8,
    summary: 'Driver LTO/MTOP vetting, ticket arbitration, and rider/driver suspension review.',
    scopes: ['Driver Compliance Vetting', 'Safety Reports Moderation'],
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
  formScopes.value = ['Safety Reports Moderation']
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
      toastMessage.value = `Updated RBAC permissions for ${existing.name}.`
    }
  } else {
    roles.value.push({
      id: `ROLE-${roles.value.length + 1}`,
      name: formName.value.trim(),
      usersCount: 0,
      summary: formSummary.value.trim() || 'Custom regional operations role.',
      scopes: [...formScopes.value],
    })
    toastMessage.value = `Created custom RBAC role "${formName.value.trim()}".`
  }

  showRoleModal.value = false
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Staff Roles &amp; Permissions (RBAC)
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Configure role-based access scopes and module permissions across operations staff.
        </p>
      </div>
      <button
        type="button"
        @click="openCreateModal"
        class="px-3.5 py-2 bg-neutral-900 text-white rounded-md text-xs font-semibold hover:bg-neutral-800 transition-colors cursor-pointer"
      >
        + Create Custom Role
      </button>
    </div>

    <ToastBanner :message="toastMessage" tone="success" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="r in roles"
        :key="r.id"
        class="p-5 bg-white rounded-lg border border-neutral-200 space-y-3 flex flex-col justify-between"
      >
        <div class="space-y-3">
          <div class="flex items-center justify-between gap-2">
            <h3 class="font-bold text-sm text-neutral-900">{{ r.name }}</h3>
            <StatusBadge :label="`${r.usersCount} Users Assigned`" tone="neutral" />
          </div>
          <p class="text-xs text-neutral-600 leading-relaxed">{{ r.summary }}</p>
          <div class="flex flex-wrap gap-1.5">
            <span
              v-for="scope in r.scopes"
              :key="scope"
              class="px-2 py-0.5 bg-neutral-100 text-neutral-700 rounded text-[11px] font-medium"
            >
              {{ scope }}
            </span>
          </div>
        </div>
        <div class="pt-3 border-t border-neutral-100 flex justify-between items-center text-xs">
          <button
            type="button"
            @click="openEditModal(r)"
            class="text-neutral-700 hover:text-neutral-900 font-semibold cursor-pointer"
          >
            Edit Permissions
          </button>
          <RouterLink
            to="/settings/audit-logs"
            class="text-neutral-500 hover:text-neutral-900 font-medium"
          >
            Audit History →
          </RouterLink>
        </div>
      </div>
    </div>

    <Teleport to="body">
      <div
        v-if="showRoleModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/50 backdrop-blur-[1px] p-4"
        role="dialog"
        aria-modal="true"
        @click.self="showRoleModal = false"
      >
        <form
          class="bg-white rounded-lg border border-neutral-200 shadow-2xl w-full max-w-lg p-6 space-y-4"
          @submit.prevent="saveRoleModal"
        >
          <div class="flex items-center justify-between border-b border-neutral-100 pb-3">
            <h3 class="text-base font-bold text-neutral-900">
              {{ editingRoleId ? 'Edit Role Permissions' : 'Create Custom RBAC Role' }}
            </h3>
            <button
              type="button"
              aria-label="Close modal"
              @click="showRoleModal = false"
              class="text-neutral-400 hover:text-neutral-700 cursor-pointer"
            >
              <Icon icon="lucide:x" class="w-4 h-4" />
            </button>
          </div>

          <div class="space-y-3 text-xs">
            <div>
              <label class="block font-semibold text-neutral-700 mb-1">Role Title</label>
              <input
                v-model="formName"
                type="text"
                required
                placeholder="e.g. Pagadian Compliance Reviewer"
                class="w-full px-3 py-2 border border-neutral-200 rounded-md focus:outline-none focus:border-neutral-900"
              />
            </div>
            <div>
              <label class="block font-semibold text-neutral-700 mb-1">Description</label>
              <input
                v-model="formSummary"
                type="text"
                placeholder="Summary of responsibilities..."
                class="w-full px-3 py-2 border border-neutral-200 rounded-md focus:outline-none focus:border-neutral-900"
              />
            </div>
            <div>
              <span class="block font-semibold text-neutral-700 mb-2">
                Authorized Permission Scopes (select at least one)
              </span>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                <label
                  v-for="scope in permissionCatalog"
                  :key="scope"
                  class="flex items-center space-x-2 p-2 rounded border border-neutral-200 cursor-pointer hover:bg-neutral-50"
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

          <div class="flex items-center justify-end gap-2 pt-2 border-t border-neutral-100">
            <button
              type="button"
              @click="showRoleModal = false"
              class="px-4 py-2 bg-white border border-neutral-200 rounded-md text-xs font-semibold text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="formScopes.length === 0"
              class="px-4 py-2 bg-neutral-900 text-white rounded-md text-xs font-semibold hover:bg-neutral-800 disabled:opacity-40 cursor-pointer"
            >
              {{ editingRoleId ? 'Save Permissions' : 'Create Role' }}
            </button>
          </div>
        </form>
      </div>
    </Teleport>
  </div>
</template>
