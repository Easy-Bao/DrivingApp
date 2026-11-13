<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const props = withDefaults(
  defineProps<{
    modelValue: string
    placeholder?: string
    ariaLabel?: string
  }>(),
  {
    placeholder: 'Search...',
    ariaLabel: 'Search records',
  },
)

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
}>()

const inputRef = ref<HTMLInputElement | null>(null)

function updateValue(event: Event) {
  emit('update:modelValue', (event.target as HTMLInputElement).value)
}

function clearSearch() {
  emit('update:modelValue', '')
  inputRef.value?.focus()
}

function handleEscape() {
  if (props.modelValue) {
    emit('update:modelValue', '')
  }
}
</script>

<template>
  <div class="relative w-full">
    <Icon
      icon="lucide:search"
      class="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400 text-xs"
      aria-hidden="true"
    />
    <input
      ref="inputRef"
      type="text"
      :value="modelValue"
      :placeholder="placeholder"
      :aria-label="ariaLabel"
      class="w-full h-8 pl-8 pr-8 border border-neutral-200 bg-white text-xs text-neutral-900 placeholder:text-neutral-400 focus:outline-none focus:border-neutral-900 transition-colors"
      @input="updateValue"
      @keydown.escape="handleEscape"
    />
    <button
      v-if="modelValue"
      type="button"
      aria-label="Clear search"
      class="absolute right-1 top-1/2 -translate-y-1/2 p-1 text-neutral-400 hover:text-neutral-900 transition-colors cursor-pointer"
      @click="clearSearch"
    >
      <Icon icon="lucide:x" class="text-xs" aria-hidden="true" />
    </button>
  </div>
</template>
