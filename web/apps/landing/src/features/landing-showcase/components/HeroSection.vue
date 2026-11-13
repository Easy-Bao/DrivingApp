<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <section class="border-b border-neutral-200 bg-white">
    <div
      class="mx-auto grid max-w-6xl items-center gap-12 px-4 py-14 sm:px-6 sm:py-20 lg:grid-cols-2 lg:py-24"
    >
      <div>
        <p class="text-xs font-semibold tracking-widest text-neutral-500 uppercase">
          Pagadian City
        </p>
        <h1
          class="mt-4 text-4xl leading-tight font-bold tracking-tight text-neutral-900 sm:text-5xl lg:text-6xl"
        >
          Rides around Pagadian, made easy.
        </h1>
        <p class="mt-5 max-w-md text-base leading-relaxed text-neutral-600 sm:text-lg">
          Book a Taxicle in seconds. See the fare first, pick your driver, and pay in cash.
        </p>

        <div class="mt-8 flex flex-wrap items-center gap-3">
          <RouterLink
            to="/download"
            class="inline-flex min-h-12 items-center bg-neutral-900 px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-neutral-800"
          >
            Download App
          </RouterLink>
          <RouterLink
            to="/drive"
            class="inline-flex min-h-12 items-center border border-neutral-300 bg-white px-6 py-3 text-sm font-semibold text-neutral-900 transition-colors hover:bg-neutral-100"
          >
            Become a Driver
          </RouterLink>
        </div>

        <p class="mt-5 text-xs text-neutral-500">Free for passengers. Android and iOS.</p>
      </div>

      <div class="flex justify-center lg:justify-end" aria-hidden="true">
        <div class="w-64 border-[10px] border-neutral-900 bg-neutral-50 shadow-xl sm:w-72">
          <div class="flex h-72 flex-col justify-between bg-neutral-200 p-4">
            <span class="w-fit bg-white px-2 py-1 text-[10px] font-semibold text-neutral-700">
              Agora Public Market
            </span>
            <span
              class="w-fit self-end bg-neutral-900 px-2 py-1 text-[10px] font-semibold text-white"
            >
              Dao Capitol
            </span>
          </div>
          <div class="space-y-3 border-t border-neutral-200 bg-white p-4">
            <div class="flex items-baseline justify-between">
              <span class="text-sm font-bold text-neutral-900">Standard</span>
              <span class="text-lg font-bold tabular-nums text-neutral-900">₱61</span>
            </div>
            <div class="flex items-center justify-between text-xs text-neutral-500">
              <span>3.4 km · 11 min</span>
              <span>3 drivers nearby</span>
            </div>
            <div class="bg-neutral-900 py-2.5 text-center text-xs font-semibold text-white">
              Book Ride
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
