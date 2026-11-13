<script setup lang="ts">
import { computed, ref } from 'vue'
import { BIDDING_MOCK_BIDS, BIDDING_STEPS } from '@/features/landing-showcase/data/landingContent'
import UiIcon from '@/shared/components/UiIcon.vue'

type BidSortMode = 'price' | 'eta'

const activeStepIndex = ref(1)
const selectedBidId = ref<string>(BIDDING_MOCK_BIDS[0]?.id ?? 'bid-danilo')
const sortMode = ref<BidSortMode>('price')

const currentStep = computed(() => {
  return BIDDING_STEPS[activeStepIndex.value] ?? BIDDING_STEPS[0]
})

const sortedBids = computed(() => {
  const list = [...BIDDING_MOCK_BIDS]
  return list.sort((firstBid, secondBid) =>
    sortMode.value === 'price'
      ? firstBid.bidPhp - secondBid.bidPhp
      : firstBid.etaMinutes - secondBid.etaMinutes,
  )
})

const selectedBid = computed(() => {
  return (
    BIDDING_MOCK_BIDS.find((candidateBid) => candidateBid.id === selectedBidId.value) ??
    BIDDING_MOCK_BIDS[0]
  )
})
</script>

<template>
  <section
    id="bidding-flow"
    class="relative overflow-hidden bg-[#090d16] py-16 text-white sm:py-24"
  >
    <div
      class="pointer-events-none absolute right-0 top-0 h-96 w-96 rounded-full bg-emerald-500/10 blur-3xl"
      aria-hidden="true"
    />

    <div class="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="grid items-center gap-12 lg:grid-cols-12">
        <div class="lg:col-span-6">
          <p class="text-xs font-bold uppercase tracking-wider text-emerald-300">
            How Live Dispatch Works
          </p>
          <h2 class="mt-2 text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
            No curbside haggling. Choose your driver in 90 seconds.
          </h2>
          <p class="mt-3 max-w-xl text-base text-slate-300">
            Street-side price guesswork disappears when both passenger and driver see the municipal
            floor, verified unit badge, and exact arrival ETA.
          </p>

          <div role="tablist" aria-label="Bidding workflow steps" class="mt-8 space-y-3">
            <button
              v-for="(step, stepIndex) in BIDDING_STEPS"
              :key="step.number"
              type="button"
              role="tab"
              :aria-selected="activeStepIndex === stepIndex"
              class="w-full rounded-2xl border p-4 text-left transition-all focus-visible:outline-emerald-300 sm:p-5"
              :class="
                activeStepIndex === stepIndex
                  ? 'border-emerald-400/70 bg-white/10 shadow-lg shadow-emerald-950/30'
                  : 'border-white/10 bg-white/5 hover:border-white/20 hover:bg-white/[0.07]'
              "
              @click="activeStepIndex = stepIndex"
            >
              <div class="flex items-start gap-4">
                <span
                  class="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-xs font-extrabold tabular-nums"
                  :class="
                    activeStepIndex === stepIndex
                      ? 'bg-emerald-500 text-[#090d16]'
                      : 'bg-white/10 text-slate-300'
                  "
                >
                  {{ step.number }}
                </span>

                <div class="min-w-0 flex-1">
                  <p class="text-xs font-semibold uppercase tracking-wider text-emerald-300">
                    {{ step.subtitle }}
                  </p>
                  <h3 class="mt-0.5 text-base font-bold text-white sm:text-lg">
                    {{ step.title }}
                  </h3>
                  <p
                    v-if="activeStepIndex === stepIndex"
                    class="mt-2 text-sm leading-relaxed text-slate-300"
                  >
                    {{ step.description }}
                  </p>
                </div>
              </div>
            </button>
          </div>
        </div>

        <div class="lg:col-span-6">
          <div
            class="mx-auto max-w-md rounded-[2.25rem] border border-white/15 bg-slate-900/95 p-3.5 shadow-2xl"
          >
            <div
              class="mb-2.5 flex items-center justify-between px-4 pt-1 text-[11px] font-semibold text-slate-400"
            >
              <span class="tabular-nums">9:41</span>
              <span class="h-1.5 w-16 rounded-full bg-slate-700" aria-hidden="true" />
              <span>Pagadian 4G</span>
            </div>

            <div class="rounded-[1.75rem] bg-white p-5 text-[#090d16]">
              <div class="flex items-center justify-between border-b border-slate-100 pb-3">
                <div>
                  <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-700">
                    EasyRide Passenger View
                  </p>
                  <p class="text-sm font-extrabold text-[#090d16]">
                    {{ currentStep?.badgeText }}
                  </p>
                </div>
                <span
                  class="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-bold tabular-nums text-emerald-800"
                >
                  <UiIcon name="clock" size-class="h-3.5 w-3.5" />
                  <span v-if="activeStepIndex === 1">01:14</span>
                  <span v-else-if="activeStepIndex === 0">Floor Ready</span>
                  <span v-else>Matched</span>
                </span>
              </div>

              <div v-if="activeStepIndex === 0" class="mt-4 space-y-4">
                <div class="rounded-2xl bg-slate-50 p-3.5 ring-1 ring-slate-200/80">
                  <div class="flex items-center gap-2.5 text-xs font-semibold text-slate-700">
                    <span class="h-2.5 w-2.5 rounded-full bg-emerald-600" aria-hidden="true" />
                    Agora Public Market, Poblacion
                  </div>
                  <div class="my-2 ml-1 h-4 w-px bg-slate-300" aria-hidden="true" />
                  <div class="flex items-center gap-2.5 text-xs font-semibold text-slate-700">
                    <span class="h-2.5 w-2.5 rounded-full bg-amber-500" aria-hidden="true" />
                    Dao Provincial Capitol &amp; Hospital
                  </div>
                </div>

                <div class="rounded-2xl bg-emerald-50 p-4 ring-1 ring-emerald-200">
                  <div class="flex items-baseline justify-between">
                    <span class="text-xs font-bold uppercase tracking-wider text-emerald-800">
                      Upfront Fare Floor
                    </span>
                    <span class="text-2xl font-extrabold tabular-nums text-[#090d16]"
                      >&#8369;54</span
                    >
                  </div>
                  <p class="mt-1 text-xs text-slate-700">
                    3.4 km uphill corridor · Surge capped at 2.0x · Cash on drop-off
                  </p>
                </div>

                <button
                  type="button"
                  class="inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-xl bg-emerald-700 px-4 py-2.5 text-sm font-bold text-white transition-colors hover:bg-emerald-800"
                  @click="activeStepIndex = 1"
                >
                  <span>Request Live Driver Bids</span>
                  <UiIcon name="arrow-right" size-class="h-4 w-4" />
                </button>
              </div>

              <div v-else-if="activeStepIndex === 1" class="mt-4 space-y-3">
                <div>
                  <div class="h-1.5 w-full overflow-hidden rounded-full bg-slate-100">
                    <div class="h-full w-4/5 rounded-full bg-emerald-600" />
                  </div>
                  <div class="mt-2.5 flex items-center justify-between gap-2">
                    <p class="text-xs font-semibold text-slate-600">Sort bids:</p>
                    <div class="inline-flex rounded-full bg-slate-100 p-0.5 text-[11px] font-bold">
                      <button
                        type="button"
                        class="rounded-full px-2.5 py-1 transition-colors"
                        :class="
                          sortMode === 'price'
                            ? 'bg-white text-[#090d16] shadow-2xs'
                            : 'text-slate-600'
                        "
                        @click="sortMode = 'price'"
                      >
                        Lowest &#8369;
                      </button>
                      <button
                        type="button"
                        class="rounded-full px-2.5 py-1 transition-colors"
                        :class="
                          sortMode === 'eta'
                            ? 'bg-white text-[#090d16] shadow-2xs'
                            : 'text-slate-600'
                        "
                        @click="sortMode = 'eta'"
                      >
                        Fastest ETA
                      </button>
                    </div>
                  </div>
                </div>

                <button
                  v-for="bid in sortedBids"
                  :key="bid.id"
                  type="button"
                  class="flex w-full items-center justify-between gap-3 rounded-2xl border p-3.5 text-left transition-all"
                  :class="
                    selectedBidId === bid.id
                      ? 'border-emerald-600 bg-emerald-50/75 ring-1 ring-emerald-600/20'
                      : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'
                  "
                  @click="selectedBidId = bid.id"
                >
                  <div class="min-w-0">
                    <div class="flex flex-wrap items-center gap-1.5">
                      <span class="text-sm font-extrabold text-[#090d16]">{{
                        bid.driverName
                      }}</span>
                      <span
                        class="inline-flex items-center gap-0.5 rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-bold text-amber-800"
                      >
                        <UiIcon name="star" size-class="h-3 w-3 text-amber-500" />
                        {{ bid.rating }}
                      </span>
                      <span
                        class="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-700"
                      >
                        {{ bid.todaCode }}
                      </span>
                    </div>
                    <p class="mt-1 text-xs text-slate-600">
                      {{ bid.unitModel }} · Plate {{ bid.plateCode }} · {{ bid.etaMinutes }} min
                      away
                    </p>
                  </div>

                  <div class="shrink-0 text-right">
                    <p class="text-lg font-extrabold tabular-nums text-emerald-800">
                      &#8369;{{ bid.bidPhp }}
                    </p>
                    <p class="text-[11px] font-semibold text-slate-500">{{ bid.tierLabel }}</p>
                  </div>
                </button>

                <button
                  type="button"
                  class="mt-1 inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-xl bg-[#090d16] px-4 py-2.5 text-sm font-bold text-white transition-colors hover:bg-slate-800"
                  @click="activeStepIndex = 2"
                >
                  <span
                    >Accept {{ selectedBid?.driverName }} for &#8369;{{ selectedBid?.bidPhp }}</span
                  >
                  <UiIcon name="check" size-class="h-4 w-4 text-emerald-400" />
                </button>
              </div>

              <div v-else class="mt-4 space-y-4">
                <div class="rounded-2xl border border-emerald-200 bg-emerald-50 p-4">
                  <div class="flex items-center justify-between">
                    <span class="text-xs font-bold uppercase tracking-wider text-emerald-800">
                      Driver En Route
                    </span>
                    <span
                      class="rounded-full bg-emerald-700 px-2.5 py-0.5 text-xs font-bold text-white"
                    >
                      ETA {{ selectedBid?.etaMinutes }} min
                    </span>
                  </div>
                  <p class="mt-2 text-lg font-extrabold text-[#090d16]">
                    {{ selectedBid?.driverName }} · {{ selectedBid?.unitModel }}
                  </p>
                  <p class="mt-0.5 text-xs font-semibold text-slate-700">
                    Plate {{ selectedBid?.plateCode }} · TODA {{ selectedBid?.todaCode }} · Locked
                    &#8369;{{ selectedBid?.bidPhp }} cash
                  </p>

                  <div
                    class="mt-3 flex items-center gap-2 rounded-xl bg-white px-3 py-2 text-[11px] font-semibold text-slate-700 ring-1 ring-emerald-200"
                  >
                    <span class="h-2 w-2 rounded-full bg-emerald-600" aria-hidden="true" />
                    <span class="truncate">Agora Market &#8594; Dao Capitol</span>
                    <span class="ml-auto shrink-0 text-emerald-800">GPS Live</span>
                  </div>
                </div>

                <div class="grid grid-cols-2 gap-2.5 text-xs font-bold">
                  <div
                    class="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-slate-800"
                  >
                    <UiIcon name="navigation" size-class="h-4 w-4 text-emerald-700" />
                    Share Live GPS Link
                  </div>
                  <div
                    class="flex items-center gap-2 rounded-xl border border-rose-200 bg-rose-50 px-3 py-2.5 text-rose-800"
                  >
                    <UiIcon name="alert" size-class="h-4 w-4 text-rose-700" />
                    One-Tap SOS Ready
                  </div>
                </div>

                <button
                  type="button"
                  class="inline-flex min-h-10 w-full items-center justify-center rounded-xl border border-slate-200 bg-white px-4 py-2 text-xs font-bold text-slate-700 hover:bg-slate-50"
                  @click="activeStepIndex = 0"
                >
                  Replay Bidding Walkthrough
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
