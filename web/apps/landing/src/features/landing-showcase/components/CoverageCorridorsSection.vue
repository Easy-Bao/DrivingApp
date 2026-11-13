<script setup lang="ts">
import { computed, ref } from 'vue'
import { triggerFarePrefill } from '@/features/fare-estimation'
import { PAGADIAN_ZONES } from '@/features/landing-showcase/data/landingContent'
import UiIcon from '@/shared/components/UiIcon.vue'

const selectedZoneId = ref<string>(PAGADIAN_ZONES[0]?.id ?? 'poblacion-agora')

const activeZone = computed(() => {
  return PAGADIAN_ZONES.find((zone) => zone.id === selectedZoneId.value) ?? PAGADIAN_ZONES[0]
})

const highlightedCorridorPath = computed(() => {
  const target = activeZone.value?.svgCoords ?? { x: 276, y: 211 }
  if (target.x === 276 && target.y === 211) {
    return 'M218 206 Q276 184 334 206'
  }
  const controlX = Math.round((276 + target.x) / 2)
  const controlY = Math.min(211, target.y) - 24
  return `M276 211 Q${controlX} ${controlY} ${target.x} ${target.y}`
})

const prefillActiveZoneRoute = () => {
  const zone = activeZone.value
  if (!zone) {
    return
  }
  triggerFarePrefill({
    pickupLocation: zone.recommendedRoute.pickup,
    destinationLocation: zone.recommendedRoute.destination,
    rideTier: zone.recommendedRoute.tier,
  })
}
</script>

