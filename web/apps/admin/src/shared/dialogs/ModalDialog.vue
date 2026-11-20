<script lang="ts">
let openModalCount = 0
let savedBodyOverflow: string | null = null

function lockBodyScroll() {
  if (typeof document === 'undefined') return
  if (openModalCount === 0) {
    savedBodyOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
  }
  openModalCount += 1
}

function unlockBodyScroll() {
  if (typeof document === 'undefined' || openModalCount === 0) return
  openModalCount -= 1
  if (openModalCount === 0) {
    document.body.style.overflow = savedBodyOverflow ?? ''
    savedBodyOverflow = null
  }
}
</script>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, useId, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { useEscapeKey } from '@/shared/composables/use-escape-key'

export type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl'

const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(', ')

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
const dialogPanelRef = ref<HTMLDivElement | null>(null)
let isScrollLocked = false
let previousFocusedElement: HTMLElement | null = null

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

function trapFocus(event: KeyboardEvent) {
  const panel = dialogPanelRef.value
  if (!panel) return

  const focusableElements = Array.from(panel.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR))
  if (focusableElements.length === 0) {
    event.preventDefault()
    panel.focus()
    return
  }

  const first = focusableElements[0]!
  const last = focusableElements[focusableElements.length - 1]!
  const active = document.activeElement

  if (event.shiftKey) {
    if (active === first || active === panel || !panel.contains(active)) {
      event.preventDefault()
      last.focus()
    }
  } else if (active === last) {
    event.preventDefault()
    first.focus()
  }
}

function releaseDialogFocusAndScroll() {
  if (isScrollLocked) {
    unlockBodyScroll()
    isScrollLocked = false
  }
  if (previousFocusedElement?.isConnected) {
    previousFocusedElement.focus()
  }
  previousFocusedElement = null
}

watch(
  () => props.open,
  async (isOpen) => {
    if (isOpen) {
      if (typeof document !== 'undefined' && document.activeElement instanceof HTMLElement) {
        previousFocusedElement = document.activeElement
      }
      if (!isScrollLocked) {
        lockBodyScroll()
        isScrollLocked = true
      }
      await nextTick()
      dialogPanelRef.value?.focus()
    } else {
      releaseDialogFocusAndScroll()
    }
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  releaseDialogFocusAndScroll()
})

useEscapeKey(() => props.open, closeDialog)
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
        ref="dialogPanelRef"
        tabindex="-1"
        :class="sizeClass"
        class="w-full bg-white border border-neutral-200 shadow-xl flex flex-col max-h-[90dvh] focus:outline-none"
        @keydown.tab="trapFocus"
      >
        <div class="px-5 py-4 border-b border-neutral-200 shrink-0">
          <div class="flex items-start justify-between gap-3">
            <div class="flex-1 min-w-0">
              <h2 :id="headingId" class="text-sm sm:text-base font-bold text-neutral-900">
                {{ title }}
              </h2>
              <p v-if="subtitle && !$slots.subtitle" class="text-xs text-neutral-500 mt-0.5">
                {{ subtitle }}
              </p>
            </div>
            <div class="flex items-center gap-2 shrink-0">
              <slot name="header-meta" />
              <button
                type="button"
                :aria-label="closeLabel"
                class="p-1.5 text-neutral-500 hover:text-neutral-900 hover:bg-neutral-100 transition-colors cursor-pointer"
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
