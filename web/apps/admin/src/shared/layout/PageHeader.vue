<script setup lang="ts">
defineProps<{
  title: string
  description?: string
}>()
</script>

<template>
  <header class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
    <div class="min-w-0">
      <h1 class="text-xl sm:text-2xl font-bold tracking-tight text-neutral-900">
        {{ title }}
      </h1>
      <p v-if="description" class="text-xs sm:text-sm text-neutral-500 mt-1">
        {{ description }}
      </p>
    </div>
    <div v-if="$slots.actions" class="flex flex-wrap items-center gap-2 shrink-0">
      <slot name="actions" />
    </div>
  </header>
</template>
