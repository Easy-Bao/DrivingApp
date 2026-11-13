<script setup lang="ts">
interface BrandLogoProps {
  surface?: 'light' | 'dark'
  showCityTag?: boolean
}

withDefaults(defineProps<BrandLogoProps>(), {
  surface: 'light',
  showCityTag: false,
})
</script>

<template>
  <span class="inline-flex items-center gap-2.5 select-none">
    <span
      class="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-[#059669] shadow-sm ring-1 ring-inset ring-white/20"
    >
      <svg
        width="22"
        height="22"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
      >
        <path
          d="M5 14.5H19L16.7 8.4A2 2 0 0 0 14.83 7.1H9.17A2 2 0 0 0 7.3 8.4L5 14.5Z"
          fill="#FFFFFF"
        />
        <path
          d="M4.5 14.5H19.5V16.8A1.2 1.2 0 0 1 18.3 18H5.7A1.2 1.2 0 0 1 4.5 16.8V14.5Z"
          fill="#ECFDF5"
        />
        <circle cx="8" cy="18.2" r="2.1" fill="#090D16" stroke="#FFFFFF" stroke-width="1.2" />
        <circle cx="16" cy="18.2" r="2.1" fill="#090D16" stroke="#FFFFFF" stroke-width="1.2" />
      </svg>
    </span>
    <span class="flex items-baseline gap-2">
      <span
        class="text-lg font-extrabold tracking-tight"
        :class="surface === 'dark' ? 'text-white' : 'text-[#090d16]'"
      >
        Easy<span :class="surface === 'dark' ? 'text-emerald-300' : 'text-emerald-700'">Ride</span>
      </span>
      <span
        v-if="showCityTag"
        class="hidden sm:inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold tracking-wide"
        :class="
          surface === 'dark'
            ? 'bg-white/10 text-emerald-200 ring-1 ring-white/15'
            : 'bg-emerald-50 text-emerald-800 ring-1 ring-emerald-200'
        "
      >
        Pagadian 7016
      </span>
    </span>
  </span>
</template>
