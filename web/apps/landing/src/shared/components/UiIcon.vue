<script setup lang="ts">
export type IconName =
  | 'alert'
  | 'apple'
  | 'arrow-right'
  | 'arrow-up-right'
  | 'bolt'
  | 'check'
  | 'check-circle'
  | 'chevron-down'
  | 'clock'
  | 'close'
  | 'compass'
  | 'download'
  | 'lock'
  | 'map-pin'
  | 'menu'
  | 'message'
  | 'navigation'
  | 'package'
  | 'phone'
  | 'play-store'
  | 'qr-code'
  | 'radio'
  | 'server'
  | 'shield'
  | 'shield-check'
  | 'sparkles'
  | 'star'
  | 'taxicle'
  | 'trending-up'
  | 'users'
  | 'wallet'

interface UiIconProps {
  name: IconName
  sizeClass?: string
}

withDefaults(defineProps<UiIconProps>(), {
  sizeClass: 'h-5 w-5',
})
</script>

<template>
  <svg
    :class="['shrink-0', sizeClass]"
    viewBox="0 0 24 24"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    aria-hidden="true"
  >
    <template v-if="name === 'taxicle'">
      <path
        d="M4.5 14h15l-2.1-5.8A2 2 0 0 0 15.5 7H8.5a2 2 0 0 0-1.9 1.2L4.5 14Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
      <path
        d="M3.5 14h17v2.5a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1V14Z"
        stroke="currentColor"
        stroke-width="1.8"
      />
      <circle cx="7.5" cy="18.5" r="2" fill="currentColor" />
      <circle cx="16.5" cy="18.5" r="2" fill="currentColor" />
      <path d="M12 7v7" stroke="currentColor" stroke-width="1.6" />
    </template>

    <template v-else-if="name === 'bolt'">
      <path
        d="M13 2L4.5 13.5H11.5L10.5 22L19.5 10.5H12.5L13 2Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'package'">
      <path
        d="M12 3l8 4.5v9L12 21l-8-4.5v-9L12 3Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
      <path
        d="M12 12l8-4.5M12 12v9M12 12L4 7.5M16 5.25L8 9.75"
        stroke="currentColor"
        stroke-width="1.6"
      />
    </template>

    <template v-else-if="name === 'shield'">
      <path
        d="M12 3l7 3v5.5c0 4.6-2.9 8.2-7 9.5-4.1-1.3-7-4.9-7-9.5V6l7-3Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'shield-check'">
      <path
        d="M12 3l7 3v5.5c0 4.6-2.9 8.2-7 9.5-4.1-1.3-7-4.9-7-9.5V6l7-3Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
      <path
        d="M9 12.2l2 2 4-4"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'check'">
      <path
        d="M5 12.5l4.2 4.2L19 7"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'check-circle'">
      <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8" />
      <path
        d="M8.5 12.3l2.3 2.3 4.7-4.8"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'clock'">
      <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8" />
      <path d="M12 7.5V12l3 1.8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
    </template>

    <template v-else-if="name === 'map-pin'">
      <path
        d="M12 21s6.5-5.6 6.5-11a6.5 6.5 0 1 0-13 0c0 5.4 6.5 11 6.5 11Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
      <circle cx="12" cy="10" r="2.2" stroke="currentColor" stroke-width="1.8" />
    </template>

    <template v-else-if="name === 'navigation'">
      <path
        d="M3.5 11.2L20.5 3.5L13 20.5L10.8 13.4L3.5 11.2Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'arrow-right'">
      <path
        d="M5 12h14M13.5 6.5L19 12l-5.5 5.5"
        stroke="currentColor"
        stroke-width="1.85"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'arrow-up-right'">
      <path
        d="M7 17L17 7M9 7h8v8"
        stroke="currentColor"
        stroke-width="1.85"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'star'">
      <path
        d="M12 2.8l2.7 5.5 6.1.9-4.4 4.3 1 6.1L12 16.7l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9L12 2.8Z"
        fill="currentColor"
      />
    </template>

    <template v-else-if="name === 'sparkles'">
      <path
        d="M12 3l1.7 4.8L18.5 9.5l-4.8 1.7L12 16l-1.7-4.8L5.5 9.5l4.8-1.7L12 3ZM19 16l.8 2.2L22 19l-2.2.8L19 22l-.8-2.2L16 19l2.2-.8L19 16Z"
        stroke="currentColor"
        stroke-width="1.7"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'qr-code'">
      <rect x="4" y="4" width="6" height="6" rx="1" stroke="currentColor" stroke-width="1.8" />
      <rect x="14" y="4" width="6" height="6" rx="1" stroke="currentColor" stroke-width="1.8" />
      <rect x="4" y="14" width="6" height="6" rx="1" stroke="currentColor" stroke-width="1.8" />
      <path
        d="M14 14h2.5v2.5H14V14ZM18 14h2v6h-4v-2M14 19.5h2"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linecap="round"
      />
    </template>

    <template v-else-if="name === 'wallet'">
      <path
        d="M4 7.5A2.5 2.5 0 0 1 6.5 5H18a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H6.5A2.5 2.5 0 0 1 4 16.5v-9Z"
        stroke="currentColor"
        stroke-width="1.8"
      />
      <path d="M16 12h4v3h-4a1.5 1.5 0 0 1 0-3Z" stroke="currentColor" stroke-width="1.7" />
    </template>

    <template v-else-if="name === 'phone'">
      <path
        d="M6.6 4.2h2.8l1.2 3.8-1.9 1.5a13.5 13.5 0 0 0 5.8 5.8l1.5-1.9 3.8 1.2v2.8a2 2 0 0 1-2.2 2A15.8 15.8 0 0 1 4.6 6.4a2 2 0 0 1 2-2.2Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'alert'">
      <path
        d="M12 4L3.5 19h17L12 4Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
      <path
        d="M12 9.5v4.2M12 16.5h.01"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
      />
    </template>

    <template v-else-if="name === 'menu'">
      <path
        d="M4 7h16M4 12h16M4 17h16"
        stroke="currentColor"
        stroke-width="1.9"
        stroke-linecap="round"
      />
    </template>

    <template v-else-if="name === 'close'">
      <path
        d="M6 6l12 12M18 6L6 18"
        stroke="currentColor"
        stroke-width="1.9"
        stroke-linecap="round"
      />
    </template>

    <template v-else-if="name === 'chevron-down'">
      <path
        d="M6 9l6 6 6-6"
        stroke="currentColor"
        stroke-width="1.9"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'play-store'">
      <path
        d="M5 4.2c0-.8.9-1.3 1.6-.9l12.6 7.8c.7.4.7 1.4 0 1.8L6.6 20.7c-.7.4-1.6-.1-1.6-.9V4.2Z"
        fill="currentColor"
      />
    </template>

    <template v-else-if="name === 'apple'">
      <path
        d="M15.8 12.6c0-2.1 1.7-3.1 1.8-3.2-1-1.5-2.5-1.7-3.1-1.7-1.3-.1-2.6.8-3.2.8-.7 0-1.7-.8-2.8-.8-1.4 0-2.8.8-3.5 2.1-1.5 2.6-.4 6.5 1.1 8.6.7 1 1.6 2.2 2.7 2.1 1.1 0 1.5-.7 2.8-.7s1.7.7 2.8.7c1.2 0 1.9-1 2.6-2 .8-1.2 1.2-2.4 1.2-2.5-.1 0-2.4-.9-2.4-3.4ZM13.7 6.3c.6-.7 1-1.7.9-2.7-.9 0-1.9.6-2.5 1.3-.5.6-1 1.6-.9 2.6 1 .1 1.9-.5 2.5-1.2Z"
        fill="currentColor"
      />
    </template>

    <template v-else-if="name === 'download'">
      <path
        d="M12 4v11m0 0l-4-4m4 4l4-4M5 19h14"
        stroke="currentColor"
        stroke-width="1.85"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'server'">
      <rect x="4" y="4" width="16" height="6.5" rx="1.5" stroke="currentColor" stroke-width="1.8" />
      <rect
        x="4"
        y="13.5"
        width="16"
        height="6.5"
        rx="1.5"
        stroke="currentColor"
        stroke-width="1.8"
      />
      <circle cx="8" cy="7.25" r="0.9" fill="currentColor" />
      <circle cx="8" cy="16.75" r="0.9" fill="currentColor" />
    </template>

    <template v-else-if="name === 'radio'">
      <circle cx="12" cy="12" r="2.2" fill="currentColor" />
      <path
        d="M8.2 15.8a5.4 5.4 0 0 1 0-7.6M15.8 8.2a5.4 5.4 0 0 1 0 7.6M5.4 18.6a9.3 9.3 0 0 1 0-13.2M18.6 5.4a9.3 9.3 0 0 1 0 13.2"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linecap="round"
      />
    </template>

    <template v-else-if="name === 'users'">
      <circle cx="9.5" cy="8.5" r="3.2" stroke="currentColor" stroke-width="1.8" />
      <path
        d="M3.5 19a6 6 0 0 1 12 0"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linecap="round"
      />
      <circle cx="16.8" cy="9.5" r="2.4" stroke="currentColor" stroke-width="1.6" />
      <path
        d="M16.5 14.5a4.5 4.5 0 0 1 4 4.5"
        stroke="currentColor"
        stroke-width="1.6"
        stroke-linecap="round"
      />
    </template>

    <template v-else-if="name === 'trending-up'">
      <path
        d="M4 16l5.5-5.5 4 4L20 8M15 8h5v5"
        stroke="currentColor"
        stroke-width="1.85"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'compass'">
      <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8" />
      <path
        d="M15.2 8.8l-2 5.2-5.2 2 2-5.2 5.2-2Z"
        stroke="currentColor"
        stroke-width="1.7"
        stroke-linejoin="round"
      />
    </template>

    <template v-else-if="name === 'lock'">
      <rect x="5" y="11" width="14" height="9" rx="2" stroke="currentColor" stroke-width="1.8" />
      <path
        d="M8 11V8a4 4 0 1 1 8 0v3"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linecap="round"
      />
    </template>

    <template v-else-if="name === 'message'">
      <path
        d="M5 6.5A2.5 2.5 0 0 1 7.5 4h9A2.5 2.5 0 0 1 19 6.5v7A2.5 2.5 0 0 1 16.5 16H10l-4.2 3.2A.5.5 0 0 1 5 18.8V6.5Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
    </template>
  </svg>
</template>
