<script setup lang="ts">
import { Icon } from '@iconify/vue'
</script>

<template>
  <div class="space-y-6 max-w-4xl">
    <div>
      <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
        Super Administrator Account
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Manage executive credentials, session authorization, and hardware security keys.
      </p>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl p-6 shadow-xs space-y-6">
      <div class="flex items-center space-x-4 border-b border-neutral-100 pb-6">
        <div
          class="w-16 h-16 rounded-2xl bg-neutral-900 text-white flex items-center justify-center font-bold text-xl shadow-md"
        >
          AD
        </div>
        <div>
          <h2 class="text-base font-bold text-neutral-900">Operations Control Lead</h2>
          <p class="text-xs text-neutral-500">ops@easyride.io · Employee ID: #EMP-001</p>
          <span
            class="inline-block mt-2 px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold"
          >
            Root Super Admin (All Permissions)
          </span>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
        <div>
          <label class="block font-semibold text-neutral-700 mb-1">Full Name</label>
          <input
            type="text"
            value="System Administrator"
            class="w-full px-3 py-2 bg-neutral-50 border border-neutral-200 rounded-lg text-xs"
          />
        </div>
        <div>
          <label class="block font-semibold text-neutral-700 mb-1">Email Address</label>
          <input
            type="email"
            value="admin@easyride.io"
            class="w-full px-3 py-2 bg-neutral-50 border border-neutral-200 rounded-lg text-xs"
          />
        </div>
      </div>

      <div class="pt-4 border-t border-neutral-100 flex items-center justify-between">
        <div class="flex items-center space-x-3">
          <Icon icon="lucide:shield-check" class="text-2xl text-emerald-600" />
          <div>
            <span class="text-xs font-semibold text-neutral-900"
              >Two-Factor Authentication (2FA)</span
            >
            <p class="text-[11px] text-neutral-500">Hardware token or authenticator app active.</p>
          </div>
        </div>
        <span class="px-2.5 py-1 bg-emerald-100 text-emerald-800 text-[10px] font-bold rounded-full"
          >Enforced</span
        >
      </div>
    </div>
  </div>
</template>
