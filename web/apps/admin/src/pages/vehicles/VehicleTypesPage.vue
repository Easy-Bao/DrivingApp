<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const vehicleTiers = ref([
  {
    id: 'TIER-ECO',
    name: 'Economy',
    capacity: 4,
    baseFare: '$3.50',
    perKm: '$1.25',
    perMin: '$0.25',
    minFare: '$5.00',
    cancellationFee: '$3.00',
    icon: 'lucide:car',
    status: 'Active',
    description: 'Affordable everyday rides for up to 4 passengers with compact or sedan cars.',
  },
  {
    id: 'TIER-COMF',
    name: 'Comfort',
    capacity: 4,
    baseFare: '$5.00',
    perKm: '$1.75',
    perMin: '$0.35',
    minFare: '$7.50',
    cancellationFee: '$5.00',
    icon: 'lucide:sparkles',
    status: 'Active',
    description: 'Newer vehicles with extra legroom and top-rated drivers.',
  },
  {
    id: 'TIER-XL',
    name: 'XL Family',
    capacity: 6,
    baseFare: '$7.50',
    perKm: '$2.40',
    perMin: '$0.45',
    minFare: '$10.00',
    cancellationFee: '$7.00',
    icon: 'lucide:truck',
    status: 'Active',
    description: 'Spacious SUVs and minivans for groups up to 6 passengers with luggage.',
  },
  {
    id: 'TIER-EXEC',
    name: 'Executive Black',
    capacity: 4,
    baseFare: '$12.00',
    perKm: '$3.50',
    perMin: '$0.75',
    minFare: '$20.00',
    cancellationFee: '$10.00',
    icon: 'lucide:crown',
    status: 'Active',
    description: 'High-end luxury sedans driven by commercially licensed chauffeurs.',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Vehicle Types & Service Classes
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Define passenger fare structures, vehicle seating requirements, and dispatch priorities.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-lg text-xs font-semibold transition-colors flex items-center space-x-2"
      >
        <Icon icon="lucide:plus" />
        <span>Add Vehicle Type</span>
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="tier in vehicleTiers"
        :key="tier.id"
        class="bg-white border border-neutral-200 rounded-xl p-5 shadow-2xs hover:border-neutral-300 transition-all flex flex-col justify-between"
      >
        <div>
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center space-x-3">
              <div
                class="w-10 h-10 rounded-lg bg-neutral-100 flex items-center justify-center text-neutral-900"
              >
                <Icon :icon="tier.icon" class="text-xl" />
              </div>
              <div>
                <h3 class="font-bold text-base text-neutral-900">{{ tier.name }}</h3>
                <span class="text-[11px] text-neutral-400 font-mono">{{ tier.id }}</span>
              </div>
            </div>
            <span
              class="px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-100 text-emerald-800"
            >
              {{ tier.status }}
            </span>
          </div>
          <p class="text-xs text-neutral-500 mb-4">{{ tier.description }}</p>

          <div class="grid grid-cols-3 gap-2 py-3 border-y border-neutral-100 text-center">
            <div>
              <div class="text-[10px] uppercase font-semibold text-neutral-400">Base Fare</div>
              <div class="text-sm font-bold text-neutral-900 mt-0.5">{{ tier.baseFare }}</div>
            </div>
            <div>
              <div class="text-[10px] uppercase font-semibold text-neutral-400">Rate / Km</div>
              <div class="text-sm font-bold text-neutral-900 mt-0.5">{{ tier.perKm }}</div>
            </div>
            <div>
              <div class="text-[10px] uppercase font-semibold text-neutral-400">Rate / Min</div>
              <div class="text-sm font-bold text-neutral-900 mt-0.5">{{ tier.perMin }}</div>
            </div>
          </div>
        </div>

        <div class="mt-4 pt-2 flex items-center justify-between text-xs text-neutral-500">
          <div class="flex items-center space-x-1">
            <Icon icon="lucide:users" class="text-neutral-400" />
            <span>Max {{ tier.capacity }} Riders</span>
          </div>
          <button type="button" class="text-neutral-900 font-semibold hover:underline">
            Edit Pricing Matrix →
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
