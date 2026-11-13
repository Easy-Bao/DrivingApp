<script setup lang="ts" generic="T extends string = string">
import { computed, nextTick, onBeforeUnmount, ref } from 'vue'
import { Icon } from '@iconify/vue'

type RawOption<V extends string> = V | { label: string; value: V; disabled?: boolean }

interface NormalizedOption<V extends string> {
  label: string
  value: V
  disabled: boolean
}

const props = withDefaults(
  defineProps<{
    modelValue: T
    options: readonly RawOption<T>[]
    ariaLabel?: string
    placeholder?: string
    fullWidth?: boolean
    disabled?: boolean
  }>(),
  {
    ariaLabel: 'Select option',
    placeholder: 'Select...',
    fullWidth: false,
    disabled: false,
  },
)

const emit = defineEmits<{
  (e: 'update:modelValue', value: T): void
}>()

const normalizedOptions = computed<NormalizedOption<T>[]>(() =>
  props.options.map((opt) =>
    typeof opt === 'string'
      ? { label: opt, value: opt, disabled: false }
      : { label: opt.label, value: opt.value, disabled: Boolean(opt.disabled) },
  ),
)

const selectedLabel = computed(() => {
  const match = normalizedOptions.value.find((opt) => opt.value === props.modelValue)
  return match ? match.label : props.placeholder
})

const triggerRef = ref<HTMLButtonElement | null>(null)
const menuRef = ref<HTMLDivElement | null>(null)
const isOpen = ref(false)
const activeIndex = ref(-1)
const menuStyle = ref<Record<string, string>>({
  top: '0px',
  left: '0px',
  minWidth: '180px',
})

const updatePosition = () => {
  const trigger = triggerRef.value
  if (!trigger) return
  const rect = trigger.getBoundingClientRect()
  const viewportHeight = typeof window !== 'undefined' ? window.innerHeight : 800
  const viewportWidth = typeof window !== 'undefined' ? window.innerWidth : 1280
  const estimatedHeight = Math.min(normalizedOptions.value.length * 32 + 4, 260)
  const spaceBelow = viewportHeight - rect.bottom
  const openUpward = spaceBelow < estimatedHeight && rect.top > estimatedHeight

  const width = Math.max(rect.width, 168)
  const maxLeft = Math.max(8, viewportWidth - width - 8)
  const left = Math.min(Math.max(8, rect.left), maxLeft)

  if (openUpward) {
    menuStyle.value = {
      bottom: `${Math.max(8, viewportHeight - rect.top)}px`,
      left: `${left}px`,
      minWidth: `${width}px`,
    }
  } else {
    menuStyle.value = {
      top: `${rect.bottom}px`,
      left: `${left}px`,
      minWidth: `${width}px`,
    }
  }
}

const attachListeners = () => {
  if (typeof document === 'undefined') return
  document.addEventListener('pointerdown', onOutsidePointerDown, true)
  document.addEventListener('keydown', onDocumentKeydown)
  window.addEventListener('resize', updatePosition)
  window.addEventListener('scroll', updatePosition, true)
}

const detachListeners = () => {
  if (typeof document === 'undefined') return
  document.removeEventListener('pointerdown', onOutsidePointerDown, true)
  document.removeEventListener('keydown', onDocumentKeydown)
  window.removeEventListener('resize', updatePosition)
  window.removeEventListener('scroll', updatePosition, true)
}

const openMenu = async () => {
  if (props.disabled) return
  isOpen.value = true
  const currentIdx = normalizedOptions.value.findIndex((o) => o.value === props.modelValue)
  activeIndex.value = currentIdx >= 0 ? currentIdx : 0
  await nextTick()
  updatePosition()
  attachListeners()
}

const closeMenu = (restoreFocus = false) => {
  if (!isOpen.value) return
  isOpen.value = false
  activeIndex.value = -1
  detachListeners()
  if (restoreFocus) {
    triggerRef.value?.focus()
  }
}

const toggleMenu = () => {
  if (props.disabled) return
  if (isOpen.value) {
    closeMenu(true)
  } else {
    void openMenu()
  }
}

