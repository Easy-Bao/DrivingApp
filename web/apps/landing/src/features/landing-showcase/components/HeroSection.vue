<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { FareEstimatorCard } from '@/features/fare-estimation'
import {
  HERO_TRUST_METRICS,
  LIVE_DISPATCH_CHANNELS,
} from '@/features/landing-showcase/data/landingContent'
import StoreBadges from '@/shared/components/StoreBadges.vue'
import UiIcon from '@/shared/components/UiIcon.vue'
</script>

<template>
  <section
    id="fare-estimator"
    class="relative overflow-hidden border-b border-slate-200/80 bg-linear-to-b from-emerald-50/75 via-white to-white"
  >
    <div
      class="pointer-events-none absolute -left-24 top-10 h-72 w-72 rounded-full bg-emerald-200/35 blur-3xl"
      aria-hidden="true"
    />
    <div
      class="pointer-events-none absolute -right-24 bottom-0 h-80 w-80 rounded-full bg-teal-100/45 blur-3xl"
      aria-hidden="true"
    />

    <div class="relative mx-auto max-w-7xl px-4 py-12 sm:px-6 sm:py-16 lg:px-8 lg:py-20">
      <div class="grid items-center gap-10 lg:grid-cols-12 lg:gap-12">
        <div class="lg:col-span-6">
          <div class="flex flex-wrap items-center gap-2">
            <span
              class="inline-flex items-center gap-2 rounded-full border border-emerald-200 bg-white px-3.5 py-1.5 text-xs font-bold text-emerald-800 shadow-2xs"
            >
              <span
                class="h-2 w-2 rounded-full bg-emerald-600 motion-safe:animate-pulse"
                aria-hidden="true"
              />
              Pagadian City 7016 · Active Dispatch
            </span>
            <span
              class="inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white/90 px-3 py-1.5 text-xs font-semibold text-slate-700"
            >
              MTOP &amp; LTO Verified Fleet
            </span>
          </div>

          <h1
            class="mt-5 text-4xl font-extrabold tracking-tight text-[#090d16] sm:text-5xl lg:leading-[1.08]"
          >
            Pagadian Taxicles, priced upfront before you step in.
          </h1>

          <p class="mt-5 max-w-xl text-base leading-relaxed text-slate-600 sm:text-lg">
            Compare live 90-second bids from LTO- and MTOP-verified local drivers, lock a fair PHP
            fare before pickup, and commute smoothly across Poblacion hills, Dao Capitol, and
            Bulatok Terminal.
          </p>

          <div
            class="mt-6 flex flex-wrap items-center gap-x-4 gap-y-2 rounded-2xl border border-emerald-200/80 bg-white/85 px-4 py-2.5 text-xs shadow-2xs"
          >
            <span class="font-bold text-emerald-800">Simulated staging lanes:</span>
            <span
              v-for="channel in LIVE_DISPATCH_CHANNELS"
              :key="channel.zone"
              class="inline-flex items-center gap-1.5 text-slate-700"
            >
              <span class="h-1.5 w-1.5 rounded-full bg-emerald-500" aria-hidden="true" />
              <strong class="font-semibold text-[#090d16]">{{ channel.zone }}</strong>
              <span class="text-slate-500">({{ channel.count }})</span>
            </span>
          </div>

          <div class="mt-7 flex flex-wrap items-center gap-3">
            <RouterLink
              to="/drive"
              class="inline-flex min-h-12 items-center gap-2 rounded-full bg-[#090d16] px-6 py-3 text-sm font-bold text-white shadow-sm transition-colors hover:bg-slate-800"
            >
              <span>Drive &amp; Earn with EasyRide</span>
              <UiIcon name="arrow-right" size-class="h-4 w-4" />
            </RouterLink>

            <RouterLink
              to="/safety"
              class="inline-flex min-h-12 items-center gap-2 rounded-full border border-slate-300 bg-white px-5 py-3 text-sm font-bold text-[#090d16] transition-colors hover:border-emerald-300 hover:bg-emerald-50/60"
            >
              <UiIcon name="shield-check" size-class="h-4 w-4 text-emerald-700" />
              <span>How We Verify Every Unit</span>
            </RouterLink>
          </div>

          <div class="mt-7">
            <StoreBadges audience="passenger" surface="light" />
          </div>

          <dl class="mt-8 grid grid-cols-3 gap-3 border-t border-slate-200/80 pt-6 sm:gap-5">
            <div v-for="metric in HERO_TRUST_METRICS" :key="metric.label">
              <dt class="text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                {{ metric.label }}
              </dt>
              <dd class="mt-1 text-lg font-extrabold tabular-nums text-[#090d16] sm:text-2xl">
                {{ metric.value }}
              </dd>
              <p class="mt-0.5 text-xs text-slate-600">{{ metric.detail }}</p>
            </div>
          </dl>
        </div>

        <div class="relative lg:col-span-6">
          <div
            class="pointer-events-none absolute -inset-4 rounded-[2rem] bg-[radial-gradient(#94a3b8_1px,transparent_1px)] bg-size-[18px_18px] opacity-30"
            aria-hidden="true"
          />
          <div class="relative">
            <FareEstimatorCard />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
