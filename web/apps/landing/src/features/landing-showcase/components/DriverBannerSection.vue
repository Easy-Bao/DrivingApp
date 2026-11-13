<script setup lang="ts">
import { RouterLink } from 'vue-router'
import UiIcon from '@/shared/components/UiIcon.vue'
</script>

<template>
  <section class="py-6 sm:py-10">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div
        class="relative overflow-hidden rounded-3xl bg-linear-to-br from-emerald-900 via-emerald-950 to-[#090d16] p-8 text-white shadow-xl sm:p-12"
      >
        <div
          class="pointer-events-none absolute -right-12 -top-12 h-64 w-64 rounded-full bg-emerald-400/15 blur-3xl"
          aria-hidden="true"
        />

        <div class="relative grid items-center gap-8 lg:grid-cols-12">
          <div class="lg:col-span-7">
            <span
              class="inline-flex items-center gap-1.5 rounded-full bg-white/10 px-3 py-1 text-xs font-bold text-emerald-200 ring-1 ring-white/15"
            >
              <UiIcon name="qr-code" size-class="h-3.5 w-3.5" />
              Company QRPh Prepaid Driver Wallet
            </span>

            <h2 class="mt-4 text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
              Keep 85%–90% of every cash fare. Top up anytime via QRPh.
            </h2>

            <p class="mt-3 max-w-2xl text-base leading-relaxed text-emerald-100/90">
              No confusing week-end balance debt. Load your EasyRide driver wallet from &#8369;50
              via GCash, Maya, BDO, or BPI InstaPay QRPh and earn steady uphill and terminal
              dispatches all week.
            </p>

            <div class="mt-7 flex flex-wrap items-center gap-3">
              <RouterLink
                to="/drive"
                class="inline-flex min-h-12 items-center gap-2 rounded-full bg-white px-6 py-3 text-sm font-extrabold text-[#090d16] shadow-sm transition-colors hover:bg-emerald-50"
              >
                <span>Calculate Take-Home &amp; Join</span>
                <UiIcon name="arrow-right" size-class="h-4 w-4 text-emerald-700" />
              </RouterLink>

              <RouterLink
                :to="{ path: '/drive', hash: '#requirements' }"
                class="inline-flex min-h-12 items-center gap-2 rounded-full border border-white/25 bg-white/10 px-5 py-3 text-sm font-bold text-white transition-colors hover:bg-white/15"
              >
                <span>View LTO &amp; TODA Checklist</span>
              </RouterLink>
            </div>
          </div>

          <div class="grid gap-3 sm:grid-cols-3 lg:col-span-5 lg:grid-cols-1">
            <div class="rounded-2xl border border-white/15 bg-white/10 p-4 backdrop-blur-xs">
              <p class="text-xs font-semibold uppercase tracking-wider text-emerald-200">
                Commission Tiers
              </p>
              <p class="mt-1 text-2xl font-extrabold tabular-nums">10% – 15%</p>
              <p class="mt-0.5 text-xs text-emerald-100/80">
                10% e-BaoBao Pioneer · 12% Pro 4.85&#9733;+ · 15% Standard
              </p>
            </div>

            <div class="rounded-2xl border border-white/15 bg-white/10 p-4 backdrop-blur-xs">
              <p class="text-xs font-semibold uppercase tracking-wider text-emerald-200">
                Minimum Wallet Floor
              </p>
              <p class="mt-1 text-2xl font-extrabold tabular-nums">&#8369;50.00</p>
              <p class="mt-0.5 text-xs text-emerald-100/80">
                Keep &#8369;50+ loaded to receive real-time passenger bids
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
