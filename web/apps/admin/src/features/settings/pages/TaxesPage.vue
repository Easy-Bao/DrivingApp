<script setup lang="ts">
import { ref } from 'vue'

const taxRules = ref([
  {
    id: 'TAX-01',
    name: 'Municipal Transportation Excise Tax',
    jurisdiction: 'Metro Central City Council',
    rateType: 'Percentage (3.5%)',
    appliedTo: 'Gross Trip Fare',
    isIncludedInFare: true,
    status: 'Enforced',
  },
  {
    id: 'TAX-02',
    name: 'Clean Air Clean Transportation Fund',
    jurisdiction: 'State Environmental Agency',
    rateType: 'Flat Fee (₱0.75 / trip)',
    appliedTo: 'Internal Combustion Vehicles Only (Waived for EVs)',
    isIncludedInFare: true,
    status: 'Enforced',
  },
  {
    id: 'TAX-03',
    name: 'Airport Ground Access Regulatory Fee',
    jurisdiction: 'Airport Authority Terminal Commission',
    rateType: 'Flat Fee (₱4.00 / trip)',
    appliedTo: 'Pickups & Dropoffs inside Airport Polygon',
    isIncludedInFare: true,
    status: 'Enforced',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Municipal & Environmental Tax Rules
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Configure statutory municipal fees, airport passenger surcharges, and green fleet tax
          exemptions.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors flex items-center space-x-2"
      >
        <span>Add Statutory Tax Rule</span>
      </button>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Enforced Regional Tax Policies</h2>
        <span class="text-xs text-neutral-400">Deducted and held for statutory remittance</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Tax ID</th>
            <th class="py-3 px-4">Tax Rule Name</th>
            <th class="py-3 px-4">Levying Authority</th>
            <th class="py-3 px-4">Rate & Mechanism</th>
            <th class="py-3 px-4">Trigger Condition</th>
            <th class="py-3 px-4 text-right">Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr v-for="t in taxRules" :key="t.id" class="hover:bg-neutral-50/70 transition-colors">
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ t.id }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ t.name }}</td>
            <td class="py-3 px-4 text-neutral-600">{{ t.jurisdiction }}</td>
            <td class="py-3 px-4 font-bold text-neutral-800">{{ t.rateType }}</td>
            <td class="py-3 px-4 text-neutral-500 text-[11px] max-w-xs">{{ t.appliedTo }}</td>
            <td class="py-3 px-4 text-right">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 text-emerald-800"
              >
                {{ t.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
