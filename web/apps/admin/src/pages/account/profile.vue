<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
import { ROLE_PROFILES, lockAuthSession, updateOperatorProfile, useAuthSession } from '@/core'

const router = useRouter()
const authSession = useAuthSession()

const lockConsoleSession = () => {
  lockAuthSession()
  void router.push({ name: '/auth/login', query: { redirect: '/account/profile' } })
}

const fullName = ref(authSession.value.operatorName)
const email = ref(authSession.value.operatorEmail)
const phone = ref('+63 917 801 7016')
const regionHub = ref('Pagadian City Dispatch Hub')
const mfaMethod = ref<'authenticator' | 'hardware_key'>('authenticator')

watch(
  () => [authSession.value.operatorName, authSession.value.operatorEmail] as const,
  ([nextName, nextEmail]) => {
    fullName.value = nextName
    email.value = nextEmail
  },
)

const roleLabel = computed(() =>
  authSession.value.role ? ROLE_PROFILES[authSession.value.role].label : 'Session Locked',
)
const employeeCode = computed(() => authSession.value.userId?.toUpperCase() || 'OP-SESSION')

const toastMessage = ref<string | null>(null)
const toastTone = ref<'success' | 'warning' | 'error' | 'info'>('success')

const showPasswordModal = ref(false)
const currentPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const passwordError = ref('')

const initials = computed(() => {
  const parts = fullName.value.trim().split(/\s+/).filter(Boolean)
  if (parts.length === 0) return 'AD'
  if (parts.length === 1) return parts[0]!.slice(0, 2).toUpperCase()
  return `${parts[0]![0]}${parts[1]![0]}`.toUpperCase()
})

const saveProfile = () => {
  const result = updateOperatorProfile({
    operatorName: fullName.value,
    operatorEmail: email.value,
  })
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  toastTone.value = 'success'
  toastMessage.value = 'Operator profile preferences updated.'
}

const toggleMfaMethod = () => {
  mfaMethod.value = mfaMethod.value === 'authenticator' ? 'hardware_key' : 'authenticator'
  toastTone.value = 'info'
  toastMessage.value =
    mfaMethod.value === 'hardware_key'
      ? 'Primary MFA switched to FIDO2 Hardware Security Key.'
      : 'Primary MFA switched to Authenticator TOTP App.'
}

const openPasswordModal = () => {
  currentPassword.value = ''
  newPassword.value = ''
  confirmPassword.value = ''
  passwordError.value = ''
  showPasswordModal.value = true
}

const submitPasswordRotation = () => {
  if (newPassword.value.length < 10) {
    passwordError.value = 'New passphrase must be at least 10 characters.'
    return
  }
  if (newPassword.value !== confirmPassword.value) {
    passwordError.value = 'New passphrase confirmation does not match.'
    return
  }
  showPasswordModal.value = false
  toastTone.value = 'success'
  toastMessage.value = 'Session credentials rotated and active tokens refreshed.'
}
</script>

