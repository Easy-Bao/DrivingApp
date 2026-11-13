<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { SAFETY_PILLARS } from '@/features/landing-showcase/data/landingContent'
import UiIcon from '@/shared/components/UiIcon.vue'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'

type TelemetryPreviewMode = 'share' | 'sos'

const previewMode = ref<TelemetryPreviewMode>('share')

const EMERGENCY_CHANNELS = [
  {
    name: 'EasyRide Dispatch Safety Desk',
    detail: 'Triggered with trip ID, live coordinates, driver plate/MTOP, and passenger contact.',
    actionLabel: 'In-App One-Tap SOS',
  },
  {
    name: 'Pagadian City CDRRMO Rescue',
    detail: 'Direct municipal emergency coordination inside Pagadian City 7016 boundaries.',
    actionLabel: 'Hotline: 062-925-0911',
  },
  {
    name: 'Philippine National Emergency',
    detail: 'Immediate voice handoff from the trip safety sheet when urgent assistance is needed.',
    actionLabel: 'Dial 911',
  },
]
</script>

<template>
  <LandingLayout>
    <section class="border-b border-slate-200 bg-linear-to-b from-slate-50 to-white py-14 sm:py-20">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="max-w-3xl">
          <span
            class="inline-flex items-center gap-2 rounded-full border border-emerald-200 bg-emerald-50 px-3.5 py-1.5 text-xs font-bold text-emerald-800"
          >
            <UiIcon name="shield-check" size-class="h-4 w-4" />
            Verified Operations &amp; Emergency Response
          </span>
          <h1 class="mt-4 text-4xl font-extrabold tracking-tight text-[#090d16] sm:text-5xl">
            Verified Pagadian operators before every pickup
          </h1>
          <p class="mt-4 text-base leading-relaxed text-slate-600 sm:text-lg">
            EasyRide binds every bid to a checked LTO Professional License, Pagadian municipal MTOP
            franchise number, and real-time GPS trip session.
          </p>
        </div>

        <div class="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          <article
            v-for="pillar in SAFETY_PILLARS"
            :key="pillar.id"
            class="rounded-3xl border border-slate-200 bg-white p-6 shadow-xs"
          >
            <span
              class="inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200"
            >
              <UiIcon :name="pillar.icon" size-class="h-5 w-5" />
            </span>
            <p class="mt-4 text-[11px] font-bold uppercase tracking-wider text-slate-500">
              {{ pillar.verificationCode }}
            </p>
            <h2 class="mt-1 text-lg font-extrabold text-[#090d16]">{{ pillar.title }}</h2>
            <p class="mt-2 text-sm leading-relaxed text-slate-600">{{ pillar.summary }}</p>
          </article>
        </div>
      </div>
    </section>

    <section class="bg-[#090d16] py-16 text-white sm:py-20">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="grid items-start gap-10 lg:grid-cols-12">
          <div class="lg:col-span-7">
            <p class="text-xs font-bold uppercase tracking-wider text-emerald-300">
              In-Trip SOS Escalation
            </p>
            <h2 class="mt-2 text-3xl font-extrabold tracking-tight text-white">
              Three rapid-response channels from inside every active ride
            </h2>

            <div class="mt-8 grid gap-4 md:grid-cols-3 lg:grid-cols-1">
              <article
                v-for="channel in EMERGENCY_CHANNELS"
                :key="channel.name"
                class="flex flex-col justify-between gap-3 rounded-3xl border border-white/15 bg-white/5 p-5 sm:flex-row sm:items-center"
              >
                <div>
                  <h3 class="text-base font-bold text-white">{{ channel.name }}</h3>
                  <p class="mt-1 text-sm leading-relaxed text-slate-300">{{ channel.detail }}</p>
                </div>
                <p
                  class="inline-flex shrink-0 items-center gap-2 rounded-full bg-emerald-500/15 px-3.5 py-1.5 text-xs font-bold text-emerald-200 ring-1 ring-emerald-400/30"
                >
                  <UiIcon name="phone" size-class="h-3.5 w-3.5" />
                  {{ channel.actionLabel }}
                </p>
              </article>
            </div>
          </div>

          <div class="lg:col-span-5">
            <div class="rounded-3xl border border-white/15 bg-slate-900 p-6 shadow-2xl">
              <div
                class="flex flex-wrap items-center justify-between gap-2 border-b border-white/10 pb-4"
              >
                <span class="text-xs font-bold uppercase tracking-wider text-emerald-300">
                  Interactive Safety Preview
                </span>
                <div class="inline-flex rounded-full bg-white/10 p-0.5 text-xs font-bold">
                  <button
                    type="button"
                    class="rounded-full px-3 py-1 transition-colors"
                    :class="
                      previewMode === 'share' ? 'bg-emerald-500 text-[#090d16]' : 'text-slate-300'
                    "
                    @click="previewMode = 'share'"
                  >
                    Live Share
                  </button>
                  <button
                    type="button"
                    class="rounded-full px-3 py-1 transition-colors"
                    :class="previewMode === 'sos' ? 'bg-rose-500 text-white' : 'text-slate-300'"
                    @click="previewMode = 'sos'"
                  >
                    SOS Active
                  </button>
                </div>
              </div>

              <div
                v-if="previewMode === 'share'"
                class="mt-5 space-y-3 rounded-2xl bg-white p-5 text-[#090d16]"
              >
                <div class="flex items-center justify-between">
                  <span class="text-xs font-bold uppercase tracking-wider text-emerald-700">
                    Family Trip Link Active
                  </span>
                  <span
                    class="rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-bold text-emerald-800"
                  >
                    On Route
                  </span>
                </div>
                <p class="text-base font-extrabold">Danilo R. · Bajaj RE 4S</p>
                <p class="text-xs text-slate-600">
                  Plate ZDS-418M · MTOP POBLACION-04 · Agora Market &#8594; Dao Capitol
                </p>
                <p class="rounded-xl bg-slate-50 px-3 py-2 text-xs font-medium text-slate-700">
                  Agreed Fare: &#8369;55 cash · ETA 7 mins remaining
                </p>
              </div>

              <div
                v-else
                class="mt-5 space-y-3 rounded-2xl border border-rose-500/40 bg-rose-950/50 p-5 text-white"
              >
                <div class="flex items-center justify-between">
                  <span class="text-xs font-bold uppercase tracking-wider text-rose-300">
                    Emergency Telemetry Dispatched
                  </span>
                  <span
                    class="rounded-full bg-rose-500 px-2.5 py-0.5 text-[11px] font-bold text-white"
                  >
                    Priority
                  </span>
                </div>
                <p class="text-base font-extrabold">GPS Ping: Rizal Ave / Santiago Jct</p>
                <p class="text-xs text-rose-100/90">
                  Unit Plate ZDS-418M and MTOP records surfaced automatically to EasyRide Safety
                  Operations Desk and Pagadian CDRRMO (062-925-0911).
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-10 flex flex-wrap gap-3">
          <RouterLink
            to="/"
            class="inline-flex min-h-11 items-center gap-2 rounded-full bg-white px-6 py-2.5 text-sm font-bold text-[#090d16] hover:bg-emerald-50"
          >
            <span>Return to Fare Estimator</span>
            <UiIcon name="arrow-right" size-class="h-4 w-4" />
          </RouterLink>
          <RouterLink
            to="/download"
            class="inline-flex min-h-11 items-center rounded-full border border-white/25 px-6 py-2.5 text-sm font-bold text-white hover:bg-white/10"
          >
            Download EasyRide Apps
          </RouterLink>
        </div>
      </div>
    </section>
  </LandingLayout>
</template>
