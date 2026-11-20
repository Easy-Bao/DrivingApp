<script setup lang="ts">
import { Icon } from '@iconify/vue'

export interface FlyoutItem {
  id: string
  label: string
  icon: string
  badge?: string | number
  isActive?: boolean
  onSelect: () => void
}

export interface FlyoutState {
  id: string
  title: string
  activeItemLabel?: string | null
  metaText?: string
  items: FlyoutItem[]
  top: number
  left: number
}

export interface TooltipState {
  label: string
  top: number
  left: number
}

defineProps<{
  collapsed: boolean
  activeFlyout: FlyoutState | null
  collapsedTooltip: TooltipState | null
}>()

const emit = defineEmits<{
  (e: 'cancelClose'): void
  (e: 'scheduleClose'): void
}>()
</script>

<template>
  <Teleport to="body">
    <div
      v-if="collapsed && activeFlyout"
      data-test="collapsed-flyout"
      role="menu"
      :aria-label="activeFlyout.title"
      class="fixed z-50 w-56 bg-white border border-neutral-300 shadow-lg"
      :style="{ top: `${activeFlyout.top}px`, left: `${activeFlyout.left}px` }"
      @mouseenter="emit('cancelClose')"
      @mouseleave="emit('scheduleClose')"
    >
      <div
        class="bg-neutral-900 text-white px-3 py-2 flex items-center justify-between gap-2 text-xs font-semibold"
      >
        <span class="truncate">{{ activeFlyout.title }}</span>
        <span
          v-if="activeFlyout.activeItemLabel"
          class="text-[10px] font-medium text-neutral-300 truncate max-w-[110px]"
        >
          {{ activeFlyout.activeItemLabel }}
        </span>
        <span v-else class="text-[10px] font-mono text-neutral-300">
          {{ activeFlyout.metaText ?? activeFlyout.items.length }}
        </span>
      </div>
      <div class="p-1 space-y-0.5 max-h-72 overflow-y-auto">
        <button
          v-for="item in activeFlyout.items"
          :key="item.id"
          type="button"
          role="menuitem"
          :aria-current="item.isActive ? 'page' : undefined"
          class="w-full px-2.5 py-2 text-left text-xs font-medium flex items-center justify-between gap-2 transition-colors cursor-pointer"
          :class="
            item.isActive
              ? 'bg-neutral-900 text-white font-semibold'
              : 'text-neutral-700 hover:bg-neutral-100 hover:text-neutral-900'
          "
          @click="item.onSelect()"
        >
          <span class="flex items-center gap-2 min-w-0">
            <Icon
              :icon="item.icon"
              class="text-sm shrink-0"
              :class="item.isActive ? 'text-white' : 'text-neutral-500'"
              aria-hidden="true"
            />
            <span class="truncate">{{ item.label }}</span>
          </span>
          <span
            v-if="item.badge"
            class="px-1.5 py-0.5 text-[10px] font-semibold shrink-0"
            :class="item.isActive ? 'bg-white text-neutral-900' : 'bg-neutral-900 text-white'"
          >
            {{ item.badge }}
          </span>
        </button>
      </div>
    </div>

    <div
      v-if="collapsed && collapsedTooltip && !activeFlyout"
      data-test="collapsed-tooltip"
      role="tooltip"
      class="fixed z-50 -translate-y-1/2 bg-neutral-900 text-white px-2.5 py-1.5 text-xs font-medium pointer-events-none shadow-sm"
      :style="{ top: `${collapsedTooltip.top}px`, left: `${collapsedTooltip.left}px` }"
    >
      {{ collapsedTooltip.label }}
    </div>
  </Teleport>
</template>