<template>
  <section id="coverage" class="border-y border-slate-200/80 bg-slate-50 py-16 sm:py-24">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="max-w-2xl">
        <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
          Pagadian City Service Coverage
        </p>
        <h2 class="mt-2 text-3xl font-extrabold tracking-tight text-[#090d16] sm:text-4xl">
          Built for inclined hills, coastal piers, and busy barangays
        </h2>
        <p class="mt-3 text-base text-slate-600">
          Inspect how EasyRide stages licensed TODA units across Pagadian City 7016 — from flat
          Agora Market streets to steep Dao Capitol climbs.
        </p>
      </div>

      <div class="mt-10 grid items-start gap-8 lg:grid-cols-12">
        <div
          class="space-y-3 lg:col-span-5"
          role="tablist"
          aria-label="Pagadian coverage corridors"
        >
          <button
            v-for="zone in PAGADIAN_ZONES"
            :key="zone.id"
            type="button"
            role="tab"
            :aria-selected="selectedZoneId === zone.id"
            class="w-full rounded-2xl border p-4 text-left transition-all"
            :class="
              selectedZoneId === zone.id
                ? 'border-emerald-600 bg-white shadow-md ring-1 ring-emerald-600/20'
                : 'border-slate-200 bg-white/75 hover:border-slate-300 hover:bg-white'
            "
            @click="selectedZoneId = zone.id"
          >
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
                  {{ zone.corridorType }}
                </p>
                <h3 class="mt-0.5 text-base font-extrabold text-[#090d16]">{{ zone.name }}</h3>
              </div>
              <span
                class="shrink-0 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-bold tabular-nums text-emerald-800"
              >
                {{ zone.typicalWait }}
              </span>
            </div>
            <p class="mt-2 text-xs text-slate-600">
              Flag-down &#8369;{{ zone.baseFlagDownPhp }} · Typical hop {{ zone.sampleFarePhp }}
            </p>
          </button>
        </div>

        <div class="lg:col-span-7">
          <div class="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
            <div
              class="relative h-72 w-full bg-linear-to-b from-slate-100 via-emerald-50/35 to-sky-50 sm:h-80"
            >
              <div
                class="pointer-events-none absolute left-4 top-4 z-10 inline-flex items-center gap-1.5 rounded-full bg-white/90 px-3 py-1 text-[11px] font-bold text-slate-700 shadow-2xs ring-1 ring-slate-200"
              >
                <UiIcon name="compass" size-class="h-3.5 w-3.5 text-emerald-700" />
                Pagadian Crescent · North
              </div>

              <svg
                class="h-full w-full"
                viewBox="0 0 600 320"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
              >
                <path
                  d="M0 78 Q160 40 310 58 T600 66"
                  stroke="#CBD5E1"
                  stroke-width="1"
                  stroke-dasharray="4 4"
                />
                <path
                  d="M0 135 Q180 98 330 112 T600 118"
                  stroke="#CBD5E1"
                  stroke-width="1"
                  stroke-dasharray="4 4"
                />

                <path
                  d="M108 144 Q215 110 252 83 Q375 95 480 122"
                  stroke="#94A3B8"
                  stroke-width="2.5"
                  stroke-linecap="round"
                />
                <path
                  d="M108 144 Q195 198 276 211 Q395 198 480 122"
                  stroke="#CBD5E1"
                  stroke-width="3"
                  stroke-linecap="round"
                />

                <path
                  :d="highlightedCorridorPath"
                  stroke="#059669"
                  stroke-width="4"
                  stroke-dasharray="7 5"
                  stroke-linecap="round"
                />

                <path d="M0 245 Q160 228 290 250 T600 232 L600 320 L0 320 Z" fill="#E0F2FE" />
                <path d="M0 245 Q160 228 290 250 T600 232" stroke="#7DD3FC" stroke-width="2" />
                <text
                  x="295"
                  y="292"
                  text-anchor="middle"
                  fill="#0369A1"
                  font-size="11"
                  font-weight="700"
                  letter-spacing="2"
                >
                  ILLANA BAY COASTLINE
                </text>
              </svg>

              <button
                v-for="zone in PAGADIAN_ZONES"
                :key="`pin-${zone.id}`"
                type="button"
                class="absolute -translate-x-1/2 -translate-y-1/2 rounded-full px-3 py-1.5 text-xs font-bold shadow-md transition-all"
                :style="{ left: `${zone.mapCoords.x}%`, top: `${zone.mapCoords.y}%` }"
                :class="
                  selectedZoneId === zone.id
                    ? 'scale-105 bg-emerald-700 text-white ring-4 ring-emerald-500/30'
                    : 'border border-slate-300 bg-white text-[#090d16] hover:border-emerald-500 hover:bg-emerald-50'
                "
                @click="selectedZoneId = zone.id"
              >
                <span
                  v-if="selectedZoneId === zone.id"
                  class="pointer-events-none absolute inset-0 rounded-full bg-emerald-500/30 motion-safe:animate-ping"
                  aria-hidden="true"
                />
                <span class="relative">{{ zone.shortLabel }}</span>
              </button>
            </div>

            <div v-if="activeZone" class="border-t border-slate-200 p-6">
              <div class="flex flex-wrap items-start justify-between gap-4">
                <div>
                  <span class="text-xs font-bold uppercase tracking-wider text-emerald-700">
                    Active Zone Snapshot
                  </span>
                  <h3 class="mt-0.5 text-xl font-extrabold text-[#090d16]">
                    {{ activeZone.name }}
                  </h3>
                  <p class="mt-1 text-sm text-slate-600">{{ activeZone.elevationNote }}</p>
                </div>

                <div
                  class="rounded-2xl bg-emerald-50 px-4 py-2.5 text-right ring-1 ring-emerald-200"
                >
                  <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-800">
                    Typical Trip Range
                  </p>
                  <p class="text-lg font-extrabold tabular-nums text-[#090d16]">
                    {{ activeZone.sampleFarePhp }}
                  </p>
                </div>
              </div>

              <div class="mt-5">
                <p class="text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Frequent Pickup &amp; Drop-off Landmarks
                </p>
                <div class="mt-2 flex flex-wrap gap-2">
                  <span
                    v-for="landmark in activeZone.landmarks"
                    :key="landmark"
                    class="inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-800"
                  >
                    <UiIcon name="map-pin" size-class="h-3.5 w-3.5 text-emerald-700" />
                    {{ landmark }}
                  </span>
                </div>
              </div>

              <div
                class="mt-5 flex flex-wrap items-center justify-between gap-3 border-t border-slate-100 pt-4"
              >
                <span class="text-xs font-medium text-slate-600">
                  Avg pickup dispatch ETA:
                  <strong class="text-[#090d16]">{{ activeZone.typicalWait }}</strong>
                </span>
                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-3.5 py-1.5 text-xs font-bold text-emerald-800 ring-1 ring-emerald-200 transition-colors hover:bg-emerald-100"
                  @click="prefillActiveZoneRoute"
                >
                  <span>Prefill this corridor in calculator</span>
                  <UiIcon name="arrow-right" size-class="h-3.5 w-3.5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