const selectOption = (opt: NormalizedOption<T>) => {
  if (opt.disabled) return
  emit('update:modelValue', opt.value)
  closeMenu(true)
}

const onOutsidePointerDown = (event: PointerEvent) => {
  const target = event.target as Node | null
  if (!target) return
  if (triggerRef.value?.contains(target) || menuRef.value?.contains(target)) {
    return
  }
  closeMenu(false)
}

const moveActive = (delta: number) => {
  const items = normalizedOptions.value
  if (items.length === 0) return
  let idx = activeIndex.value
  for (let step = 0; step < items.length; step++) {
    idx = (idx + delta + items.length) % items.length
    if (!items[idx]?.disabled) {
      activeIndex.value = idx
      return
    }
  }
}

const onDocumentKeydown = (event: KeyboardEvent) => {
  if (!isOpen.value) return
  if (event.key === 'Escape') {
    event.preventDefault()
    closeMenu(true)
  } else if (event.key === 'ArrowDown') {
    event.preventDefault()
    moveActive(1)
  } else if (event.key === 'ArrowUp') {
    event.preventDefault()
    moveActive(-1)
  } else if (event.key === 'Enter' || event.key === ' ') {
    const active = normalizedOptions.value[activeIndex.value]
    if (active && !active.disabled) {
      event.preventDefault()
      selectOption(active)
    }
  }
}

const onTriggerKeydown = (event: KeyboardEvent) => {
  if (props.disabled) return
  if (!isOpen.value && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
    event.preventDefault()
    void openMenu()
  }
}

onBeforeUnmount(() => {
  detachListeners()
})
</script>

<template>
  <button
    ref="triggerRef"
    type="button"
    role="combobox"
    :disabled="disabled"
    :aria-expanded="isOpen"
    aria-haspopup="listbox"
    :aria-label="ariaLabel"
    :class="[
      fullWidth ? 'w-full' : 'w-full sm:w-auto',
      disabled
        ? 'bg-neutral-100 text-neutral-500 cursor-not-allowed'
        : 'bg-white text-neutral-900 hover:border-neutral-400 cursor-pointer',
    ]"
    class="inline-flex items-center justify-between gap-3 px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium focus:outline-none focus:border-neutral-900 transition-colors"
    @click="toggleMenu"
    @keydown="onTriggerKeydown"
  >
    <span class="truncate text-left">{{ selectedLabel }}</span>
    <Icon
      icon="lucide:chevron-down"
      class="h-3.5 w-3.5 shrink-0 text-neutral-500 transition-transform duration-150"
      :class="isOpen ? 'rotate-180 text-neutral-900' : ''"
      aria-hidden="true"
    />
  </button>

  <Teleport to="body">
    <div
      v-if="isOpen"
      ref="menuRef"
      role="listbox"
      :aria-label="ariaLabel"
      :style="menuStyle"
      class="fixed z-[100] bg-white border border-neutral-300 rounded-none shadow-md py-0 max-h-64 overflow-y-auto focus:outline-none"
    >
      <button
        v-for="(option, index) in normalizedOptions"
        :key="option.value"
        type="button"
        role="option"
        :aria-selected="option.value === modelValue"
        :disabled="option.disabled"
        class="w-full text-left px-3 py-2 text-xs rounded-none flex items-center justify-between gap-2 transition-colors"
        :class="
          option.value === modelValue
            ? 'bg-neutral-900 text-white font-semibold'
            : activeIndex === index
              ? 'bg-neutral-100 text-neutral-900'
              : option.disabled
                ? 'bg-white text-neutral-400 cursor-not-allowed'
                : 'bg-white text-neutral-900 hover:bg-neutral-100 cursor-pointer'
        "
        @mouseenter="activeIndex = index"
        @click="selectOption(option)"
      >
        <span class="truncate">{{ option.label }}</span>
        <Icon
          v-if="option.value === modelValue"
          icon="lucide:check"
          class="h-3.5 w-3.5 shrink-0 text-white"
          aria-hidden="true"
        />
      </button>
    </div>
  </Teleport>
</template>
