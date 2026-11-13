<script setup lang="ts">
import { triggerFarePrefill } from '@/features/fare-estimation'
import { FLEET_TIERS } from '@/features/landing-showcase/data/landingContent'
</script>

<template>
  <section id="rides" class="bg-white py-14 sm:py-20">
    <div class="mx-auto max-w-6xl px-4 sm:px-6">
      <div class="flex flex-col justify-between gap-2 sm:flex-row sm:items-end">
        <h2 class="text-2xl font-bold tracking-tight text-neutral-900 sm:text-3xl">Our Rides</h2>
        <p class="text-sm text-neutral-500">Three Taxicle tiers priced in PHP.</p>
      </div>

      <div class="mt-8 grid gap-5 md:grid-cols-3">
        <article
          v-for="tier in FLEET_TIERS"
          :key="tier.id"
          class="flex flex-col justify-between border border-neutral-200 bg-white p-6"
        >
          <div>
            <div class="flex items-baseline justify-between gap-2">
              <h3 class="text-lg font-bold text-neutral-900">{{ tier.name }}</h3>
              <span class="text-sm font-semibold tabular-nums text-neutral-900">
                {{ tier.priceLabel }}
              </span>
            </div>
            <p class="mt-2 text-sm leading-relaxed text-neutral-600">{{ tier.description }}</p>
          </div>

          <button
            type="button"
            class="mt-6 w-fit text-xs font-semibold text-neutral-700 hover:text-neutral-900"
            @click="triggerFarePrefill({ rideTier: tier.rideTierKey })"
          >
            Check rate &rarr;
          </button>
        </article>
      </div>
    </div>
  </section>
</template>
