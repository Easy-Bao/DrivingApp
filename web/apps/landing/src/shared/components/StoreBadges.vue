<script setup lang="ts">
import { RouterLink } from 'vue-router'
import UiIcon from '@/shared/components/UiIcon.vue'

interface StoreBadgesProps {
  audience?: 'passenger' | 'driver'
  surface?: 'light' | 'dark'
}

withDefaults(defineProps<StoreBadgesProps>(), {
  audience: 'passenger',
  surface: 'light',
})
</script>

<template>
  <div class="flex flex-wrap items-center gap-3">
    <RouterLink
      :to="{ path: '/download', query: { role: audience }, hash: '#android' }"
      class="inline-flex min-h-12 items-center gap-3 rounded-xl px-4 py-2.5 text-left transition-colors"
      :class="
        surface === 'dark'
          ? 'bg-white text-[#090d16] hover:bg-emerald-50 shadow-sm'
          : 'bg-[#090d16] text-white hover:bg-slate-800 shadow-sm'
      "
    >
      <UiIcon name="play-store" size-class="h-5 w-5 text-emerald-500" />
      <span>
        <span class="block text-[10px] font-medium uppercase tracking-wider opacity-75">
          {{ audience === 'driver' ? 'Driver Android' : 'Get it on' }}
        </span>
        <span class="block text-sm font-bold leading-tight">Google Play</span>
      </span>
    </RouterLink>

    <RouterLink
      v-if="audience === 'passenger'"
      :to="{ path: '/download', query: { role: audience }, hash: '#ios' }"
      class="inline-flex min-h-12 items-center gap-3 rounded-xl px-4 py-2.5 text-left transition-colors"
      :class="
        surface === 'dark'
          ? 'bg-white/10 text-white ring-1 ring-white/20 hover:bg-white/15'
          : 'bg-white text-[#090d16] ring-1 ring-slate-200 hover:bg-slate-50 shadow-xs'
      "
    >
      <UiIcon name="apple" size-class="h-5 w-5" />
      <span>
        <span class="block text-[10px] font-medium uppercase tracking-wider opacity-75">
          Download on the
        </span>
        <span class="block text-sm font-bold leading-tight">App Store</span>
      </span>
    </RouterLink>

    <RouterLink
      :to="{ path: '/download', query: { role: audience }, hash: '#apk' }"
      class="inline-flex min-h-12 items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition-colors"
      :class="
        surface === 'dark'
          ? 'text-emerald-200 ring-1 ring-emerald-400/35 hover:bg-emerald-500/15'
          : 'text-emerald-800 bg-emerald-50 ring-1 ring-emerald-200 hover:bg-emerald-100'
      "
    >
      <UiIcon name="download" size-class="h-4 w-4" />
      <span>{{ audience === 'driver' ? 'Driver APK Guide' : 'Direct APK' }}</span>
    </RouterLink>
  </div>
</template>
