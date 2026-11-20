<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ROLE_PROFILES, lockAuthSession, updateOperatorProfile, useAuthSession } from '@/core'
import { ModalDialog, PageHeader, StatusBadge, ToastBanner, getInitials, useToast } from '@/shared'

const router = useRouter()
const authSession = useAuthSession()

const lockConsoleSession = () => {
  lockAuthSession()
  void router.push({ name: '/auth/login', query: { redirect: '/account/profile' } })
}

const fullName = ref(authSession.value.operatorName)
const email = ref(authSession.value.operatorEmail)
const phone = ref('+63 917 801 7016')
const regionHub = ref('Main Hub')
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

const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

const showPasswordModal = ref(false)
const currentPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const passwordError = ref('')

const initials = computed(() => getInitials(fullName.value, 'AD'))

const saveProfile = () => {
  const result = updateOperatorProfile({
    operatorName: fullName.value,
    operatorEmail: email.value,
  })
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast('Operator profile preferences updated.', 'success')
}

const toggleMfaMethod = () => {
  mfaMethod.value = mfaMethod.value === 'authenticator' ? 'hardware_key' : 'authenticator'
  showToast(
    mfaMethod.value === 'hardware_key'
      ? 'Primary MFA switched to FIDO2 Hardware Security Key.'
      : 'Primary MFA switched to Authenticator TOTP App.',
    'info',
  )
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
  showToast('Session credentials rotated and active tokens refreshed.', 'success')
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
          class="px-4 py-2 bg-white border border-neutral-200 text-xs font-semibold text-neutral-800 hover:bg-neutral-50 transition-colors cursor-pointer"
          @click="openPasswordModal"
        >
          Rotate Password
        </button>
        <button
          type="button"
          class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 transition-colors cursor-pointer"
          @click="lockConsoleSession"
        >
          Lock Session
        </button>
      </template>
    </PageHeader>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

    <form class="bg-white border border-neutral-200 p-6 space-y-6" @submit.prevent="saveProfile">
      <div class="flex flex-col sm:flex-row sm:items-center gap-4 border-b border-neutral-100 pb-6">
        <div
          class="w-16 h-16 bg-neutral-900 text-white flex items-center justify-center font-bold text-xl shrink-0"
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
            Contact
          </label>
          <input
            id="profile-phone"
            v-model="phone"
            type="tel"
            class="w-full px-3 py-2 bg-white border border-neutral-200 text-xs font-mono text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label for="profile-hub" class="block font-semibold text-neutral-700 mb-1"> Hub </label>
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
            class="px-3 py-1.5 bg-neutral-100 hover:bg-neutral-200 text-neutral-800 text-xs font-medium transition-colors cursor-pointer"
          >
            Switch 2FA Factor
          </button>
        </div>
      </div>

      <div class="flex justify-end pt-2">
        <button
          type="submit"
          class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 transition-colors cursor-pointer"
        >
          Save Profile Changes
        </button>
      </div>
    </form>

    <ModalDialog
      v-model:open="showPasswordModal"
      title="Rotate Account Password"
      size="md"
      close-label="Close"
    >
      <form
        id="rotate-password-form"
        class="space-y-3 text-xs"
        @submit.prevent="submitPasswordRotation"
      >
        <div>
          <label for="rotate-current-password" class="block font-semibold text-neutral-700 mb-1">
            Current Password
          </label>
          <input
            id="rotate-current-password"
            v-model="currentPassword"
            type="password"
            autocomplete="current-password"
            required
            class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label for="rotate-new-password" class="block font-semibold text-neutral-700 mb-1">
            New Passphrase (min. 10 chars)
          </label>
          <input
            id="rotate-new-password"
            v-model="newPassword"
            type="password"
            autocomplete="new-password"
            required
            class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label for="rotate-confirm-password" class="block font-semibold text-neutral-700 mb-1">
            Confirm Passphrase
          </label>
          <input
            id="rotate-confirm-password"
            v-model="confirmPassword"
            type="password"
            autocomplete="new-password"
            required
            class="w-full px-3 py-2 border border-neutral-200 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <p v-if="passwordError" role="alert" class="text-rose-600 font-medium">
          {{ passwordError }}
        </p>
      </form>

      <template #footer>
        <button
          type="button"
          class="px-4 py-2 bg-white border border-neutral-200 text-xs font-semibold text-neutral-700 hover:bg-neutral-50 cursor-pointer"
          @click="showPasswordModal = false"
        >
          Cancel
        </button>
        <button
          type="submit"
          form="rotate-password-form"
          class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
        >
          Update Password
        </button>
      </template>
    </ModalDialog>
  </div>
</template>
