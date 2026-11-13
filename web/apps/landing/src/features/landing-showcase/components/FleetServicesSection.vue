<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { triggerFarePrefill } from '@/features/fare-estimation'
import {
  FLEET_SERVICES,
  type FleetServiceItem,
} from '@/features/landing-showcase/data/landingContent'
import UiIcon from '@/shared/components/UiIcon.vue'

const selectedServiceId = ref<string>(FLEET_SERVICES[0]?.id ?? 'taxicle-standard')

const previewTierInCalculator = (service: FleetServiceItem) => {
  selectedServiceId.value = service.id
  triggerFarePrefill({
    rideTier: service.rideTierKey,
  })
}
</script>

<template>
  <section id="fleet" class="bg-white py-16 sm:py-24">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div class="max-w-2xl">
          <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
            Pagadian Mobility Suite
          </p>
          <h2 class="mt-2 text-3xl font-extrabold tracking-tight text-[#090d16] sm:text-4xl">
            Four three-wheel tiers matched to Pagadian terrain
          </h2>
          <p class="mt-3 text-base text-slate-600">
            From tight market loops around Agora to steep inclines climbing up Dao Capitol and quiet
            rainy-day e-BaoBao commutes.
          </p>
        </div>

        <RouterLink
          to="/download"
          class="inline-flex min-h-10 shrink-0 items-center gap-1.5 self-start rounded-full border border-slate-200 bg-slate-50 px-4 py-2 text-sm font-bold text-[#090d16] transition-colors hover:border-emerald-300 hover:bg-emerald-50"
        >
          <span>Compare tiers in app</span>
          <UiIcon name="arrow-up-right" size-class="h-4 w-4 text-emerald-700" />
        </RouterLink>
      </div>

      <div class="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <article
          v-for="service in FLEET_SERVICES"
          :key="service.id"
          class="group flex flex-col justify-between rounded-3xl border p-6 transition-all motion-safe:hover:-translate-y-0.5"
          :class="
            selectedServiceId === service.id
              ? 'border-emerald-500 bg-emerald-50/40 shadow-md shadow-emerald-900/5'
              : 'border-slate-200 bg-white hover:border-slate-300 hover:shadow-sm'
          "
        >
          <div>
            <div class="flex items-start justify-between gap-3">
              <span
                class="inline-flex h-12 w-12 items-center justify-center rounded-2xl ring-1 ring-inset"
                :class="service.accentClass"
              >
                <UiIcon :name="service.icon" size-class="h-6 w-6" />
              </span>

              <span
                class="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold tabular-nums text-[#090d16]"
              >
                {{ service.flagDownLabel }}
              </span>
            </div>

            <h3 class="mt-5 text-lg font-extrabold tracking-tight text-[#090d16]">
              {{ service.name }}
            </h3>
            <p class="mt-1 text-sm font-medium text-slate-600">{{ service.tagline }}</p>

            <div class="mt-4 rounded-2xl border border-slate-200/80 bg-white px-3.5 py-2.5">
              <p class="text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                Typical Unit &amp; Tariff
              </p>
              <p class="mt-0.5 text-xs font-bold text-[#090d16]">{{ service.vehicleSpec }}</p>
              <p class="mt-0.5 text-xs font-semibold tabular-nums text-emerald-800">
                {{ service.rateLabel }}
              </p>
            </div>

            <p
              class="mt-3 inline-flex rounded-lg bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-700"
            >
              {{ service.capacitySpec }}
            </p>

            <ul class="mt-4 space-y-2 text-xs text-slate-700">
              <li v-for="point in service.highlights" :key="point" class="flex items-start gap-2">
                <UiIcon name="check-circle" size-class="mt-0.5 h-4 w-4 text-emerald-700" />
                <span>{{ point }}</span>
              </li>
            </ul>
          </div>

          <div class="mt-6 flex items-center justify-between border-t border-slate-200/70 pt-4">
            <button
              type="button"
              class="text-xs font-bold text-emerald-800 transition-colors hover:text-emerald-950"
              @click="selectedServiceId = service.id"
            >
              {{ selectedServiceId === service.id ? 'Active tier card' : 'Highlight tier' }}
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-1 text-xs font-bold text-[#090d16] transition-colors hover:text-emerald-700"
              @click="previewTierInCalculator(service)"
            >
              <span>Load in calculator</span>
              <UiIcon name="arrow-right" size-class="h-3.5 w-3.5" />
            </button>
          </div>
        </article>
      </div>
    </div>
  </section>
</template>
