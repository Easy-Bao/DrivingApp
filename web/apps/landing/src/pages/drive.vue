<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { DriverEarningsCalculator } from '@/features/landing-showcase'
import { COMMISSION_TIERS } from '@/features/landing-showcase/data/landingContent'
import StoreBadges from '@/shared/components/StoreBadges.vue'
import UiIcon from '@/shared/components/UiIcon.vue'
import LandingLayout from '@/shared/layouts/LandingLayout.vue'

interface RequirementDoc {
  stepNumber: string
  title: string
  detail: string
  requiredFor: string
}

const DRIVER_DOCUMENTS: RequirementDoc[] = [
  {
    stepNumber: '01',
    title: 'LTO Professional Driver License',
    detail: 'Valid restriction code for 3-wheeled motorized tricycles / public utility units.',
    requiredFor: 'Identity & license check',
  },
  {
    stepNumber: '02',
    title: 'Pagadian Municipal MTOP & TODA Endorsement',
    detail: 'Active Mayor’s Tricycle Operator’s Permit body number and barangay TODA clearance.',
    requiredFor: 'Franchise & zone match',
  },
  {
    stepNumber: '03',
    title: 'LTO OR/CR & Compulsory TPL Insurance',
    detail:
      'Current Official Receipt, Certificate of Registration, and active third-party liability.',
    requiredFor: 'Unit safety & roadworthiness',
  },
  {
    stepNumber: '04',
    title: 'NBI & PNP Police Clearances',
    detail: 'Verified background check before any driver can receive live trip broadcasts.',
    requiredFor: 'Passenger safety gate',
  },
]

const QRPH_STEPS = [
  { step: '1', label: 'Open Driver Wallet' },
  { step: '2', label: 'Generate Company QRPh' },
  { step: '3', label: 'Scan in GCash / Maya / Bank' },
  { step: '4', label: 'Instant ₱50+ Active Status' },
]

const QRPH_BANKS = ['GCash QRPh', 'Maya QRPh', 'BDO InstaPay', 'BPI InstaPay', 'UnionBank']
</script>

