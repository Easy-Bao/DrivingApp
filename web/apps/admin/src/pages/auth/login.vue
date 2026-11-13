<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import { ROLE_PROFILES, loginOperator, type OperatorRole } from '@/core/auth/auth-session'
import { sanitizeRedirectPath } from '@/app/router/guards'

definePage({
  meta: { public: true, hideChrome: true },
})

const route = useRoute()
const router = useRouter()

const selectedRole = ref<OperatorRole>('root_operator')
const securityPin = ref('7016')
const showPin = ref(false)
const errorMessage = ref('')

const roleOptions = [
  { label: 'Root Operator', value: 'root_operator' as OperatorRole },
  { label: 'Fleet Ops', value: 'fleet_ops' as OperatorRole },
  { label: 'Finance Ops', value: 'finance_ops' as OperatorRole },
  { label: 'Support Lead', value: 'support_lead' as OperatorRole },
]

const activeProfile = computed(() => ROLE_PROFILES[selectedRole.value])
const redirectTarget = computed(() => sanitizeRedirectPath(route.query.redirect))

function submitSignIn() {
  errorMessage.value = ''
  const result = loginOperator(selectedRole.value, securityPin.value)
  if (!result.ok) {
    errorMessage.value = result.error
    return
  }
  void router.replace(redirectTarget.value)
}
</script>

<template>
  <div class="min-h-dvh min-h-screen bg-neutral-100 flex items-center justify-center p-4 sm:p-6">
    <div class="w-full max-w-md bg-white border border-neutral-300 shadow-sm">
      <div
        class="px-5 sm:px-6 py-4 sm:py-5 border-b border-neutral-200 flex items-center justify-between gap-3"
      >
        <div class="flex items-center gap-3">
          <div
            class="w-9 h-9 bg-neutral-900 text-white flex items-center justify-center font-bold text-sm"
          >
            ER
          </div>
          <div>
            <h1 class="text-base font-bold text-neutral-900 tracking-tight">EasyRide Operations</h1>
            <p class="text-[11px] text-neutral-500">Pagadian City · 7016</p>
          </div>
        </div>
        <Icon icon="lucide:shield-check" class="text-xl text-neutral-800" aria-hidden="true" />
      </div>

      <form class="p-5 sm:p-6 space-y-4 text-xs" @submit.prevent="submitSignIn">
        <div
          v-if="route.query.redirect"
          class="p-3 bg-neutral-50 border border-neutral-300 text-neutral-800 text-xs"
        >
          Locked. Sign in for
          <span class="font-mono font-semibold">{{ redirectTarget }}</span
          >.
        </div>

        <div class="space-y-1.5">
          <label class="block font-semibold text-neutral-800">Role</label>
          <BaseSelect
            v-model="selectedRole"
            aria-label="Select operator role"
            :full-width="true"
            :options="roleOptions"
          />
          <p class="text-[11px] text-neutral-500">
            {{ activeProfile.operatorName }} ·
            <span class="font-mono">{{ activeProfile.operatorEmail }}</span>
          </p>
        </div>

        <div class="p-3 bg-neutral-50 border border-neutral-200 space-y-1">
          <div class="text-[11px] font-semibold uppercase tracking-wide text-neutral-500">
            Access Scope
          </div>
          <p class="text-xs text-neutral-700">{{ activeProfile.scopeSummary }}</p>
        </div>

        <div class="space-y-1.5">
          <label for="operator-pin" class="block font-semibold text-neutral-800">
            Security PIN
          </label>
          <div class="relative">
            <input
              id="operator-pin"
              v-model="securityPin"
              :type="showPin ? 'text' : 'password'"
              autocomplete="current-password"
              placeholder="4+ digit PIN"
              class="w-full px-3 pr-9 py-2 bg-white border border-neutral-300 text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
            />
            <button
              type="button"
              :aria-label="showPin ? 'Hide security PIN' : 'Show security PIN'"
              class="absolute right-2 top-1/2 -translate-y-1/2 p-1 text-neutral-400 hover:text-neutral-900 transition-colors cursor-pointer"
              @click="showPin = !showPin"
            >
              <Icon
                :icon="showPin ? 'lucide:eye-off' : 'lucide:eye'"
                class="text-sm"
                aria-hidden="true"
              />
            </button>
          </div>
        </div>

        <div
          v-if="errorMessage"
          role="alert"
          class="p-2.5 bg-neutral-50 border border-neutral-300 border-l-2 border-l-rose-600 text-neutral-900"
        >
          {{ errorMessage }}
        </div>

        <button
          type="submit"
          class="w-full py-2.5 px-4 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
        >
          Unlock Session
        </button>
      </form>
    </div>
  </div>
</template>
