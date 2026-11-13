<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { ROLE_PROFILES, lockAuthSession, useAuthSession } from '@/core/auth/auth-session'

definePage({
  meta: { hideChrome: false },
})

const route = useRoute()
const router = useRouter()
const session = useAuthSession()

const currentRoleLabel = computed(() => {
  const role = session.value.role
  return role ? ROLE_PROFILES[role].label : 'Unauthenticated'
})

const requestedPath = computed(() => {
  return typeof route.query.from === 'string' ? route.query.from : 'Protected Section'
})

const requiredRoles = computed(() => {
  return typeof route.query.required === 'string' ? route.query.required : 'root_operator'
})

function switchOperatorRole() {
  const redirectTarget =
    typeof route.query.from === 'string' ? route.query.from : '/dashboard/overview'
  lockAuthSession()
  void router.push({ name: '/auth/login', query: { redirect: redirectTarget } })
}
</script>

<template>
  <div class="min-h-[60vh] w-full flex items-center justify-center p-6">
    <div class="w-full max-w-md bg-white border border-neutral-300 p-8 text-center space-y-5">
      <div
        class="w-12 h-12 mx-auto bg-neutral-100 border border-neutral-300 flex items-center justify-center text-neutral-900"
      >
        <Icon icon="lucide:shield-alert" class="text-2xl" aria-hidden="true" />
      </div>

      <div class="space-y-1.5">
        <p class="text-[11px] font-mono font-bold uppercase tracking-wider text-neutral-500">
          403 · Restricted
        </p>
        <h1 class="text-xl font-bold text-neutral-900 tracking-tight">Restricted Access</h1>
        <p class="text-xs text-neutral-600 leading-relaxed">
          <span class="font-semibold text-neutral-900">{{ currentRoleLabel }}</span>
          cannot open
          <span class="font-mono text-neutral-900">{{ requestedPath }}</span
          >.
        </p>
        <p class="text-[11px] font-mono text-neutral-400">Allowed: {{ requiredRoles }}</p>
      </div>

      <div class="flex flex-col sm:flex-row items-center justify-center gap-2.5 pt-2">
        <RouterLink
          to="/dashboard/overview"
          class="w-full sm:w-auto px-4 py-2 bg-white border border-neutral-300 hover:bg-neutral-50 text-xs font-semibold text-neutral-800 transition-colors"
        >
          Overview
        </RouterLink>
        <button
          type="button"
          class="w-full sm:w-auto px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
          @click="switchOperatorRole"
        >
          Switch Role
        </button>
      </div>
    </div>
  </div>
</template>
