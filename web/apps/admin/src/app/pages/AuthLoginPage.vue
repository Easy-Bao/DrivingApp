<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import { ROLE_PROFILES, loginOperator, type AdminRole } from '@/core/auth/auth-session'
import { sanitizeRedirectPath } from '@/app/router/guards'

const route = useRoute()
const router = useRouter()

const selectedRole = ref<AdminRole>('super_admin')
const securityPin = ref('7016')
const errorMessage = ref('')

const roleOptions = [
  { label: 'Super Administrator (Full Access)', value: 'super_admin' as AdminRole },
  { label: 'Dispatch & Safety Supervisor', value: 'fleet_ops' as AdminRole },
  { label: 'Treasury & Settlements Officer', value: 'finance_admin' as AdminRole },
  { label: 'Trust & Safety Lead', value: 'support_lead' as AdminRole },
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
  <div class="min-h-screen bg-neutral-100 flex items-center justify-center p-4 sm:p-6">
    <div class="w-full max-w-md bg-white border border-neutral-300 shadow-sm">
      <div class="px-6 py-5 border-b border-neutral-200 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div
            class="w-9 h-9 bg-neutral-900 text-white flex items-center justify-center font-bold text-sm"
          >
            ER
          </div>
          <div>
            <h1 class="text-base font-bold text-neutral-900 tracking-tight">
              EasyRide Operations Console
            </h1>
            <p class="text-[11px] text-neutral-500">
              Pagadian City (7016) · Protected Admin Access
            </p>
          </div>
        </div>
        <Icon icon="lucide:shield-check" class="text-xl text-neutral-800" aria-hidden="true" />
      </div>

      <form class="p-6 space-y-4 text-xs" @submit.prevent="submitSignIn">
        <div
          v-if="route.query.redirect"
          class="p-3 bg-amber-50 border border-amber-200 text-amber-900 text-xs"
        >
          Session is locked. Authenticate to access
          <span class="font-mono font-semibold">{{ redirectTarget }}</span>
          .
        </div>

        <div class="space-y-1.5">
          <label class="block font-semibold text-neutral-800">Operator Role Profile</label>
          <BaseSelect
            v-model="selectedRole"
            aria-label="Select operator role profile"
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
            Authorized Route Scope
          </div>
          <p class="text-xs text-neutral-700">{{ activeProfile.scopeSummary }}</p>
        </div>

        <div class="space-y-1.5">
          <label for="operator-pin" class="block font-semibold text-neutral-800">
            Operator Security PIN
          </label>
          <input
            id="operator-pin"
            v-model="securityPin"
            type="password"
            autocomplete="current-password"
            placeholder="Enter 4+ digit PIN"
            class="w-full px-3 py-2 bg-white border border-neutral-300 text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
          />
        </div>

        <div v-if="errorMessage" class="p-2.5 bg-rose-50 border border-rose-200 text-rose-800">
          {{ errorMessage }}
        </div>

        <button
          type="submit"
          class="w-full py-2.5 px-4 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
        >
          Unlock Admin Console
        </button>
      </form>
    </div>
  </div>
</template>
