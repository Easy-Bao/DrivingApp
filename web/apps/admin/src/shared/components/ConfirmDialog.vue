<script setup lang="ts">
import { computed, onBeforeUnmount, watch } from 'vue'
import { Icon } from '@iconify/vue'

const props = withDefaults(
  defineProps<{
    open: boolean
    title: string
    description: string
    confirmLabel?: string
    cancelLabel?: string
    tone?: 'neutral' | 'emerald' | 'rose' | 'amber'
    requireReason?: boolean
    reasonLabel?: string
    reasonPlaceholder?: string
    reason?: string
  }>(),
  {
    confirmLabel: 'Confirm',
    cancelLabel: 'Cancel',
    tone: 'neutral',
    requireReason: false,
    reasonLabel: 'Reason / Audit Note',
    reasonPlaceholder: 'Enter brief operational reason...',
    reason: '',
  },
)

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
  (e: 'update:reason', value: string): void
  (e: 'confirm'): void
  (e: 'cancel'): void
}>()

const headingId = 'confirm-dialog-title'

const canConfirm = computed(() => {
  if (!props.requireReason) return true
  return props.reason.trim().length > 0
})

const confirmClasses = computed(() => {
  switch (props.tone) {
    case 'emerald':
      return 'bg-emerald-600 hover:bg-emerald-700 text-white'
    case 'rose':
      return 'bg-rose-600 hover:bg-rose-700 text-white'
    case 'amber':
      return 'bg-amber-600 hover:bg-amber-700 text-white'
    default:
      return 'bg-neutral-900 hover:bg-neutral-800 text-white'
  }
})

function closeDialog() {
  emit('update:open', false)
  emit('cancel')
}

function handleConfirm() {
  if (!canConfirm.value) return
  emit('confirm')
  emit('update:open', false)
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
  <div
    v-if="open"
    role="dialog"
    aria-modal="true"
    :aria-labelledby="headingId"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
    @click.self="closeDialog"
  >
    <div class="bg-white border border-neutral-200 max-w-md w-full p-6 space-y-4 shadow-xl">
      <div class="flex items-start justify-between gap-3">
        <div class="space-y-1">
          <h3 :id="headingId" class="text-base font-bold text-neutral-900">
            {{ title }}
          </h3>
          <p class="text-xs text-neutral-600 leading-relaxed">
            {{ description }}
          </p>
        </div>
        <button
          type="button"
          aria-label="Close confirmation dialog"
          class="p-1 text-neutral-400 hover:text-neutral-700 transition-colors cursor-pointer"
          @click="closeDialog"
        >
          <Icon icon="lucide:x" class="text-sm" aria-hidden="true" />
        </button>
      </div>

      <div v-if="requireReason" class="space-y-1.5">
        <label for="confirm-dialog-reason" class="block text-xs font-semibold text-neutral-700">
          {{ reasonLabel }}
        </label>
        <textarea
          id="confirm-dialog-reason"
          :value="reason"
          rows="3"
          :placeholder="reasonPlaceholder"
          class="w-full px-3 py-2 text-xs bg-neutral-50 border border-neutral-200 focus:outline-none focus:border-neutral-900"
          @input="emit('update:reason', ($event.target as HTMLTextAreaElement).value)"
        />
      </div>

      <div class="flex items-center justify-end gap-2 pt-2 border-t border-neutral-100">
        <button
          type="button"
          class="px-4 py-2 text-xs font-semibold text-neutral-700 bg-neutral-100 hover:bg-neutral-200 transition-colors cursor-pointer"
          @click="closeDialog"
        >
          {{ cancelLabel }}
        </button>
        <button
          type="button"
          :disabled="!canConfirm"
          class="px-4 py-2 text-xs font-semibold transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
          :class="confirmClasses"
          @click="handleConfirm"
        >
          {{ confirmLabel }}
        </button>
      </div>
    </div>
  </div>
</template>
