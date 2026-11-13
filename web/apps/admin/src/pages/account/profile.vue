<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import router from '@/app/router'
import { lockAuthSession } from '@/core/auth/auth-session'

const lockConsoleSession = () => {
  lockAuthSession()
  void router.push({ name: '/auth/login', query: { redirect: '/account/profile' } })
}

const fullName = ref('Operations Control Lead')
const email = ref('ops@easyride.ph')
const phone = ref('+63 917 801 7016')
const regionHub = ref('Pagadian City Dispatch Hub (ZIP 7016)')
const mfaMethod = ref<'authenticator' | 'hardware_key'>('authenticator')

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
  if (!fullName.value.trim() || !email.value.includes('@')) {
    toastTone.value = 'error'
    toastMessage.value = 'Enter a valid full name and email address before saving.'
    return
  }
  toastTone.value = 'success'
  toastMessage.value = 'Administrator profile preferences updated.'
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
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Profile Settings
        </h1>
        <p class="text-sm text-neutral-500 mt-1">Credentials, hub assignment, and 2FA.</p>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <button
          type="button"
          @click="openPasswordModal"
          class="inline-flex items-center justify-center space-x-2 px-4 py-2 bg-white border border-neutral-200 rounded-none text-xs font-semibold text-neutral-800 hover:bg-neutral-50 transition-colors cursor-pointer"
        >
          <Icon icon="lucide:key-round" class="w-4 h-4" />
          <span>Rotate Password</span>
        </button>
        <button
          type="button"
          @click="lockConsoleSession"
          class="inline-flex items-center justify-center space-x-2 px-4 py-2 bg-neutral-900 text-white rounded-none text-xs font-semibold hover:bg-neutral-800 transition-colors cursor-pointer"
        >
          <Icon icon="lucide:lock" class="w-4 h-4" />
          <span>Lock Session</span>
        </button>
      </div>
    </div>

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
            {{ email }} · {{ phone }} · Employee ID: EMP-001
          </p>
          <StatusBadge label="Root Access" tone="success" />
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
        <div>
          <label for="admin-full-name" class="block font-semibold text-neutral-700 mb-1">
            Full Name
          </label>
          <input
            id="admin-full-name"
            v-model="fullName"
            type="text"
            class="w-full px-3 py-2 bg-white border border-neutral-200 rounded-none text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label for="admin-email" class="block font-semibold text-neutral-700 mb-1">
            Work Email Address
          </label>
          <input
            id="admin-email"
            v-model="email"
            type="email"
            class="w-full px-3 py-2 bg-white border border-neutral-200 rounded-none text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label for="admin-phone" class="block font-semibold text-neutral-700 mb-1">
            Operations Contact (PH)
          </label>
          <input
            id="admin-phone"
            v-model="phone"
            type="tel"
            class="w-full px-3 py-2 bg-white border border-neutral-200 rounded-none text-xs font-mono text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>
        <div>
          <label for="admin-hub" class="block font-semibold text-neutral-700 mb-1">
            Assigned Operations Hub
          </label>
          <input
            id="admin-hub"
            v-model="regionHub"
            type="text"
            class="w-full px-3 py-2 bg-white border border-neutral-200 rounded-none text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
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

    <Teleport to="body">
      <div
        v-if="showPasswordModal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/50 backdrop-blur-[1px] p-4"
        role="dialog"
        aria-modal="true"
        aria-labelledby="password-modal-title"
        @click.self="showPasswordModal = false"
      >
        <form
          class="bg-white rounded-none border border-neutral-200 shadow-2xl w-full max-w-md p-6 space-y-4"
          @submit.prevent="submitPasswordRotation"
        >
          <div class="flex items-center justify-between">
            <h3 id="password-modal-title" class="text-base font-bold text-neutral-900">
              Rotate Administrator Password
            </h3>
            <button
              type="button"
              aria-label="Close modal"
              @click="showPasswordModal = false"
              class="text-neutral-400 hover:text-neutral-700 cursor-pointer"
            >
              <Icon icon="lucide:x" class="w-4 h-4" />
            </button>
          </div>

          <div class="space-y-3 text-xs">
            <div>
              <label class="block font-semibold text-neutral-700 mb-1">Current Password</label>
              <input
                v-model="currentPassword"
                type="password"
                required
                class="w-full px-3 py-2 border border-neutral-200 rounded-none focus:outline-none focus:border-neutral-900"
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
                class="w-full px-3 py-2 border border-neutral-200 rounded-none focus:outline-none focus:border-neutral-900"
              />
            </div>
            <div>
              <label class="block font-semibold text-neutral-700 mb-1">Confirm Passphrase</label>
              <input
                v-model="confirmPassword"
                type="password"
                required
                class="w-full px-3 py-2 border border-neutral-200 rounded-none focus:outline-none focus:border-neutral-900"
              />
            </div>
            <p v-if="passwordError" class="text-rose-600 font-medium">{{ passwordError }}</p>
          </div>

          <div class="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              @click="showPasswordModal = false"
              class="px-4 py-2 bg-white border border-neutral-200 rounded-none text-xs font-semibold text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="px-4 py-2 bg-neutral-900 text-white rounded-none text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            >
              Update Password
            </button>
          </div>
        </form>
      </div>
    </Teleport>
  </div>
</template>
