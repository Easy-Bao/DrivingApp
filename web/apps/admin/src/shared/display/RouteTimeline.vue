<script setup lang="ts">
withDefaults(
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
</script>

<template>
  <div class="flex flex-col">
    <div class="flex items-stretch gap-3">
      <div class="flex w-5 shrink-0 flex-col items-center">
        <svg
          viewBox="0 0 20 20"
          class="mt-0.5 h-5 w-5 shrink-0 text-neutral-900"
          aria-hidden="true"
        >
          <circle cx="10" cy="8" r="7" fill="currentColor" />
          <path d="M7 13L10 19L13 13Z" fill="currentColor" />
          <circle cx="10" cy="8" r="3" fill="white" />
        </svg>
        <div
          class="my-1 min-h-3 flex-1 border-l border-dashed border-neutral-300"
          aria-hidden="true"
        />
      </div>
      <div class="min-w-0 pb-3">
        <div class="text-[11px] font-semibold text-neutral-500">{{ pickupLabel }}</div>
        <div class="text-xs font-semibold text-neutral-900">{{ pickup }}</div>
      </div>
    </div>

    <div class="flex items-start gap-3">
      <div class="flex w-5 shrink-0 flex-col items-center">
        <svg
          viewBox="0 0 20 20"
          class="mt-0.5 h-5 w-5 shrink-0 text-emerald-600"
          aria-hidden="true"
        >
          <circle cx="10" cy="8" r="7" fill="currentColor" />
          <path d="M7 13L10 19L13 13Z" fill="currentColor" />
          <circle cx="10" cy="8" r="3" fill="white" />
        </svg>
      </div>
      <div class="min-w-0">
        <div class="text-[11px] font-semibold text-neutral-500">{{ dropoffLabel }}</div>
        <div class="text-xs font-semibold text-neutral-900">{{ dropoff }}</div>
      </div>
    </div>
  </div>
</template>
