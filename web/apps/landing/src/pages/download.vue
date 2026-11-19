<script setup lang="ts">
import { motion } from 'motion-v'
import { computed, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { RIDE_TIER_CONFIGS } from '@/features/fare-estimation/api/fare-estimation.api'
import type { RideTier } from '@/features/fare-estimation/types'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'

const EASE = [0.22, 1, 0.36, 1] as const

function readQueryString(value: unknown): string {
  if (typeof value === 'string') {
    return value.trim()
  }
  if (Array.isArray(value)) {
    const first = value[0]
    return typeof first === 'string' ? first.trim() : ''
  }
  return ''
}

const route = useRoute()

const initialRole = readQueryString(route?.query?.role) === 'driver' ? 'driver' : 'passenger'
const selectedRole = ref<'passenger' | 'driver'>(initialRole)

const prefilledRoute = computed(() => {
  const from = readQueryString(route?.query?.from)
  const to = readQueryString(route?.query?.to)
  const fare = readQueryString(route?.query?.fare)
  const rawTier = readQueryString(route?.query?.tier)
  const tierKey: RideTier = rawTier === 'comfort' || rawTier === 'executive' ? rawTier : 'standard'

  if (!from || !to) {
    return null
  }

  return {
    from,
    to,
    fare,
    tierName: RIDE_TIER_CONFIGS[tierKey].shortLabel,
  }
})
</script>

<template>
  <LandingLayout>
    <section class="bg-neutral-50/70 py-16 sm:py-22">
      <div class="mx-auto max-w-5xl px-5 sm:px-6">
        <motion.div
          v-if="prefilledRoute"
          :initial="{ opacity: 0, y: 10 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.4, ease: EASE }"
          class="mb-10 flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-neutral-200/90 bg-white px-5 py-4 text-sm text-neutral-950 shadow-[0_8px_24px_-16px_rgba(9,13,22,0.12)]"
        >
          <div class="flex items-start gap-3">
            <span class="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-emerald-600" aria-hidden="true" />
            <div>
              <p class="text-[11px] font-bold tracking-[0.12em] text-neutral-400 uppercase">
                Selected Route Estimate
              </p>
              <p class="mt-0.5 font-semibold text-neutral-950">
                {{ prefilledRoute.from }} &#8594; {{ prefilledRoute.to }} ·
                {{ prefilledRoute.tierName }}
                <strong v-if="prefilledRoute.fare" class="tabular-nums text-neutral-950">
                  &#8369;{{ prefilledRoute.fare }}
                </strong>
              </p>
            </div>
          </div>

          <RouterLink
            to="/"
            class="rounded-full border border-neutral-200/90 bg-neutral-50 px-4 py-1.5 text-xs font-semibold text-neutral-700 transition-colors hover:border-neutral-300 hover:bg-neutral-100 hover:text-neutral-950"
          >
            Adjust route
          </RouterLink>
        </motion.div>

        <motion.div
          :initial="{ opacity: 0, y: 12 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.48, ease: EASE }"
          class="text-center"
        >
          <p class="text-[11px] font-bold tracking-[0.14em] text-neutral-400 uppercase">
            Mobile Apps
          </p>
          <h1
            class="mt-3 text-4xl leading-tight font-bold tracking-[-0.035em] text-neutral-950 sm:text-5xl"
          >
            Get EasyRide
          </h1>
          <p class="mx-auto mt-3.5 max-w-xl text-base leading-relaxed text-neutral-500">
            Choose the Passenger app to book Pagadian Taxicles, or install the Driver app to bid on
            local trips.
          </p>

          <div
            role="group"
            aria-label="Switch app edition"
            class="mt-8 inline-flex rounded-full border border-neutral-200/90 bg-white p-1 shadow-[0_1px_3px_rgba(9,13,22,0.04)]"
          >
            <button
              type="button"
              class="relative z-10 rounded-full px-5 py-2 text-sm font-semibold transition-colors duration-150"
              :class="
                selectedRole === 'passenger'
                  ? 'text-white'
                  : 'text-neutral-500 hover:text-neutral-950'
              "
              @click="selectedRole = 'passenger'"
            >
              <motion.span
                v-if="selectedRole === 'passenger'"
                layout-id="download-role-pill"
                :transition="{ type: 'spring', stiffness: 460, damping: 34 }"
                class="absolute inset-0 -z-10 rounded-full bg-neutral-950 shadow-xs"
                aria-hidden="true"
              />
              Passenger App
            </button>
            <button
              type="button"
              class="relative z-10 rounded-full px-5 py-2 text-sm font-semibold transition-colors duration-150"
              :class="
                selectedRole === 'driver' ? 'text-white' : 'text-neutral-500 hover:text-neutral-950'
              "
              @click="selectedRole = 'driver'"
            >
              <motion.span
                v-if="selectedRole === 'driver'"
                layout-id="download-role-pill"
                :transition="{ type: 'spring', stiffness: 460, damping: 34 }"
                class="absolute inset-0 -z-10 rounded-full bg-neutral-950 shadow-xs"
                aria-hidden="true"
              />
              Driver App
            </button>
          </div>
        </motion.div>

        <motion.div
          :initial="{ opacity: 0, y: 16 }"
          :animate="{ opacity: 1, y: 0 }"
          :transition="{ duration: 0.52, delay: 0.08, ease: EASE }"
          class="mt-10 grid gap-6 md:grid-cols-2"
        >
          <article
            id="android"
            class="flex flex-col justify-between rounded-2xl border p-7 transition-all duration-200 sm:p-8"
            :class="
              selectedRole === 'passenger'
                ? 'border-neutral-950 bg-white shadow-[0_20px_48px_-24px_rgba(9,13,22,0.14)] ring-1 ring-neutral-950/10'
                : 'border-neutral-200/80 bg-white/60 opacity-85 hover:opacity-100'
            "
          >
            <div>
              <div class="flex items-center justify-between text-xs">
                <span
                  class="rounded-full border border-neutral-200/90 bg-neutral-50 px-3 py-1 font-semibold text-neutral-800"
                >
                  Commuters
                </span>
                <span class="font-medium text-neutral-400">Android &amp; iOS</span>
              </div>

              <h2 class="mt-5 text-2xl font-bold tracking-[-0.02em] text-neutral-950">
                EasyRide Passenger
              </h2>
              <p class="mt-2.5 text-sm leading-relaxed text-neutral-500">
                Check upfront fare floors across Poblacion, Dao Capitol, and Bulatok Terminal and
                choose from live Taxicle bids.
              </p>

              <ul class="mt-6 space-y-2.5 text-sm text-neutral-700">
                <li class="flex items-center gap-3">
                  <span class="h-px w-3 shrink-0 bg-neutral-300" aria-hidden="true" />
                  Upfront PHP tariff preview before pickup
                </li>
                <li class="flex items-center gap-3">
                  <span class="h-px w-3 shrink-0 bg-neutral-300" aria-hidden="true" />
                  Live arrival ETA and driver unit comparison
                </li>
                <li class="flex items-center gap-3">
                  <span class="h-px w-3 shrink-0 bg-neutral-300" aria-hidden="true" />
                  Saved Pagadian stops and trip receipts
                </li>
              </ul>
            </div>

            <div id="ios" class="mt-8 flex flex-wrap gap-2.5 border-t border-neutral-100 pt-6">
              <RouterLink
                :to="{ path: '/download', query: { role: 'passenger' }, hash: '#android' }"
                class="inline-flex min-h-11 items-center gap-2.5 rounded-xl bg-neutral-950 px-4 py-2 text-left text-white shadow-[0_4px_12px_-4px_rgba(9,13,22,0.3)] transition-all duration-150 hover:bg-neutral-800 active:scale-[0.985]"
              >
                <svg
                  width="15"
                  height="15"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    d="M5 4.2c0-.8.9-1.3 1.6-.9l12.6 7.8c.7.4.7 1.4 0 1.8L6.6 20.7c-.7.4-1.6-.1-1.6-.9V4.2Z"
                  />
                </svg>
                <span>
                  <span class="block text-[9px] uppercase tracking-wider text-neutral-300">
                    Get it on
                  </span>
                  <span class="block text-xs font-bold leading-tight">Google Play</span>
                </span>
              </RouterLink>

              <RouterLink
                :to="{ path: '/download', query: { role: 'passenger' }, hash: '#ios' }"
                class="inline-flex min-h-11 items-center gap-2.5 rounded-xl border border-neutral-200/90 bg-white px-4 py-2 text-left text-neutral-950 shadow-[0_1px_2px_rgba(0,0,0,0.03)] transition-all duration-150 hover:border-neutral-300 hover:bg-neutral-50 active:scale-[0.985]"
              >
                <svg
                  width="15"
                  height="15"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    d="M15.8 12.6c0-2.1 1.7-3.1 1.8-3.2-1-1.5-2.5-1.7-3.1-1.7-1.3-.1-2.6.8-3.2.8-.7 0-1.7-.8-2.8-.8-1.4 0-2.8.8-3.5 2.1-1.5 2.6-.4 6.5 1.1 8.6.7 1 1.6 2.2 2.7 2.1 1.1 0 1.5-.7 2.8-.7s1.7.7 2.8.7c1.2 0 1.9-1 2.6-2 .8-1.2 1.2-2.4 1.2-2.5-.1 0-2.4-.9-2.4-3.4ZM13.7 6.3c.6-.7 1-1.7.9-2.7-.9 0-1.9.6-2.5 1.3-.5.6-1 1.6-.9 2.6 1 .1 1.9-.5 2.5-1.2Z"
                  />
                </svg>
                <span>
                  <span class="block text-[9px] uppercase tracking-wider text-neutral-500">
                    Download on the
                  </span>
                  <span class="block text-xs font-bold leading-tight">App Store</span>
                </span>
              </RouterLink>
            </div>
          </article>

          <article
            id="apk"
            class="flex flex-col justify-between rounded-2xl border p-7 transition-all duration-200 sm:p-8"
            :class="
              selectedRole === 'driver'
                ? 'border-neutral-950 bg-white shadow-[0_20px_48px_-24px_rgba(9,13,22,0.14)] ring-1 ring-neutral-950/10'
                : 'border-neutral-200/80 bg-white/60 opacity-85 hover:opacity-100'
            "
          >
            <div>
              <div class="flex items-center justify-between text-xs">
                <span class="rounded-full bg-neutral-950 px-3 py-1 font-semibold text-white">
                  Taxicle Drivers
                </span>
                <span class="font-medium text-neutral-400">Android Build</span>
              </div>

              <h2 class="mt-5 text-2xl font-bold tracking-[-0.02em] text-neutral-950">
                EasyRide Driver
              </h2>
              <p class="mt-2.5 text-sm leading-relaxed text-neutral-500">
                Receive nearby Pagadian passenger requests, send transparent bids, and track your
                QRPh wallet balance in one view.
              </p>

              <ul class="mt-6 space-y-2.5 text-sm text-neutral-700">
                <li class="flex items-center gap-3">
                  <span class="h-px w-3 shrink-0 bg-neutral-300" aria-hidden="true" />
                  QRPh top-ups via GCash, Maya, BDO, and BPI
                </li>
                <li class="flex items-center gap-3">
                  <span class="h-px w-3 shrink-0 bg-neutral-300" aria-hidden="true" />
                  10%–15% commission ledger per completed trip
                </li>
                <li class="flex items-center gap-3">
                  <span class="h-px w-3 shrink-0 bg-neutral-300" aria-hidden="true" />
                  Fast onboarding for LTO and MTOP units
                </li>
              </ul>
            </div>

            <div class="mt-8 flex flex-wrap gap-2.5 border-t border-neutral-100 pt-6">
              <RouterLink
                :to="{ path: '/download', query: { role: 'driver' }, hash: '#android' }"
                class="inline-flex min-h-11 items-center gap-2.5 rounded-xl bg-neutral-950 px-4 py-2 text-left text-white shadow-[0_4px_12px_-4px_rgba(9,13,22,0.3)] transition-all duration-150 hover:bg-neutral-800 active:scale-[0.985]"
              >
                <svg
                  width="15"
                  height="15"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    d="M5 4.2c0-.8.9-1.3 1.6-.9l12.6 7.8c.7.4.7 1.4 0 1.8L6.6 20.7c-.7.4-1.6-.1-1.6-.9V4.2Z"
                  />
                </svg>
                <span>
                  <span class="block text-[9px] uppercase tracking-wider text-neutral-300">
                    Driver Android
                  </span>
                  <span class="block text-xs font-bold leading-tight">Google Play</span>
                </span>
              </RouterLink>
            </div>
          </article>
        </motion.div>
      </div>
    </section>
  </LandingLayout>
</template>
