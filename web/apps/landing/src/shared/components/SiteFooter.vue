<script setup lang="ts">
import { RouterLink } from 'vue-router'
import BrandLogo from '@/shared/components/BrandLogo.vue'
import StoreBadges from '@/shared/components/StoreBadges.vue'
import UiIcon from '@/shared/components/UiIcon.vue'

type AppRoutePath = '/' | '/drive' | '/safety' | '/download' | '/architecture'

interface FooterLink {
  label: string
  to: AppRoutePath | { path: AppRoutePath; hash?: string; query?: Record<string, string> }
}

const EXPLORE_LINKS: FooterLink[] = [
  { label: 'Ride with EasyRide', to: '/' },
  { label: 'Taxicle Fare Estimator', to: { path: '/', hash: '#fare-estimator' } },
  { label: '90-Second Bidding', to: { path: '/', hash: '#bidding-flow' } },
  { label: 'Pagadian Coverage Zones', to: { path: '/', hash: '#coverage' } },
  { label: 'Rider & Driver FAQ', to: { path: '/', hash: '#faq' } },
]

const PARTNER_LINKS: FooterLink[] = [
  { label: 'Drive & Earn', to: '/drive' },
  { label: 'QRPh Wallet Top-Ups', to: { path: '/drive', hash: '#commission' } },
  { label: 'TODA & LTO Verification', to: { path: '/drive', hash: '#requirements' } },
  { label: '24/7 Safety & SOS Desk', to: '/safety' },
  { label: 'Download Android & iOS', to: '/download' },
]

const PLATFORM_LINKS: FooterLink[] = [
  { label: 'System Architecture', to: '/architecture' },
  { label: 'Go Modular Monolith', to: { path: '/architecture', hash: '#services' } },
  { label: 'WebSocket Live Bidding', to: { path: '/architecture', hash: '#protocol' } },
  { label: 'Safety Verification Gates', to: '/safety' },
]
</script>

<template>
  <footer class="border-t border-slate-800 bg-[#090d16] text-slate-300">
    <div class="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8">
      <div class="grid gap-10 lg:grid-cols-12">
        <div class="space-y-5 lg:col-span-5">
          <RouterLink to="/" class="inline-block rounded-xl focus-visible:outline-emerald-300">
            <BrandLogo surface="dark" show-city-tag />
          </RouterLink>

          <p class="max-w-md text-sm leading-relaxed text-slate-300">
            Built specifically for Pagadian City commuters and licensed Taxicle, TukTuk, and
            e-BaoBao drivers. Know the municipal fare floor upfront, compare live 90-second bids,
            and travel across inclined barangays with verified local operators.
          </p>

          <div class="flex flex-wrap gap-3 text-xs text-slate-300">
            <span
              class="inline-flex items-center gap-1.5 rounded-full bg-white/5 px-3 py-1.5 ring-1 ring-white/10"
            >
              <UiIcon name="map-pin" size-class="h-3.5 w-3.5 text-emerald-400" />
              Poblacion &amp; Santiago Hub, Pagadian City 7016
            </span>
            <span
              class="inline-flex items-center gap-1.5 rounded-full bg-white/5 px-3 py-1.5 ring-1 ring-white/10"
            >
              <UiIcon name="phone" size-class="h-3.5 w-3.5 text-emerald-400" />
              Pagadian CDRRMO: 062-925-0911
            </span>
          </div>

          <StoreBadges audience="passenger" surface="dark" />
        </div>

        <div class="grid gap-8 sm:grid-cols-3 lg:col-span-7">
          <div>
            <h2 class="text-xs font-bold uppercase tracking-wider text-white">Commuters</h2>
            <ul class="mt-4 space-y-2.5 text-sm">
              <li v-for="link in EXPLORE_LINKS" :key="link.label">
                <RouterLink
                  :to="link.to"
                  class="text-slate-300 transition-colors hover:text-emerald-300 focus-visible:outline-emerald-300"
                >
                  {{ link.label }}
                </RouterLink>
              </li>
            </ul>
          </div>

          <div>
            <h2 class="text-xs font-bold uppercase tracking-wider text-white">
              Drivers &amp; Safety
            </h2>
            <ul class="mt-4 space-y-2.5 text-sm">
              <li v-for="link in PARTNER_LINKS" :key="link.label">
                <RouterLink
                  :to="link.to"
                  class="text-slate-300 transition-colors hover:text-emerald-300 focus-visible:outline-emerald-300"
                >
                  {{ link.label }}
                </RouterLink>
              </li>
            </ul>
          </div>

          <div>
            <h2 class="text-xs font-bold uppercase tracking-wider text-white">Platform</h2>
            <ul class="mt-4 space-y-2.5 text-sm">
              <li v-for="link in PLATFORM_LINKS" :key="link.label">
                <RouterLink
                  :to="link.to"
                  class="text-slate-300 transition-colors hover:text-emerald-300 focus-visible:outline-emerald-300"
                >
                  {{ link.label }}
                </RouterLink>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <div
        class="mt-12 flex flex-col gap-3 border-t border-slate-800/90 pt-6 text-xs text-slate-400 sm:flex-row sm:items-center sm:justify-between"
      >
        <p>
          EasyRide Mobility · Pagadian City, Zamboanga del Sur · Tariff preview &amp; static mock
          showcase
        </p>
        <div class="flex flex-wrap items-center gap-4">
          <span class="tabular-nums text-slate-300">Currency: PHP (&#8369;)</span>
          <span class="inline-flex items-center gap-1.5 text-emerald-300">
            <span class="h-2 w-2 rounded-full bg-emerald-400" aria-hidden="true" />
            Vue Router 5 File-Based Routing
          </span>
        </div>
      </div>
    </div>
  </footer>
</template>