<template>
  <LandingLayout>
    <section
      class="border-b border-slate-200 bg-linear-to-b from-emerald-50/80 via-white to-white py-14 sm:py-20"
    >
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="grid items-center gap-10 lg:grid-cols-12">
          <div class="lg:col-span-7">
            <span
              class="inline-flex items-center gap-2 rounded-full border border-emerald-200 bg-white px-3.5 py-1.5 text-xs font-bold text-emerald-800"
            >
              <UiIcon name="trending-up" size-class="h-4 w-4" />
              Pagadian City Driver Partner Program
            </span>

            <h1 class="mt-4 text-4xl font-extrabold tracking-tight text-[#090d16] sm:text-5xl">
              Earn more per Pagadian trip with transparent 10%–15% fees
            </h1>

            <p class="mt-4 max-w-2xl text-base leading-relaxed text-slate-600 sm:text-lg">
              Receive verified trip requests straight from Poblacion markets, Bulatok bus arrivals,
              and uphill Dao passengers. Collect exact cash upon drop-off while keeping a simple
              &#8369;50+ Company QRPh wallet balance.
            </p>

            <div class="mt-7 flex flex-wrap items-center gap-3">
              <a
                href="#requirements"
                class="inline-flex min-h-12 items-center gap-2 rounded-full bg-emerald-700 px-6 py-3 text-sm font-bold text-white shadow-sm transition-colors hover:bg-emerald-800"
              >
                <span>See Onboarding Checklist</span>
                <UiIcon name="arrow-right" size-class="h-4 w-4" />
              </a>
              <StoreBadges audience="driver" surface="light" />
            </div>
          </div>

          <div class="lg:col-span-5">
            <div class="rounded-3xl border border-slate-200 bg-[#090d16] p-6 text-white shadow-xl">
              <p class="text-xs font-bold uppercase tracking-wider text-emerald-300">
                Why Drivers Switch to EasyRide
              </p>
              <ul class="mt-4 space-y-4 text-sm">
                <li class="flex items-start gap-3">
                  <UiIcon name="check-circle" size-class="mt-0.5 h-5 w-5 text-emerald-400" />
                  <span>
                    <strong class="block text-white">No Empty Backhauls</strong>
                    Pick up uphill Dao or Tiguma return passengers directly along your route.
                  </span>
                </li>
                <li class="flex items-start gap-3">
                  <UiIcon name="qr-code" size-class="mt-0.5 h-5 w-5 text-emerald-400" />
                  <span>
                    <strong class="block text-white">Prepaid Company QRPh Control</strong>
                    Top up only what you need from &#8369;50 via GCash or Maya — zero weekly debt.
                  </span>
                </li>
                <li class="flex items-start gap-3">
                  <UiIcon name="bolt" size-class="mt-0.5 h-5 w-5 text-emerald-400" />
                  <span>
                    <strong class="block text-white">Lowest 10% Tier for e-BaoBao</strong>
                    Covered electric tricycle pioneers qualify automatically for a 10% platform fee.
                  </span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="bg-slate-50 py-14 sm:py-20">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <DriverEarningsCalculator />
      </div>
    </section>

    <section id="commission" class="border-y border-slate-200 bg-white py-16 sm:py-20">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="grid gap-10 lg:grid-cols-12">
          <div class="lg:col-span-5">
            <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
              Company QRPh Wallet
            </p>
            <h2 class="mt-2 text-3xl font-extrabold tracking-tight text-[#090d16]">
              Clear commission tiers, zero hidden deductions
            </h2>
            <p class="mt-3 text-sm leading-relaxed text-slate-600 sm:text-base">
              Keep your dispatch balance at or above &#8369;50.00 using any Philippine QRPh-enabled
              bank or e-wallet. Each completed cash trip deducts your tier percentage automatically.
            </p>

            <div class="mt-5 flex flex-wrap gap-2">
              <span
                v-for="bank in QRPH_BANKS"
                :key="bank"
                class="rounded-full border border-emerald-200 bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-900"
              >
                {{ bank }}
              </span>
            </div>
          </div>

          <div class="grid gap-4 sm:grid-cols-3 lg:col-span-7">
            <article
              v-for="tier in COMMISSION_TIERS"
              :key="tier.id"
              class="flex flex-col justify-between rounded-3xl border border-slate-200 bg-slate-50/70 p-5"
            >
              <div>
                <p class="text-xs font-bold uppercase tracking-wider text-slate-500">
                  {{ tier.vehicleFocus }}
                </p>
                <h3 class="mt-1 text-lg font-extrabold text-[#090d16]">{{ tier.tierName }}</h3>
                <p class="mt-3 text-3xl font-extrabold tabular-nums text-emerald-800">
                  {{ tier.ratePercent }}%
                </p>
                <p class="mt-2 text-xs leading-relaxed text-slate-600">{{ tier.eligibility }}</p>
              </div>
              <p
                class="mt-4 border-t border-slate-200 pt-3 text-xs font-semibold tabular-nums text-slate-700"
              >
                Min wallet floor: &#8369;{{ tier.qrphMinimumPhp }}.00
              </p>
            </article>
          </div>
        </div>

        <div
          class="mt-10 grid gap-3 rounded-3xl border border-slate-200 bg-slate-50 p-5 sm:grid-cols-4"
        >
          <div
            v-for="item in QRPH_STEPS"
            :key="item.step"
            class="flex items-center gap-3 rounded-2xl bg-white p-3.5 ring-1 ring-slate-200/80"
          >
            <span
              class="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-emerald-700 text-xs font-extrabold tabular-nums text-white"
            >
              {{ item.step }}
            </span>
            <span class="text-xs font-bold text-[#090d16]">{{ item.label }}</span>
          </div>
        </div>
      </div>
    </section>

    <section id="requirements" class="bg-slate-50 py-16 sm:py-20">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="max-w-2xl">
          <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
            Pagadian Compliance Checklist
          </p>
          <h2 class="mt-2 text-3xl font-extrabold tracking-tight text-[#090d16]">
            Documents required to activate your driver account
          </h2>
          <p class="mt-2 text-base text-slate-600">
            Prepare clear mobile photos of these four sets inside the EasyRide Driver app. Expiry
            alerts notify you automatically ahead of annual renewals.
          </p>
        </div>

        <div class="mt-8 grid gap-4 sm:grid-cols-2">
          <article
            v-for="doc in DRIVER_DOCUMENTS"
            :key="doc.title"
            class="rounded-3xl border border-slate-200 bg-white p-6 shadow-2xs"
          >
            <div class="flex items-center justify-between gap-2">
              <span class="text-[11px] font-bold uppercase tracking-wider text-emerald-700">
                {{ doc.requiredFor }}
              </span>
              <span
                class="rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-extrabold tabular-nums text-emerald-800"
              >
                {{ doc.stepNumber }}
              </span>
            </div>
            <h3 class="mt-2 text-lg font-extrabold text-[#090d16]">{{ doc.title }}</h3>
            <p class="mt-2 text-sm text-slate-600">{{ doc.detail }}</p>
          </article>
        </div>

        <div
          class="mt-10 flex flex-col items-start justify-between gap-4 rounded-3xl bg-[#090d16] p-7 text-white sm:flex-row sm:items-center"
        >
          <div>
            <h3 class="text-xl font-extrabold">Ready to register your Taxicle unit?</h3>
            <p class="mt-1 text-sm text-slate-300">
              Download the Android driver build or inspect our passenger &amp; driver verification
              standards.
            </p>
          </div>
          <div class="flex flex-wrap gap-3">
            <RouterLink
              :to="{ path: '/download', query: { role: 'driver' } }"
              class="inline-flex min-h-11 items-center gap-2 rounded-full bg-emerald-600 px-5 py-2.5 text-sm font-bold text-white transition-colors hover:bg-emerald-500"
            >
              <span>Download Driver App</span>
              <UiIcon name="download" size-class="h-4 w-4" />
            </RouterLink>
            <RouterLink
              to="/safety"
              class="inline-flex min-h-11 items-center rounded-full border border-white/20 px-5 py-2.5 text-sm font-bold text-white hover:bg-white/10"
            >
              Safety Standards
            </RouterLink>
          </div>
        </div>
      </div>
    </section>
  </LandingLayout>
</template>
