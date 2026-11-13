<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const searchQuery = ref('')

const driverWallets = ref([
  {
    driverId: 'DRV-101',
    driver: 'Marcus Miller',
    phone: '+1 (555) 234-5678',
    balance: 42.5,
    creditLimit: 0.0,
    totalTopups: 450.0,
    totalCommissionPaid: 320.0,
    status: 'Active (Dispatches Enabled)',
  },
  {
    driverId: 'DRV-102',
    driver: 'Elena Rostova',
    phone: '+1 (555) 876-5432',
    balance: 12.0,
    creditLimit: 0.0,
    totalTopups: 600.0,
    totalCommissionPaid: 480.0,
    status: 'Active (Dispatches Enabled)',
  },
  {
    driverId: 'DRV-103',
    driver: 'David Kim',
    phone: '+1 (555) 345-6789',
    balance: 88.0,
    creditLimit: 0.0,
    totalTopups: 820.0,
    totalCommissionPaid: 650.0,
    status: 'Active (Dispatches Enabled)',
  },
  {
    driverId: 'DRV-104',
    driver: 'Javier Santos',
    phone: '+1 (555) 987-6543',
    balance: 1.5,
    creditLimit: 0.0,
    totalTopups: 150.0,
    totalCommissionPaid: 148.5,
    status: 'Locked (Balance Below Minimum ₱5.00)',
  },
])

const actionToast = ref<string | null>(null)

function triggerTopupPrompt(driver: (typeof driverWallets.value)[0]) {
  actionToast.value = `Payment details and Company QR sent to ${driver.driver} via driver app.`
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Driver Dispatch Wallets
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Prepaid driver wallet balances used to deduct platform commission on cash and direct
          rides.
        </p>
      </div>
      <div class="flex items-center space-x-3">
        <RouterLink
          to="/payments/topups"
          class="px-3.5 py-2 bg-amber-500 hover:bg-amber-600 text-white text-xs font-semibold transition-colors flex items-center space-x-2"
        >
          <span>Verify Pending Top-Ups (3) →</span>
        </RouterLink>
      </div>
    </div>

    <!-- Summary Statistics -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Total In Driver Wallets</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">₱44,210.00</div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Min Threshold for Dispatch</span>
        <div class="text-xl font-bold tabular-nums text-neutral-900 mt-1">₱5.00</div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Locked Drivers (Low Balance)</span>
        <div class="text-xl font-bold tabular-nums text-rose-600 mt-1">12</div>
      </div>
      <div class="bg-white p-4 border border-neutral-200">
        <span class="text-xs text-neutral-500 font-medium">Average Top-Up Size</span>
        <div class="text-xl font-bold tabular-nums text-blue-600 mt-1">₱50.00</div>
      </div>
    </div>

    <div
      v-if="actionToast"
      class="p-4 bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <div class="relative w-72">
          <Icon icon="lucide:search" class="absolute left-3 top-2.5 text-neutral-400 text-sm" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search driver wallet by name, phone..."
            class="w-full pl-9 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 text-xs"
          />
        </div>
        <span class="text-xs text-neutral-500">No 3rd-party gateway fees</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Driver ID</th>
            <th class="py-3 px-4">Driver</th>
            <th class="py-3 px-4">Prepaid Balance</th>
            <th class="py-3 px-4">Total Top-Ups Paid</th>
            <th class="py-3 px-4">Commission Deducted</th>
            <th class="py-3 px-4">Dispatch Eligibility</th>
            <th class="py-3 px-4 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="w in driverWallets"
            :key="w.driverId"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ w.driverId }}</td>
            <td class="py-3 px-4">
              <div class="font-semibold text-neutral-900">{{ w.driver }}</div>
              <div class="text-[11px] text-neutral-400">{{ w.phone }}</div>
            </td>
            <td class="py-3 px-4">
              <span
                class="font-mono font-bold text-sm"
                :class="w.balance < 5 ? 'text-rose-600' : 'text-neutral-900'"
              >
                ₱{{ w.balance.toFixed(2) }}
              </span>
            </td>
            <td class="py-3 px-4 font-mono text-neutral-700">₱{{ w.totalTopups.toFixed(2) }}</td>
            <td class="py-3 px-4 font-mono text-neutral-700">
              ₱{{ w.totalCommissionPaid.toFixed(2) }}
            </td>
            <td class="py-3 px-4">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                :class="
                  w.balance >= 5 ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'
                "
              >
                {{ w.status }}
              </span>
            </td>
            <td class="py-3 px-4 text-right">
              <button
                type="button"
                class="text-xs text-neutral-600 hover:text-neutral-900 font-medium"
                @click="triggerTopupPrompt(w)"
              >
                Prompt QR Top-Up
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
