<script setup lang="ts">
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'

const router = useRouter()

function goBack() {
  router.back()
}
</script>

<template>
  <div class="min-h-[60vh] flex items-center justify-center p-6">
    <div class="w-full max-w-md bg-white border border-neutral-200 p-8 text-center space-y-5">
      <div
        class="w-12 h-12 mx-auto bg-neutral-100 border border-neutral-200 flex items-center justify-center text-neutral-700"
      >
        <Icon icon="lucide:compass" class="text-2xl" aria-hidden="true" />
      </div>

      <div class="space-y-1.5">
        <p class="text-[11px] font-mono font-bold uppercase tracking-wider text-neutral-400">
          Error 404
        </p>
        <h1 class="text-xl font-bold text-neutral-900 tracking-tight">
          Operations Section Not Found
        </h1>
        <p class="text-xs text-neutral-500 leading-relaxed">
          The requested admin route does not exist or has been retired during platform alignment.
        </p>
      </div>

      <div class="flex flex-col sm:flex-row items-center justify-center gap-2.5 pt-2">
        <button
          type="button"
          class="w-full sm:w-auto px-4 py-2 bg-white border border-neutral-200 hover:bg-neutral-50 text-xs font-semibold text-neutral-700 transition-colors cursor-pointer"
          @click="goBack"
        >
          Go Back
        </button>
        <RouterLink
          to="/dashboard/overview"
          class="w-full sm:w-auto px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors"
        >
          Return to Overview
        </RouterLink>
      </div>
    </div>
  </div>
</template>
