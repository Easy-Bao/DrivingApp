<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { SAFETY_PILLARS } from '@/features/landing-showcase/data/landingContent'
import UiIcon from '@/shared/components/UiIcon.vue'
</script>

<template>
  <section class="bg-white py-16 sm:py-24">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="grid items-center gap-12 lg:grid-cols-12">
        <div class="lg:col-span-5">
          <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
            Trust &amp; Verification Architecture
          </p>
          <h2 class="mt-2 text-3xl font-extrabold tracking-tight text-[#090d16] sm:text-4xl">
            Every active driver clears five document checks first
          </h2>
          <p class="mt-4 text-base leading-relaxed text-slate-600">
            No unverified operator can bid on a passenger trip. Operations teams review municipal
            franchise documents, track expiries automatically, and keep 24/7 SOS tools pinned on
            both rider and driver screens.
          </p>

          <div class="mt-6 rounded-2xl border border-emerald-200 bg-emerald-50/80 p-5">
            <div class="flex items-start gap-3">
              <span
                class="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-700 text-white"
              >
                <UiIcon name="phone" size-class="h-5 w-5" />
              </span>
              <div>
                <h3 class="text-sm font-extrabold text-[#090d16]">
                  Pagadian Emergency Escalation Ready
                </h3>
                <p class="mt-1 text-xs leading-relaxed text-slate-700">
                  In-trip SOS connects with EasyRide Dispatch Desk, Pagadian CDRRMO (062-925-0911),
                  and National 911 with live trip telemetry attached.
                </p>
              </div>
            </div>
          </div>

          <div class="mt-7">
            <RouterLink
              to="/safety"
              class="inline-flex min-h-11 items-center gap-2 rounded-full bg-[#090d16] px-6 py-2.5 text-sm font-bold text-white transition-colors hover:bg-slate-800"
            >
              <span>Inspect Safety &amp; SOS Standards</span>
              <UiIcon name="arrow-right" size-class="h-4 w-4" />
            </RouterLink>
          </div>
        </div>

        <div class="grid gap-4 sm:grid-cols-2 lg:col-span-7">
          <article
            v-for="pillar in SAFETY_PILLARS"
            :key="pillar.id"
            class="rounded-3xl border border-slate-200 bg-slate-50/70 p-6 transition-colors hover:border-emerald-200 hover:bg-emerald-50/30"
          >
            <div class="flex items-center justify-between gap-2">
              <span
                class="inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-white text-emerald-700 shadow-2xs ring-1 ring-slate-200"
              >
                <UiIcon :name="pillar.icon" size-class="h-5 w-5" />
              </span>
              <span class="text-[11px] font-bold tracking-wider text-slate-500">
                {{ pillar.verificationCode }}
              </span>
            </div>

            <h3 class="mt-4 text-base font-extrabold text-[#090d16]">{{ pillar.title }}</h3>
            <p class="mt-2 text-sm leading-relaxed text-slate-600">{{ pillar.summary }}</p>
          </article>
        </div>
      </div>
    </div>
  </section>
</template>
