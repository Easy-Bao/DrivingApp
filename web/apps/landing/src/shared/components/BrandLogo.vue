<script setup lang="ts">
interface BrandLogoProps {
  surface?: 'light' | 'dark'
}

withDefaults(defineProps<BrandLogoProps>(), {
  surface: 'light',
})
</script>

<template>
  <span class="inline-flex items-center gap-2.5 select-none">
    <span
      class="inline-flex h-8 w-8 shrink-0 items-center justify-center text-xs font-bold tracking-tight"
      :class="surface === 'dark' ? 'bg-white text-neutral-900' : 'bg-neutral-900 text-white'"
    >
      ER
    </span>
    <span
      class="text-base font-bold tracking-tight"
      :class="surface === 'dark' ? 'text-white' : 'text-neutral-900'"
    >
      EasyRide
    </span>
  </span>
</template>
