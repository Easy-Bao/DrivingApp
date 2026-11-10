<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const companyAccounts = ref([
  {
    id: 'ACC-1',
    type: 'Company Bank Account',
    bankName: 'Metropolitan Commercial Bank',
    accountName: 'EasyRide Mobility Corp - Operations',
    accountNumber: '0182-9981-2291',
    routingCode: '021000021',
    status: 'Active for Driver Top-Ups',
  },
  {
    id: 'ACC-2',
    type: 'Company Payment QR / Instant Transfer',
    bankName: 'National Instant Payment Network',
    accountName: 'EasyRide Driver Settlement QR',
    accountNumber: 'Merchant ID: ER-QR-8801',
    routingCode: 'Paybill Code: 882001',
    status: 'Active for Driver Top-Ups',
  },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Official Company Accounts & Payment QR
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Configure company bank details and QR codes presented to drivers on their mobile app for
          manual credit top-ups.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 text-white rounded-lg text-xs font-semibold hover:bg-neutral-800"
      >
        + Add Company Account
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div
        v-for="acc in companyAccounts"
        :key="acc.id"
        class="p-6 border border-neutral-200 rounded-xl bg-white shadow-xs space-y-4"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-bold text-neutral-900 uppercase tracking-wider">{{
            acc.type
          }}</span>
          <span
            class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800"
            >{{ acc.status }}</span
          >
        </div>

        <div class="space-y-2 text-xs text-neutral-700">
          <div class="flex justify-between">
            <span class="text-neutral-500">Institution / Bank</span>
            <span class="font-semibold text-neutral-900">{{ acc.bankName }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-neutral-500">Beneficiary Name</span>
            <span class="font-semibold text-neutral-900">{{ acc.accountName }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-neutral-500">Account / Merchant ID</span>
            <span class="font-mono font-bold text-neutral-900">{{ acc.accountNumber }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-neutral-500">Routing / Paybill Code</span>
            <span class="font-mono font-bold text-neutral-900">{{ acc.routingCode }}</span>
          </div>
        </div>

        <div class="pt-4 border-t border-neutral-100 flex space-x-2">
          <button
            type="button"
            class="flex-1 py-2 text-xs font-semibold border border-neutral-200 rounded-lg hover:bg-neutral-50"
          >
            Edit Account Info
          </button>
          <button
            type="button"
            class="px-3.5 py-2 text-xs font-semibold bg-neutral-900 text-white rounded-lg hover:bg-neutral-800"
          >
            Update QR Code Image
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
