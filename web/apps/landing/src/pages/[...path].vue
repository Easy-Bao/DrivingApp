<script setup lang="ts">
import { RouterLink } from 'vue-router'
import UiIcon from '@/shared/components/UiIcon.vue'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'
</script>

<template>
  <LandingLayout>
    <section class="py-20 sm:py-28">
      <div class="mx-auto max-w-2xl px-4 text-center sm:px-6">
        <span
          class="inline-flex items-center gap-2 rounded-full bg-emerald-50 px-3.5 py-1.5 text-xs font-bold text-emerald-800 ring-1 ring-emerald-200"
        >
          Route Not Found
        </span>
        <h1 class="mt-4 text-4xl font-extrabold tracking-tight text-[#090d16] sm:text-5xl">
          This Pagadian route isn’t on the map
        </h1>
        <p class="mt-4 text-base text-slate-600">
          The page you tried to open does not exist or moved when we switched to clean file-based
          routing. Head back to estimate a Taxicle fare or explore driver partner options.
        </p>

        <div class="mt-8 flex flex-wrap items-center justify-center gap-3">
          <RouterLink
            to="/"
            class="inline-flex min-h-11 items-center gap-2 rounded-full bg-emerald-700 px-6 py-2.5 text-sm font-bold text-white hover:bg-emerald-800"
          >
            <span>Back to Home</span>
            <UiIcon name="arrow-right" size-class="h-4 w-4" />
          </RouterLink>
          <RouterLink
            to="/drive"
            class="inline-flex min-h-11 items-center rounded-full border border-slate-300 bg-white px-5 py-2.5 text-sm font-bold text-[#090d16] hover:bg-slate-50"
          >
            Drive &amp; Earn
          </RouterLink>
          <RouterLink
            to="/download"
            class="inline-flex min-h-11 items-center rounded-full border border-slate-300 bg-white px-5 py-2.5 text-sm font-bold text-[#090d16] hover:bg-slate-50"
          >
            Get the App
          </RouterLink>
        </div>
      </div>
    </section>
  </LandingLayout>
</template>
