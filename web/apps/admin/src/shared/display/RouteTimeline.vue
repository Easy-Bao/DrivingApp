<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    pickup: string
    dropoff: string
    pickupLabel?: string
    dropoffLabel?: string
  }>(),
  {
    pickupLabel: 'Pick Up',
    dropoffLabel: 'Drop Off',
  },
)

const endpoints = computed(() => [
  {
    label: props.pickupLabel,
    address: props.pickup,
    pinClass: 'text-neutral-900',
    showConnector: true,
  },
  {
    label: props.dropoffLabel,
    address: props.dropoff,
    pinClass: 'text-emerald-600',
    showConnector: false,
  },
])
</script>

<template>
  <div class="flex flex-col">
    <div
      v-for="stop in endpoints"
      :key="stop.label"
      class="flex gap-3"
      :class="stop.showConnector ? 'items-stretch' : 'items-start'"
    >
      <div class="flex w-5 shrink-0 flex-col items-center">
        <svg
          viewBox="0 0 20 20"
          class="mt-0.5 h-5 w-5 shrink-0"
          :class="stop.pinClass"
          aria-hidden="true"
        >
          <circle cx="10" cy="8" r="7" fill="currentColor" />
          <path d="M7 13L10 19L13 13Z" fill="currentColor" />
          <circle cx="10" cy="8" r="3" fill="white" />
        </svg>
        <div
          v-if="stop.showConnector"
          class="my-1 min-h-3 flex-1 border-l border-dashed border-neutral-300"
          aria-hidden="true"
        />
      </div>
      <div class="min-w-0" :class="stop.showConnector ? 'pb-3' : ''">
        <div class="text-[11px] font-semibold text-neutral-500">{{ stop.label }}</div>
        <div class="text-xs font-semibold text-neutral-900">{{ stop.address }}</div>
      </div>
    </div>
  </div>
</template>
