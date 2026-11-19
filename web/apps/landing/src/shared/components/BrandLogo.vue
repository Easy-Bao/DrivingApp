<script setup lang="ts">
interface BrandLogoProps {
  surface?: 'light' | 'dark'
  size?: 'sm' | 'md'
}

withDefaults(defineProps<BrandLogoProps>(), {
  surface: 'light',
  size: 'md',
})
</script>

<template>
  <span
    class="inline-flex items-center font-bold tracking-[-0.03em] select-none"
    :class="[
      size === 'sm' ? 'text-[15px]' : 'text-[17px]',
      surface === 'dark' ? 'text-white' : 'text-neutral-950',
    ]"
  >
    EasyRide
  </span>
</template>
