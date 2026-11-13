<script setup lang="ts">
import { RouterLink } from 'vue-router'
import PlatformArchitectureExplorer from '@/features/platform-architecture/components/PlatformArchitectureExplorer.vue'
import UiIcon from '@/shared/components/UiIcon.vue'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'

const CLIENT_SURFACE_CARDS = [
  {
    name: 'apps/passenger (Flutter)',
    detail: 'Clean BLoC passenger app with upfront fare floor estimation and live 90s bid sheet.',
  },
  {
    name: 'apps/driver (Flutter)',
    detail: 'Background geolocation, MTOP document upload, and Company QRPh prepaid wallet.',
  },
  {
    name: 'web/apps/admin (Vue 3)',
    detail: 'Operations console for top-up verification, bidding monitor, and SOS alerts.',
  },
]
</script>

<template>
  <LandingLayout>
    <section class="border-b border-slate-200 bg-linear-to-b from-slate-50 to-white py-14 sm:py-16">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="max-w-3xl">
          <span
            class="inline-flex items-center gap-2 rounded-full border border-emerald-200 bg-emerald-50 px-3.5 py-1.5 text-xs font-bold text-emerald-800"
          >
            <UiIcon name="server" size-class="h-4 w-4" />
            System Topology · Static Architecture Overview
          </span>
          <h1 class="mt-4 text-4xl font-extrabold tracking-tight text-[#090d16] sm:text-5xl">
            Dispatch platform architecture built for real-time reliability
          </h1>
          <p class="mt-4 text-base leading-relaxed text-slate-600 sm:text-lg">
            Inspect how EasyRide connects Flutter commuter and driver apps with a Go modular
            monolith, PostgreSQL + PostGIS persistence, and low-latency WebSocket bidding channels.
          </p>
        </div>

        <div class="mt-10 grid gap-4 md:grid-cols-3">
          <article
            v-for="client in CLIENT_SURFACE_CARDS"
            :key="client.name"
            class="rounded-3xl border border-slate-200 bg-white p-5 shadow-2xs"
          >
            <p class="text-xs font-mono font-bold text-emerald-800">{{ client.name }}</p>
            <p class="mt-2 text-sm leading-relaxed text-slate-700">{{ client.detail }}</p>
          </article>
        </div>

        <div class="mt-10">
          <PlatformArchitectureExplorer />
        </div>

        <div class="mt-10 flex flex-wrap gap-3">
          <RouterLink
            to="/"
            class="inline-flex min-h-11 items-center gap-2 rounded-full bg-emerald-700 px-6 py-2.5 text-sm font-bold text-white hover:bg-emerald-800"
          >
            <span>Try Pagadian Fare Estimator</span>
            <UiIcon name="arrow-right" size-class="h-4 w-4" />
          </RouterLink>
          <RouterLink
            to="/drive"
            class="inline-flex min-h-11 items-center rounded-full border border-slate-300 bg-white px-6 py-2.5 text-sm font-bold text-[#090d16] hover:bg-slate-50"
          >
            Explore Driver Program
          </RouterLink>
        </div>
      </div>
    </section>
  </LandingLayout>
</template>
