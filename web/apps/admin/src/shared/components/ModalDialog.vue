<script setup lang="ts">
import { computed, onBeforeUnmount, useId, watch } from 'vue'
import { Icon } from '@iconify/vue'

export type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl'

const props = withDefaults(
  defineProps<{
    open: boolean
    title: string
    subtitle?: string
    size?: ModalSize
    closeOnBackdrop?: boolean
    closeLabel?: string
  }>(),
  {
    subtitle: undefined,
    size: 'lg',
    closeOnBackdrop: true,
    closeLabel: 'Close dialog',
  },
)

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
  (e: 'close'): void
}>()

const headingId = useId()

const sizeClass = computed(() => {
  switch (props.size) {
    case 'sm':
      return 'max-w-sm'
    case 'md':
      return 'max-w-md'
    case 'xl':
      return 'max-w-xl'
    case '2xl':
      return 'max-w-2xl'
    default:
      return 'max-w-lg'
  }
})

function closeDialog() {
  emit('update:open', false)
  emit('close')
}

function handleBackdropClick() {
  if (props.closeOnBackdrop) {
    closeDialog()
  }
}

function handleKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape' && props.open) {
    closeDialog()
  }
}

watch(
  () => props.open,
  (isOpen) => {
    if (typeof window === 'undefined') return
    if (isOpen) {
      window.addEventListener('keydown', handleKeydown)
    } else {
      window.removeEventListener('keydown', handleKeydown)
    }
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  if (typeof window !== 'undefined') {
    window.removeEventListener('keydown', handleKeydown)
  }
})
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      role="dialog"
      aria-modal="true"
      :aria-labelledby="headingId"
      class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-950/60 p-3 sm:p-4"
      @click.self="handleBackdropClick"
    >
      <div
        :class="sizeClass"
        class="w-full bg-white border border-neutral-200 shadow-xl flex flex-col max-h-[90dvh]"
      >
        <div class="px-5 py-4 border-b border-neutral-200 shrink-0">
          <div class="flex items-start justify-between gap-3">
            <div class="flex-1 min-w-0">
              <h3 :id="headingId" class="text-sm sm:text-base font-bold text-neutral-900">
                {{ title }}
              </h3>
              <p v-if="subtitle && !$slots.subtitle" class="text-xs text-neutral-500 mt-0.5">
                {{ subtitle }}
              </p>
            </div>
            <div class="flex items-center gap-2 shrink-0">
              <slot name="header-meta" />
              <button
                type="button"
                :aria-label="closeLabel"
                class="p-1 text-neutral-400 hover:text-neutral-900 hover:bg-neutral-100 transition-colors cursor-pointer"
                @click="closeDialog"
              >
                <Icon icon="lucide:x" class="text-base" aria-hidden="true" />
              </button>
            </div>
          </div>
          <div v-if="$slots.subtitle" class="mt-1.5">
            <slot name="subtitle" />
          </div>
        </div>

        <div class="p-5 overflow-y-auto flex-1 min-h-0">
          <slot />
        </div>

        <div
          v-if="$slots.footer"
          class="px-5 py-3.5 border-t border-neutral-200 bg-neutral-50/80 flex flex-wrap items-center justify-end gap-2 shrink-0"
        >
          <slot name="footer" />
        </div>
      </div>
    </div>
  </Teleport>
</template>
