<script setup lang="ts">
import { ref } from 'vue'
import ReportFilterBar from '@/features/reports/components/ReportFilterBar.vue'

const expiryForecast = ref([
  {
    month: 'November 2026',
    cdlExpiring: 14,
    insuranceExpiring: 28,
    inspectionExpiring: 32,
    totalFleetRisk: 74,
    complianceRate: '98.1%',
  },
  {
    month: 'December 2026',
    cdlExpiring: 18,
    insuranceExpiring: 35,
    inspectionExpiring: 41,
    totalFleetRisk: 94,
    complianceRate: '97.5%',
  },
  {
    month: 'January 2027',
    cdlExpiring: 11,
    insuranceExpiring: 22,
    inspectionExpiring: 29,
    totalFleetRisk: 62,
    complianceRate: '98.8%',
  },
  {
    month: 'February 2027',
    cdlExpiring: 9,
    insuranceExpiring: 19,
    inspectionExpiring: 24,
    totalFleetRisk: 52,
    complianceRate: '99.2%',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Fleet Document Expiry & Compliance Forecast
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Quarterly projection of upcoming driver license, motor vehicle insurance, and roadworthiness
        certificate renewals.
      </p>
    </div>

    <ReportFilterBar report-title="Document Expiry & Compliance Forecast" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Document Renewal Projections</h2>
        <span class="text-xs text-neutral-400"
          >Automated warning sequence triggers 30 days prior</span
        >
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Forecast Month</th>
            <th class="py-3 px-4">Driver Licenses Expiring</th>
            <th class="py-3 px-4">Insurance Policies Expiring</th>
            <th class="py-3 px-4">Vehicle Inspections Expiring</th>
            <th class="py-3 px-4">Total Compliance Audits</th>
            <th class="py-3 px-4 text-right">Projected Fleet Compliance</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="f in expiryForecast"
            :key="f.month"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-bold text-neutral-900">{{ f.month }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-800">{{ f.cdlExpiring }} licenses</td>
            <td class="py-3 px-4 font-semibold text-neutral-800">
              {{ f.insuranceExpiring }} policies
            </td>
            <td class="py-3 px-4 font-semibold text-neutral-800">
              {{ f.inspectionExpiring }} inspections
            </td>
            <td class="py-3 px-4 font-bold text-amber-700">{{ f.totalFleetRisk }}</td>
            <td class="py-3 px-4 text-right font-mono font-bold text-emerald-600">
              {{ f.complianceRate }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
