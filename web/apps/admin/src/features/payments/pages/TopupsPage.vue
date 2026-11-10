<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useTopups } from '@/features/payments/composables/useTopups'

const router = useRouter()
const { topUpRequests } = useTopups()

const filterMethod = ref<'All' | 'Company QR Code' | 'Company Bank Transfer'>('All')

function navigateToDetails(id: string) {
  void router.push(`/payments/topups/${id}`)
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Driver Wallet Top-Up Verification
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Verify driver manual payment transfers to company QR or company bank account before
          crediting dispatch wallets.
        </p>
      </div>

      <div class="flex items-center space-x-3">
        <RouterLink
          to="/payments/methods"
          class="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-lg border border-neutral-200 bg-white hover:bg-neutral-50 text-xs font-semibold text-neutral-700 shadow-2xs transition-colors"
        >
          <Icon icon="lucide:qr-code" class="text-neutral-500" />
          <span>Manage Company Bank & QR</span>
        </RouterLink>
      </div>
    </div>

    <!-- Instructions Banner -->
    <div
      class="bg-blue-50/70 border border-blue-200 rounded-xl p-4 flex items-start space-x-3 text-xs"
    >
      <Icon icon="lucide:info" class="text-blue-600 text-base shrink-0 mt-0.5" />
      <div class="space-y-1 text-blue-900 leading-relaxed">
        <span class="font-bold">Manual Settlement Process:</span>
        Drivers transfer money to the company official bank account or scan the company payment QR
        code from the driver app. After receiving driver proof, admins view the detailed request
        audit record to verify the transaction reference before releasing wallet credits.
      </div>
    </div>

    <!-- Table -->
    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <div class="flex items-center space-x-3">
          <h2 class="font-bold text-sm text-neutral-900">Pending Driver Top-Up Verifications</h2>
          <span class="px-2 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-800">
            {{ topUpRequests.filter((r) => r.status === 'Pending').length }} Pending
          </span>
        </div>

        <div class="flex items-center space-x-2">
          <select
            v-model="filterMethod"
            class="px-3 py-1.5 bg-neutral-50 border border-neutral-200 rounded-lg text-xs font-medium text-neutral-700"
          >
            <option value="All">All Payment Methods</option>
            <option value="Company QR Code">Company QR Code</option>
            <option value="Company Bank Transfer">Company Bank Transfer</option>
          </select>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Request ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Amount</th>
              <th class="py-3 px-4">Prepaid Balance</th>
              <th class="py-3 px-4">Deposit Channel</th>
              <th class="py-3 px-4">Reference Code</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="req in topUpRequests"
              :key="req.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ req.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ req.driverName }}</div>
                <div class="text-[11px] text-neutral-400">
                  {{ req.driverPhone }} · Plate: {{ req.vehiclePlate }}
                </div>
              </td>
              <td class="py-3 px-4 font-bold text-sm text-neutral-900 font-mono">
                ${{ req.amount.toFixed(2) }}
              </td>
              <td class="py-3 px-4 font-mono">
                <div
                  :class="req.currentBalance < 5 ? 'text-rose-600 font-bold' : 'text-neutral-900'"
                >
                  ${{ req.currentBalance.toFixed(2) }}
                </div>
                <div class="text-[10px] text-neutral-400">
                  After: ${{
                    (req.currentBalance + (req.status === 'Pending' ? req.amount : 0)).toFixed(2)
                  }}
                </div>
              </td>
              <td class="py-3 px-4">
                <span class="inline-flex items-center space-x-1 font-medium text-neutral-800">
                  <Icon
                    :icon="
                      req.paymentMethod === 'Company QR Code'
                        ? 'lucide:qr-code'
                        : 'lucide:building-2'
                    "
                    class="text-sm text-neutral-500"
                  />
                  <span>{{ req.paymentMethod }}</span>
                </span>
                <div class="text-[10px] text-neutral-400 truncate max-w-[140px]">
                  {{ req.companyAccountPaid }}
                </div>
              </td>
              <td class="py-3 px-4 font-mono text-[11px] font-semibold text-neutral-800">
                {{ req.referenceCode }}
              </td>
              <td class="py-3 px-4">
                <span
                  class="px-2.5 py-0.5 rounded-full text-[10px] font-bold"
                  :class="{
                    'bg-amber-100 text-amber-800': req.status === 'Pending',
                    'bg-emerald-100 text-emerald-800': req.status === 'Verified',
                    'bg-rose-100 text-rose-800': req.status === 'Rejected',
                  }"
                >
                  {{ req.status }}
                </span>
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-3 py-1.5 rounded-lg bg-neutral-900 hover:bg-neutral-800 text-white font-semibold text-xs transition-colors shadow-2xs inline-flex items-center space-x-1"
                  @click="navigateToDetails(req.id)"
                >
                  <span>View Details</span>
                  <Icon icon="lucide:arrow-right" class="text-xs" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
