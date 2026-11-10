<script setup lang="ts">
import { ref } from 'vue'

const transactions = ref([
  {
    id: 'TXN-90812',
    driver: 'Marcus Miller',
    type: 'Ride Fare Credit',
    amount: '+$34.50',
    fee: '-$6.21',
    net: '+$28.29',
    date: '12 mins ago',
    status: 'Completed',
  },
  {
    id: 'TXN-90811',
    driver: 'David Kim',
    type: 'Driver Manual Top-Up',
    amount: '+$50.00',
    fee: '$0.00',
    net: '+$50.00',
    date: '34 mins ago',
    status: 'Verified',
  },
  {
    id: 'TXN-90810',
    driver: 'Elena Rostova',
    type: 'Platform Commission Deduction',
    amount: '-$4.80',
    fee: '$0.00',
    net: '-$4.80',
    date: '1 hour ago',
    status: 'Completed',
  },
  {
    id: 'TXN-90809',
    driver: 'Anthony Stark',
    type: 'Payout Disbursement',
    amount: '-$420.00',
    fee: '-$1.50',
    net: '-$421.50',
    date: 'Yesterday',
    status: 'Processed',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
        Platform Transaction Ledger
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Audit log of all platform financial movements, commissions, driver wallet credits, and
        disbursements.
      </p>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-xs overflow-hidden">
      <table class="w-full text-left text-xs">
        <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
          <tr>
            <th class="py-3 px-4">Transaction ID</th>
            <th class="py-3 px-4">Driver / Beneficiary</th>
            <th class="py-3 px-4">Type</th>
            <th class="py-3 px-4">Gross Amount</th>
            <th class="py-3 px-4">Platform Fee</th>
            <th class="py-3 px-4">Net Amount</th>
            <th class="py-3 px-4">Timestamp</th>
            <th class="py-3 px-4">Status</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100 text-neutral-700">
          <tr v-for="t in transactions" :key="t.id" class="hover:bg-neutral-50/50">
            <td class="py-3 px-4 font-mono font-bold">{{ t.id }}</td>
            <td class="py-3 px-4 font-semibold text-neutral-900">{{ t.driver }}</td>
            <td class="py-3 px-4">{{ t.type }}</td>
            <td class="py-3 px-4 font-semibold">{{ t.amount }}</td>
            <td class="py-3 px-4 text-neutral-500">{{ t.fee }}</td>
            <td
              class="py-3 px-4 font-bold"
              :class="t.net.startsWith('+') ? 'text-emerald-700' : 'text-neutral-900'"
            >
              {{ t.net }}
            </td>
            <td class="py-3 px-4 text-neutral-400">{{ t.date }}</td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800"
                >{{ t.status }}</span
              >
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
