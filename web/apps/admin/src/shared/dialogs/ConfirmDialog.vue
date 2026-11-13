<script setup lang="ts">
import { computed, useId } from 'vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'

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

const reasonInputId = useId()

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

function handleOpenUpdate(nextOpen: boolean) {
  if (!nextOpen) {
    closeDialog()
  } else {
    emit('update:open', true)
  }
}

function handleConfirm() {
  if (!canConfirm.value) return
  emit('confirm')
  emit('update:open', false)
}
</script>

<template>
  <ModalDialog
    :open="open"
    :title="title"
    size="md"
    close-label="Close confirmation dialog"
    @update:open="handleOpenUpdate"
  >
    <div class="space-y-4">
      <p class="text-xs text-neutral-600 leading-relaxed">
        {{ description }}
      </p>

      <div v-if="requireReason" class="space-y-1.5">
        <label :for="reasonInputId" class="block text-xs font-semibold text-neutral-700">
          {{ reasonLabel }}
        </label>
        <textarea
          :id="reasonInputId"
          :value="reason"
          rows="3"
          :placeholder="reasonPlaceholder"
          class="w-full px-3 py-2 text-xs bg-neutral-50 border border-neutral-200 focus:outline-none focus:border-neutral-900"
          @input="emit('update:reason', ($event.target as HTMLTextAreaElement).value)"
        />
      </div>
    </div>

    <template #footer>
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
    </template>
  </ModalDialog>
</template>
