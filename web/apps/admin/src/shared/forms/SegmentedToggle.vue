<script setup lang="ts" generic="T extends string">
export interface SegmentedOption<V extends string> {
  label: string
  value: V
}

defineProps<{
  modelValue: T
  options: readonly SegmentedOption<T>[]
  ariaLabel?: string
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: T): void
}>()
</script>

<template>
  <div role="group" :aria-label="ariaLabel" class="inline-flex border border-neutral-200 bg-white">
    <button
      v-for="option in options"
      :key="option.value"
      type="button"
      :aria-pressed="modelValue === option.value"
      class="px-2.5 py-1 text-[11px] font-semibold transition-colors cursor-pointer whitespace-nowrap"
      :class="
        modelValue === option.value
          ? 'bg-neutral-900 text-white'
          : 'text-neutral-600 hover:bg-neutral-50 hover:text-neutral-900'
      "
      @click="emit('update:modelValue', option.value)"
    >
      {{ option.label }}
    </button>
  </div>
</template>