<template>
  <div class="space-y-6 w-full">
    <PageHeader
      title="Profile"
      description="Manage account details, hub assignment, and security settings."
    >
      <template #actions>
        <button
          type="button"
          class="inline-flex items-center justify-center space-x-2 px-4 py-2 bg-white border border-neutral-200 text-xs font-semibold text-neutral-800 hover:bg-neutral-50 transition-colors cursor-pointer"
          @click="openPasswordModal"
        >
          <Icon icon="lucide:key-round" class="w-4 h-4" aria-hidden="true" />
          <span>Rotate Password</span>
        </button>
        <button
          type="button"
          class="inline-flex items-center justify-center space-x-2 px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 transition-colors cursor-pointer"
          @click="lockConsoleSession"
        >
          <Icon icon="lucide:lock" class="w-4 h-4" aria-hidden="true" />
          <span>Lock Session</span>
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <form
      class="bg-white rounded-none border border-neutral-200 p-6 space-y-6"
      @submit.prevent="saveProfile"
    >
      <div class="flex flex-col sm:flex-row sm:items-center gap-4 border-b border-neutral-100 pb-6">
        <div
          class="w-16 h-16 rounded-none bg-neutral-900 text-white flex items-center justify-center font-bold text-xl shrink-0"
        >
          {{ initials }}
        </div>
        <div class="space-y-1">
          <h2 class="text-base font-bold text-neutral-900">{{ fullName }}</h2>
          <p class="text-xs text-neutral-500 font-mono">
            {{ email }} · {{ phone }} · Operator ID: {{ employeeCode }}
          </p>
          <StatusBadge :label="roleLabel" tone="success" />
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
        <div>
          <label for="profile-full-name" class="block font-semibold text-neutral-700 mb-1">
            Full Name
          </label>
          <input
            id="profile-full-name"
            v-model="fullName"
            type="text"
            class="w-full px-3 py-2 bg-white border border-neutral-200 text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label for="profile-email" class="block font-semibold text-neutral-700 mb-1">
            Work Email Address
          </label>
          <input
            id="profile-email"
            v-model="email"
            type="email"
            class="w-full px-3 py-2 bg-white border border-neutral-200 text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label for="profile-phone" class="block font-semibold text-neutral-700 mb-1">
            Operations Contact
          </label>
          <input
            id="profile-phone"
            v-model="phone"
            type="tel"
            class="w-full px-3 py-2 bg-white border border-neutral-200 text-xs font-mono text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label for="profile-hub" class="block font-semibold text-neutral-700 mb-1">
            Assigned Operations Hub
          </label>
          <input
            id="profile-hub"
            v-model="regionHub"
            type="text"
            class="w-full px-3 py-2 bg-white border border-neutral-200 text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>
      </div>

      <div
        class="pt-4 border-t border-neutral-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div>
          <span class="text-xs font-semibold text-neutral-900">
            Two-Factor Authentication (2FA)
          </span>
          <p class="text-[11px] text-neutral-500">
            Active factor:
            {{
              mfaMethod === 'authenticator'
                ? 'Time-Based Authenticator App (TOTP)'
                : 'FIDO2 Hardware Security Key'
            }}
          </p>
        </div>
        <div class="flex items-center gap-2">
          <StatusBadge label="Enforced" tone="success" />
          <button
            type="button"
            @click="toggleMfaMethod"
            class="px-3 py-1.5 bg-neutral-100 hover:bg-neutral-200 text-neutral-800 rounded-none text-xs font-medium transition-colors cursor-pointer"
          >
            Switch 2FA Factor
          </button>
        </div>
      </div>

      <div class="flex justify-end pt-2">
        <button
          type="submit"
          class="px-4 py-2 bg-neutral-900 text-white rounded-none text-xs font-semibold hover:bg-neutral-800 transition-colors cursor-pointer"
        >
          Save Profile Changes
        </button>
      </div>
    </form>

    <ModalDialog
      v-model:open="showPasswordModal"
      title="Rotate Account Password"
      size="md"
      close-label="Close modal"
    >
      <form class="space-y-4 text-xs" @submit.prevent="submitPasswordRotation">
        <div class="space-y-3">
          <div>
            <label class="block font-semibold text-neutral-700 mb-1">Current Password</label>
            <input
              v-model="currentPassword"
              type="password"
              required
              class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <div>
            <label class="block font-semibold text-neutral-700 mb-1"
              >New Passphrase (min. 10 chars)</label
            >
            <input
              v-model="newPassword"
              type="password"
              required
              class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <div>
            <label class="block font-semibold text-neutral-700 mb-1">Confirm Passphrase</label>
            <input
              v-model="confirmPassword"
              type="password"
              required
              class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <p v-if="passwordError" class="text-rose-600 font-medium">{{ passwordError }}</p>
        </div>

        <div class="flex flex-wrap items-center justify-end gap-2 pt-3 border-t border-neutral-100">
          <button
            type="button"
            class="px-4 py-2 bg-white border border-neutral-200 text-xs font-semibold text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            @click="showPasswordModal = false"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          >
            Update Password
          </button>
        </div>
      </form>
    </ModalDialog>
  </div>
</template>
