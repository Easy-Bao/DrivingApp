<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { RIDE_TIER_CONFIGS } from '@/features/fare-estimation/api/fare-estimation.api'
import type { RideTier } from '@/features/fare-estimation/types'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'

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
    <section class="border-b border-neutral-200 bg-neutral-50 py-14 sm:py-20">
      <div class="mx-auto max-w-5xl px-4 sm:px-6">
        <div
          v-if="prefilledRoute"
          class="mb-8 flex flex-wrap items-center justify-between gap-3 border border-neutral-300 bg-white px-5 py-4 text-sm text-neutral-900"
        >
          <div>
            <p class="text-[11px] font-bold uppercase tracking-wider text-neutral-500">
              Selected Route Estimate
            </p>
            <p class="mt-0.5 font-semibold">
              {{ prefilledRoute.from }} &#8594; {{ prefilledRoute.to }} ·
              {{ prefilledRoute.tierName }}
              <strong v-if="prefilledRoute.fare" class="tabular-nums">
                &#8369;{{ prefilledRoute.fare }}
              </strong>
            </p>
          </div>
          <RouterLink
            to="/"
            class="border border-neutral-300 bg-neutral-50 px-3.5 py-1.5 text-xs font-semibold text-neutral-900 hover:bg-neutral-100"
          >
            Adjust route
          </RouterLink>
        </div>

        <div class="text-center">
          <h1 class="text-4xl font-bold tracking-tight text-neutral-900 sm:text-5xl">
            Get EasyRide
          </h1>
          <p class="mx-auto mt-3 max-w-xl text-base text-neutral-600">
            Choose the Passenger app to book Pagadian Taxicles, or install the Driver app to bid on
            local trips.
          </p>

          <div
            role="group"
            aria-label="Switch app edition"
            class="mt-7 inline-flex border border-neutral-300 bg-white p-1"
          >
            <button
              type="button"
              class="px-5 py-2 text-sm font-semibold transition-colors"
              :class="
                selectedRole === 'passenger'
                  ? 'bg-neutral-900 text-white'
                  : 'text-neutral-600 hover:text-neutral-900'
              "
              @click="selectedRole = 'passenger'"
            >
              Passenger App
            </button>
            <button
              type="button"
              class="px-5 py-2 text-sm font-semibold transition-colors"
              :class="
                selectedRole === 'driver'
                  ? 'bg-neutral-900 text-white'
                  : 'text-neutral-600 hover:text-neutral-900'
              "
              @click="selectedRole = 'driver'"
            >
              Driver App
            </button>
          </div>
        </div>

        <div class="mt-10 grid gap-6 md:grid-cols-2">
          <article
            id="android"
            class="flex flex-col justify-between border p-7 transition-colors"
            :class="
              selectedRole === 'passenger'
                ? 'border-neutral-900 bg-white'
                : 'border-neutral-200 bg-neutral-100/60'
            "
          >
            <div>
              <div class="flex items-center justify-between text-xs">
                <span
                  class="border border-neutral-300 bg-neutral-50 px-2.5 py-1 font-semibold text-neutral-800"
                >
                  Commuters
                </span>
                <span class="font-medium text-neutral-500">Android &amp; iOS</span>
              </div>

              <h2 class="mt-4 text-2xl font-bold text-neutral-900">EasyRide Passenger</h2>
              <p class="mt-2 text-sm leading-relaxed text-neutral-600">
                Check upfront fare floors across Poblacion, Dao Capitol, and Bulatok Terminal and
                choose from live Taxicle bids.
              </p>

              <ul class="mt-5 space-y-2.5 text-sm text-neutral-700">
                <li class="flex items-center gap-2.5">
                  <span class="h-1.5 w-1.5 shrink-0 bg-neutral-900" aria-hidden="true" />
                  Upfront PHP tariff preview before pickup
                </li>
                <li class="flex items-center gap-2.5">
                  <span class="h-1.5 w-1.5 shrink-0 bg-neutral-900" aria-hidden="true" />
                  Live arrival ETA and driver unit comparison
                </li>
                <li class="flex items-center gap-2.5">
                  <span class="h-1.5 w-1.5 shrink-0 bg-neutral-900" aria-hidden="true" />
                  Saved Pagadian stops and trip receipts
                </li>
              </ul>
            </div>

            <div id="ios" class="mt-7 flex flex-wrap gap-2.5 border-t border-neutral-200 pt-5">
              <RouterLink
                :to="{ path: '/download', query: { role: 'passenger' }, hash: '#android' }"
                class="inline-flex min-h-11 items-center gap-3 bg-neutral-900 px-4 py-2 text-left text-white transition-colors hover:bg-neutral-800"
              >
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    d="M5 4.2c0-.8.9-1.3 1.6-.9l12.6 7.8c.7.4.7 1.4 0 1.8L6.6 20.7c-.7.4-1.6-.1-1.6-.9V4.2Z"
                  />
                </svg>
                <span>
                  <span class="block text-[10px] uppercase tracking-wider text-neutral-300">
                    Get it on
                  </span>
                  <span class="block text-sm font-bold leading-tight">Google Play</span>
                </span>
              </RouterLink>

              <RouterLink
                :to="{ path: '/download', query: { role: 'passenger' }, hash: '#ios' }"
                class="inline-flex min-h-11 items-center gap-3 border border-neutral-300 bg-white px-4 py-2 text-left text-neutral-900 transition-colors hover:bg-neutral-100"
              >
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    d="M15.8 12.6c0-2.1 1.7-3.1 1.8-3.2-1-1.5-2.5-1.7-3.1-1.7-1.3-.1-2.6.8-3.2.8-.7 0-1.7-.8-2.8-.8-1.4 0-2.8.8-3.5 2.1-1.5 2.6-.4 6.5 1.1 8.6.7 1 1.6 2.2 2.7 2.1 1.1 0 1.5-.7 2.8-.7s1.7.7 2.8.7c1.2 0 1.9-1 2.6-2 .8-1.2 1.2-2.4 1.2-2.5-.1 0-2.4-.9-2.4-3.4ZM13.7 6.3c.6-.7 1-1.7.9-2.7-.9 0-1.9.6-2.5 1.3-.5.6-1 1.6-.9 2.6 1 .1 1.9-.5 2.5-1.2Z"
                  />
                </svg>
                <span>
                  <span class="block text-[10px] uppercase tracking-wider text-neutral-500">
                    Download on the
                  </span>
                  <span class="block text-sm font-bold leading-tight">App Store</span>
                </span>
              </RouterLink>

              <RouterLink
                :to="{ path: '/download', query: { role: 'passenger' }, hash: '#apk' }"
                class="inline-flex min-h-11 items-center border border-neutral-300 bg-neutral-50 px-4 py-2 text-sm font-semibold text-neutral-900 transition-colors hover:bg-neutral-100"
              >
                Direct APK
              </RouterLink>
            </div>
          </article>

          <article
            id="apk"
            class="flex flex-col justify-between border p-7 transition-colors"
            :class="
              selectedRole === 'driver'
                ? 'border-neutral-900 bg-white'
                : 'border-neutral-200 bg-neutral-100/60'
            "
          >
            <div>
              <div class="flex items-center justify-between text-xs">
                <span class="bg-neutral-900 px-2.5 py-1 font-semibold text-white">
                  Taxicle Drivers
                </span>
                <span class="font-medium text-neutral-500">Android Build</span>
              </div>

              <h2 class="mt-4 text-2xl font-bold text-neutral-900">EasyRide Driver</h2>
              <p class="mt-2 text-sm leading-relaxed text-neutral-600">
                Receive nearby Pagadian passenger requests, send transparent bids, and track your
                QRPh wallet balance in one view.
              </p>

              <ul class="mt-5 space-y-2.5 text-sm text-neutral-700">
                <li class="flex items-center gap-2.5">
                  <span class="h-1.5 w-1.5 shrink-0 bg-neutral-900" aria-hidden="true" />
                  QRPh top-ups via GCash, Maya, BDO, and BPI
                </li>
                <li class="flex items-center gap-2.5">
                  <span class="h-1.5 w-1.5 shrink-0 bg-neutral-900" aria-hidden="true" />
                  10%–15% commission ledger per completed trip
                </li>
                <li class="flex items-center gap-2.5">
                  <span class="h-1.5 w-1.5 shrink-0 bg-neutral-900" aria-hidden="true" />
                  Fast onboarding for LTO and MTOP units
                </li>
              </ul>
            </div>

            <div class="mt-7 flex flex-wrap gap-2.5 border-t border-neutral-200 pt-5">
              <RouterLink
                :to="{ path: '/download', query: { role: 'driver' }, hash: '#android' }"
                class="inline-flex min-h-11 items-center gap-3 bg-neutral-900 px-4 py-2 text-left text-white transition-colors hover:bg-neutral-800"
              >
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    d="M5 4.2c0-.8.9-1.3 1.6-.9l12.6 7.8c.7.4.7 1.4 0 1.8L6.6 20.7c-.7.4-1.6-.1-1.6-.9V4.2Z"
                  />
                </svg>
                <span>
                  <span class="block text-[10px] uppercase tracking-wider text-neutral-300">
                    Driver Android
                  </span>
                  <span class="block text-sm font-bold leading-tight">Google Play</span>
                </span>
              </RouterLink>

              <RouterLink
                :to="{ path: '/download', query: { role: 'driver' }, hash: '#apk' }"
                class="inline-flex min-h-11 items-center border border-neutral-300 bg-white px-4 py-2 text-sm font-semibold text-neutral-900 transition-colors hover:bg-neutral-100"
              >
                Driver APK
              </RouterLink>
            </div>
          </article>
        </div>

        <div
          class="mt-8 flex flex-col items-center justify-between gap-6 border border-neutral-200 bg-white p-6 sm:flex-row"
        >
          <div class="flex items-center gap-4">
            <div class="border border-neutral-200 bg-neutral-50 p-2.5">
              <svg
                width="64"
                height="64"
                viewBox="0 0 68 68"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
              >
                <rect width="68" height="68" fill="#FFFFFF" />
                <rect x="6" y="6" width="20" height="20" stroke="#090D16" stroke-width="4" />
                <rect x="12" y="12" width="8" height="8" fill="#090D16" />
                <rect x="42" y="6" width="20" height="20" stroke="#090D16" stroke-width="4" />
                <rect x="48" y="12" width="8" height="8" fill="#090D16" />
                <rect x="6" y="42" width="20" height="20" stroke="#090D16" stroke-width="4" />
                <rect x="12" y="48" width="8" height="8" fill="#090D16" />
                <rect x="32" y="8" width="4" height="8" fill="#090D16" />
                <rect x="32" y="22" width="4" height="12" fill="#525252" />
                <rect x="8" y="32" width="14" height="4" fill="#090D16" />
                <rect x="28" y="30" width="12" height="10" fill="#090D16" />
                <rect x="46" y="32" width="16" height="4" fill="#090D16" />
                <rect x="32" y="46" width="10" height="10" fill="#090D16" />
                <rect x="48" y="46" width="14" height="6" fill="#525252" />
                <rect x="48" y="56" width="14" height="6" fill="#090D16" />
              </svg>
            </div>
            <div>
              <p class="text-xs font-bold uppercase tracking-wider text-neutral-500">
                Desktop Quick Handoff
              </p>
              <h3 class="text-base font-bold text-neutral-900">
                {{
                  selectedRole === 'passenger'
                    ? 'Scan for EasyRide Passenger'
                    : 'Scan for EasyRide Driver'
                }}
              </h3>
              <p class="mt-0.5 text-xs text-neutral-500">
                Store links and signed APK downloads activate once mobile builds publish.
              </p>
            </div>
          </div>

          <RouterLink
            to="/"
            class="inline-flex min-h-10 shrink-0 items-center border border-neutral-300 bg-white px-4 py-2 text-xs font-semibold text-neutral-900 hover:bg-neutral-100"
          >
            Back to Estimator
          </RouterLink>
        </div>
      </div>
    </section>
  </LandingLayout>
</template>
