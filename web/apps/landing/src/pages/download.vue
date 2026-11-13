<script setup lang="ts">
import { computed, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { RIDE_TIER_CONFIGS } from '@/features/fare-estimation/api/fare-estimation.api'
import type { RideTier } from '@/features/fare-estimation/types'
import StoreBadges from '@/shared/components/StoreBadges.vue'
import UiIcon from '@/shared/components/UiIcon.vue'
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
    tierName: RIDE_TIER_CONFIGS[tierKey].name,
  }
})
</script>

<template>
  <LandingLayout>
    <section
      class="border-b border-slate-200 bg-linear-to-b from-emerald-50/75 via-white to-white py-14 sm:py-20"
    >
      <div class="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <div
          v-if="prefilledRoute"
          class="mb-8 rounded-3xl border border-emerald-300 bg-emerald-50 p-5 shadow-xs sm:p-6"
        >
          <div class="flex flex-wrap items-start justify-between gap-4">
            <div>
              <p class="text-xs font-bold uppercase tracking-wider text-emerald-800">
                Selected Route Estimate Ready
              </p>
              <h2 class="mt-1 text-lg font-extrabold text-[#090d16]">
                {{ prefilledRoute.from }} &#8594; {{ prefilledRoute.to }}
              </h2>
              <p class="mt-1 text-sm text-slate-700">
                Unit tier: <strong class="text-[#090d16]">{{ prefilledRoute.tierName }}</strong>
                <span v-if="prefilledRoute.fare">
                  · Estimated fare floor
                  <strong class="tabular-nums text-emerald-800"
                    >&#8369;{{ prefilledRoute.fare }}</strong
                  >
                </span>
              </p>
            </div>
            <RouterLink
              :to="{ path: '/', hash: '#fare-estimator' }"
              class="rounded-full border border-emerald-300 bg-white px-4 py-2 text-xs font-bold text-emerald-900 hover:bg-emerald-100"
            >
              Adjust route
            </RouterLink>
          </div>
        </div>

        <div class="text-center">
          <span
            class="inline-flex items-center gap-2 rounded-full border border-emerald-200 bg-white px-3.5 py-1.5 text-xs font-bold text-emerald-800"
          >
            <UiIcon name="download" size-class="h-4 w-4" />
            Mobile App Builds · Pagadian City 7016
          </span>
          <h1 class="mt-4 text-4xl font-extrabold tracking-tight text-[#090d16] sm:text-5xl">
            Get EasyRide on your phone
          </h1>
          <p class="mx-auto mt-3 max-w-2xl text-base text-slate-600 sm:text-lg">
            Choose the Passenger app to post Pagadian Taxicle trips and compare live bids, or
            install the Driver Partner app with Company QRPh wallet support.
          </p>

          <div
            role="group"
            aria-label="Switch app edition"
            class="mt-7 inline-flex rounded-full border border-slate-200 bg-white p-1 shadow-2xs"
          >
            <button
              type="button"
              class="rounded-full px-5 py-2 text-sm font-bold transition-colors"
              :class="
                selectedRole === 'passenger'
                  ? 'bg-emerald-700 text-white'
                  : 'text-slate-700 hover:text-[#090d16]'
              "
              @click="selectedRole = 'passenger'"
            >
              Passenger App
            </button>
            <button
              type="button"
              class="rounded-full px-5 py-2 text-sm font-bold transition-colors"
              :class="
                selectedRole === 'driver'
                  ? 'bg-[#090d16] text-white'
                  : 'text-slate-700 hover:text-[#090d16]'
              "
              @click="selectedRole = 'driver'"
            >
              Driver Partner App
            </button>
          </div>
        </div>

        <div class="mt-10 grid gap-6 md:grid-cols-2">
          <article
            id="android"
            class="flex flex-col justify-between rounded-3xl border p-7 transition-all"
            :class="
              selectedRole === 'passenger'
                ? 'border-emerald-600 bg-white shadow-lg ring-1 ring-emerald-600/20'
                : 'border-slate-200 bg-slate-50/70'
            "
          >
            <div>
              <div class="flex items-center justify-between">
                <span
                  class="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-800"
                >
                  For Commuters
                </span>
                <span class="text-xs font-semibold text-slate-500">Android &amp; iOS</span>
              </div>
              <h2 class="mt-4 text-2xl font-extrabold text-[#090d16]">EasyRide Passenger</h2>
              <p class="mt-2 text-sm leading-relaxed text-slate-600">
                Preview upfront municipal fare floors across Poblacion, Dao Capitol, Bulatok
                Terminal, and Airport routes. Compare verified driver bids inside 90 seconds.
              </p>

              <ul class="mt-5 space-y-2.5 text-sm text-slate-700">
                <li class="flex items-center gap-2">
                  <UiIcon name="check-circle" size-class="h-4 w-4 text-emerald-700" />
                  Live map tracking &amp; shareable trip link
                </li>
                <li class="flex items-center gap-2">
                  <UiIcon name="check-circle" size-class="h-4 w-4 text-emerald-700" />
                  Saved Pagadian barangay places &amp; cash receipts
                </li>
                <li class="flex items-center gap-2">
                  <UiIcon name="check-circle" size-class="h-4 w-4 text-emerald-700" />
                  One-tap in-trip SOS &amp; Pagadian CDRRMO dialer
                </li>
              </ul>
            </div>

            <div class="mt-7 border-t border-slate-100 pt-5">
              <StoreBadges audience="passenger" surface="light" />
            </div>
          </article>

          <article
            id="apk"
            class="flex flex-col justify-between rounded-3xl border p-7 transition-all"
            :class="
              selectedRole === 'driver'
                ? 'border-[#090d16] bg-white shadow-lg ring-1 ring-slate-900/15'
                : 'border-slate-200 bg-slate-50/70'
            "
          >
            <div>
              <div class="flex items-center justify-between">
                <span class="rounded-full bg-[#090d16] px-3 py-1 text-xs font-bold text-white">
                  For Taxicle Operators
                </span>
                <span class="text-xs font-semibold text-slate-500">Android Flutter Build</span>
              </div>
              <h2 class="mt-4 text-2xl font-extrabold text-[#090d16]">EasyRide Driver</h2>
              <p class="mt-2 text-sm leading-relaxed text-slate-600">
                Receive real-time nearby passenger broadcasts, place transparent PHP bids, and
                manage your prepaid Company QRPh wallet balance in one screen.
              </p>

              <ul class="mt-5 space-y-2.5 text-sm text-slate-700">
                <li class="flex items-center gap-2">
                  <UiIcon name="check-circle" size-class="h-4 w-4 text-emerald-700" />
                  QRPh top-ups via GCash, Maya, BDO &amp; BPI InstaPay
                </li>
                <li class="flex items-center gap-2">
                  <UiIcon name="check-circle" size-class="h-4 w-4 text-emerald-700" />
                  LTO, MTOP, TODA &amp; TPL expiry reminders
                </li>
                <li class="flex items-center gap-2">
                  <UiIcon name="check-circle" size-class="h-4 w-4 text-emerald-700" />
                  Clear 10%–15% commission ledger per completed trip
                </li>
              </ul>
            </div>

            <div class="mt-7 border-t border-slate-100 pt-5">
              <StoreBadges audience="driver" surface="light" />
            </div>
          </article>
        </div>

        <div
          class="mt-8 flex flex-col items-center justify-between gap-6 rounded-3xl border border-slate-200 bg-white p-6 sm:flex-row"
        >
          <div class="flex items-center gap-4">
            <div class="rounded-2xl border border-slate-200 bg-slate-50 p-3">
              <svg
                width="68"
                height="68"
                viewBox="0 0 68 68"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
              >
                <rect width="68" height="68" rx="8" fill="#FFFFFF" />
                <rect x="6" y="6" width="20" height="20" rx="3" stroke="#090D16" stroke-width="4" />
                <rect x="12" y="12" width="8" height="8" rx="1" fill="#059669" />
                <rect
                  x="42"
                  y="6"
                  width="20"
                  height="20"
                  rx="3"
                  stroke="#090D16"
                  stroke-width="4"
                />
                <rect x="48" y="12" width="8" height="8" rx="1" fill="#090D16" />
                <rect
                  x="6"
                  y="42"
                  width="20"
                  height="20"
                  rx="3"
                  stroke="#090D16"
                  stroke-width="4"
                />
                <rect x="12" y="48" width="8" height="8" rx="1" fill="#090D16" />
                <rect x="32" y="8" width="4" height="8" fill="#090D16" />
                <rect x="32" y="22" width="4" height="12" fill="#059669" />
                <rect x="8" y="32" width="14" height="4" fill="#090D16" />
                <rect x="28" y="30" width="12" height="10" rx="2" fill="#059669" />
                <rect x="46" y="32" width="16" height="4" fill="#090d16" />
                <rect x="32" y="46" width="10" height="10" fill="#090D16" />
                <rect x="48" y="46" width="14" height="6" fill="#059669" />
                <rect x="48" y="56" width="14" height="6" fill="#090D16" />
              </svg>
            </div>
            <div>
              <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
                Desktop Quick Handoff
              </p>
              <h3 class="text-base font-extrabold text-[#090d16]">
                Scan preview for
                {{ selectedRole === 'passenger' ? 'EasyRide Passenger' : 'EasyRide Driver' }}
              </h3>
              <p class="mt-0.5 text-xs text-slate-600">
                Static distribution preview: live APK checksums &amp; store URLs connect upon mobile
                release publishing.
              </p>
            </div>
          </div>

          <RouterLink
            to="/"
            class="inline-flex min-h-10 shrink-0 items-center gap-2 rounded-full border border-slate-300 bg-white px-4 py-2 text-xs font-bold text-[#090d16] hover:bg-slate-50"
          >
            <span>Back to Fare Estimator</span>
            <UiIcon name="arrow-right" size-class="h-3.5 w-3.5" />
          </RouterLink>
        </div>
      </div>
    </section>
  </LandingLayout>
</template>
