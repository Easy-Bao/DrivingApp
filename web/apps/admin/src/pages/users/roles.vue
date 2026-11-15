<script setup lang="ts">
import { ref } from 'vue'
import { ModalDialog, PageHeader, ToastBanner, type ToastTone } from '@/shared'
import { useRoles, type RbacRole } from '@/features/users'

const { roles, permissionCatalog, roleUserCounts, saveRole } = useRoles()

const showRoleModal = ref(false)
const editingRoleId = ref<string | null>(null)
const formName = ref('')
const formSummary = ref('')
const formScopes = ref<string[]>([])
const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('success')

function openCreateRole() {
  editingRoleId.value = null
  formName.value = ''
  formSummary.value = ''
  formScopes.value = ['Safety Moderation']
  showRoleModal.value = true
}

function openEditRole(role: RbacRole) {
  editingRoleId.value = role.id
  formName.value = role.name
  formSummary.value = role.summary
  formScopes.value = [...role.scopes]
  showRoleModal.value = true
}

function toggleScope(scope: string) {
  if (formScopes.value.includes(scope)) {
    formScopes.value = formScopes.value.filter((item) => item !== scope)
  } else {
    formScopes.value = [...formScopes.value, scope]
  }
}

function submitRole() {
  const result = saveRole({
    id: editingRoleId.value ?? undefined,
    name: formName.value,
    description: formSummary.value,
    scopes: formScopes.value,
  })
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  toastTone.value = 'success'
  toastMessage.value = result.message
  showRoleModal.value = false
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader title="Roles" description="Manage RBAC permission groups and staff scopes.">
      <template #actions>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="openCreateRole"
        >
          + Create Role
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="role in roles"
        :key="role.id"
        class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4"
      >
        <div class="space-y-3">
          <div class="flex items-start justify-between gap-2">
            <div>
              <h2 class="text-sm font-bold text-neutral-900">{{ role.name }}</h2>
              <p class="text-xs text-neutral-500 mt-0.5">{{ role.summary }}</p>
            </div>
            <span
              class="px-2 py-0.5 bg-neutral-100 border border-neutral-200 text-[11px] font-mono font-semibold text-neutral-700 shrink-0"
            >
              {{ roleUserCounts[role.name] ?? role.usersCount }} staff
            </span>
          </div>

          <div class="flex flex-wrap gap-1.5">
            <span
              v-for="scope in role.scopes"
              :key="scope"
              class="px-2 py-0.5 text-[11px] font-medium bg-neutral-50 border border-neutral-200 text-neutral-700"
            >
              {{ scope }}
            </span>
          </div>
        </div>

        <div class="pt-3 border-t border-neutral-100 flex items-center justify-between text-xs">
          <span class="font-mono text-neutral-400">{{ role.id }}</span>
          <button
            type="button"
            class="font-semibold text-neutral-900 hover:underline cursor-pointer"
            @click="openEditRole(role)"
          >
            Edit Permissions
          </button>
        </div>
      </div>
    </div>

    <ModalDialog
      :open="showRoleModal"
      :title="editingRoleId ? 'Edit Role Permissions' : 'Create New Role'"
      subtitle="Select console capabilities granted to operators holding this role."
      size="md"
      close-label="Close"
      @update:open="showRoleModal = $event"
    >
      <form class="space-y-4 text-xs" @submit.prevent="submitRole">
        <div class="space-y-3">
          <div>
            <label class="block text-[11px] font-semibold uppercase text-neutral-500 mb-1">
              Role Title
            </label>
            <input
              v-model="formName"
              type="text"
              required
              placeholder="e.g. Dispatch Reviewer"
              class="w-full px-3 py-2 border border-neutral-300 text-xs focus:outline-none focus:border-neutral-900"
            />
          </div>
          <div>
            <label class="block text-[11px] font-semibold uppercase text-neutral-500 mb-1">
              Description
            </label>
            <input
              v-model="formSummary"
              type="text"
              placeholder="Role responsibilities..."
              class="w-full px-3 py-2 border border-neutral-300 text-xs focus:outline-none focus:border-neutral-900"
            />
          </div>
          <div>
            <div class="text-[11px] font-semibold uppercase text-neutral-500 mb-1.5">
              Permission Scopes
            </div>
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
