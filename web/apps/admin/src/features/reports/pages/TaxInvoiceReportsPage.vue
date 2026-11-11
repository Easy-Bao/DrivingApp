<script setup lang="ts">
import { ref } from 'vue'
import ReportFilterBar from '@/features/reports/components/ReportFilterBar.vue'

const taxInvoices = ref([
  {
    invoiceId: 'INV-2026-10',
    jurisdiction: 'State Dept of Revenue',
    taxType: 'Ride-Hailing Transportation Excise Tax (3.5%)',
    taxableBase: '₱2,840,190.00',
    taxDue: '₱99,406.65',
    status: 'Filed & Paid',
  },
  {
    invoiceId: 'INV-2026-09',
    jurisdiction: 'State Dept of Revenue',
    taxType: 'Ride-Hailing Transportation Excise Tax (3.5%)',
    taxableBase: '₱2,610,400.00',
    taxDue: '₱91,364.00',
    status: 'Filed & Paid',
  },
  {
    invoiceId: 'INV-2026-08',
    jurisdiction: 'State Dept of Revenue',
    taxType: 'Ride-Hailing Transportation Excise Tax (3.5%)',
    taxableBase: '₱2,450,800.00',
    taxDue: '₱85,778.00',
    status: 'Filed & Paid',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Tax & Regulatory Invoicing Reports
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Municipal transportation excise taxes, government regulatory compliance filings, and audited
        tax invoices.
      </p>
    </div>

    <ReportFilterBar report-title="Tax & Regulatory Invoicing Summary" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Municipal & State Excise Tax Filings</h2>
        <span class="text-xs text-neutral-400">Monthly statutory returns</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Invoice ID</th>
            <th class="py-3 px-4">Tax Authority / Jurisdiction</th>
            <th class="py-3 px-4">Tax Category</th>
            <th class="py-3 px-4">Taxable Fare Volume</th>
            <th class="py-3 px-4">Excise Tax Obligation</th>
            <th class="py-3 px-4 text-right">Filing Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="t in taxInvoices"
            :key="t.invoiceId"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ t.invoiceId }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ t.jurisdiction }}</td>
            <td class="py-3 px-4 text-neutral-700">{{ t.taxType }}</td>
            <td class="py-3 px-4 font-mono text-neutral-800">{{ t.taxableBase }}</td>
            <td class="py-3 px-4 font-bold text-base text-neutral-900">{{ t.taxDue }}</td>
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
