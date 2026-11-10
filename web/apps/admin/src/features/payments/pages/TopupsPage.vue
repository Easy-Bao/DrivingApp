<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

interface TopUpRequest {
  id: string
  driverName: string
  driverPhone: string
  vehiclePlate: string
  currentBalance: number
  amount: number
  paymentMethod: 'Company QR Code' | 'Company Bank Transfer'
  referenceCode: string
  submittedAt: string
  companyAccountPaid: string
  proofNote: string
  status: 'Pending' | 'Verified' | 'Rejected'
}

const topUpRequests = ref<TopUpRequest[]>([
  {
    id: 'TOP-8921',
    driverName: 'Marcus Miller',
    driverPhone: '+1 (555) 234-5678',
    vehiclePlate: '7XYZ892',
    currentBalance: 1.5,
    amount: 50.0,
    paymentMethod: 'Company QR Code',
    referenceCode: 'QR-TXN-8829104',
    submittedAt: '8 minutes ago',
    companyAccountPaid: 'Company QR Merchant #ER-8801',
    proofNote: 'Screenshot verified against company mobile payment receipt #8829104',
    status: 'Pending',
  },
  {
    id: 'TOP-8920',
    driverName: 'Elena Rostova',
    driverPhone: '+1 (555) 876-5432',
    vehiclePlate: 'EV-4491',
    currentBalance: 3.2,
    amount: 100.0,
    paymentMethod: 'Company Bank Transfer',
    referenceCode: 'WIRE-99218204',
    submittedAt: '24 minutes ago',
    companyAccountPaid: 'Company Fleet Acct: 0182-9981-2291',
    proofNote: 'Bank deposit receipt matches exact timestamp and account holder name',
    status: 'Pending',
  },
  {
    id: 'TOP-8919',
    driverName: 'David Kim',
    driverPhone: '+1 (555) 345-6789',
    vehiclePlate: 'CAM-8891',
    currentBalance: 0.0,
    amount: 30.0,
    paymentMethod: 'Company QR Code',
    referenceCode: 'QR-TXN-7719201',
    submittedAt: '42 minutes ago',
    companyAccountPaid: 'Company QR Merchant #ER-8801',
    proofNote: 'Bank notification confirmed for $30.00',
    status: 'Pending',
  },
])

const verificationToast = ref<string | null>(null)
const selectedProofRequest = ref<TopUpRequest | null>(null)

function verifyAndCredit(req: TopUpRequest) {
  req.status = 'Verified'
  req.currentBalance += req.amount
  verificationToast.value = `Successfully verified ${req.id}! Credited $${req.amount.toFixed(2)} to ${req.driverName}. Driver wallet is now unlocked to accept rides.`
  setTimeout(() => {
    verificationToast.value = null
  }, 6000)
}

function rejectRequest(req: TopUpRequest) {
  req.status = 'Rejected'
  verificationToast.value = `Request ${req.id} for ${req.driverName} rejected. Driver has been notified.`
  setTimeout(() => {
    verificationToast.value = null
  }, 5000)
}

function openProofModal(req: TopUpRequest) {
  selectedProofRequest.value = req
}

function closeProofModal() {
  selectedProofRequest.value = null
}

function confirmAndVerify() {
  if (selectedProofRequest.value) {
    verifyAndCredit(selectedProofRequest.value)
    closeProofModal()
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Driver Top-Up Verification Queue
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Review manual driver deposits paid to company bank accounts or payment QR codes. Once
          verified, wallet credits immediately restore ride acceptance.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <RouterLink
          to="/payment/payment-methods"
          class="px-3.5 py-2 bg-white border border-neutral-200 text-neutral-700 rounded-lg text-xs font-semibold hover:bg-neutral-50 flex items-center space-x-1.5"
        >
          <Icon icon="lucide:qr-code" class="text-neutral-500" />
          <span>Manage Company Bank & QR</span>
        </RouterLink>
      </div>
    </div>

    <!-- Protocol Info Banner -->
    <div class="bg-amber-50/70 border border-amber-200 rounded-xl p-4 flex items-start space-x-3">
      <Icon icon="lucide:info" class="text-amber-700 text-lg mt-0.5 shrink-0" />
      <div class="text-xs text-amber-900 leading-relaxed">
        <span class="font-bold">Driver Top-Up Protocol:</span> Drivers with low or zero balance
        cannot accept rides. They transfer directly to the company number or company QR. Validate
        the receipt reference below, then click <strong>Verify & Credit</strong> to immediately
        restore the driver's dispatch eligibility.
      </div>
    </div>

    <!-- Toast Notification -->
    <div
      v-if="verificationToast"
      class="p-4 rounded-xl bg-emerald-900 text-white text-xs font-medium flex items-center justify-between shadow-lg transition-all animate-in fade-in"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:check-circle-2" class="text-emerald-400 text-lg shrink-0" />
        <span>{{ verificationToast }}</span>
      </div>
      <button
        type="button"
        class="text-emerald-300 hover:text-white"
        @click="verificationToast = null"
      >
        <Icon icon="lucide:x" />
      </button>
    </div>

    <!-- Verification Table -->
    <div class="bg-white border border-neutral-200 rounded-xl shadow-xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <h2 class="font-bold text-sm text-neutral-900">Pending Driver Top-Up Queue</h2>
          <span class="px-2 py-0.5 text-[10px] font-bold bg-amber-100 text-amber-800 rounded-full">
            {{ topUpRequests.filter((r) => r.status === 'Pending').length }} Pending
          </span>
        </div>
        <span class="text-xs text-neutral-400">Updates live from driver mobile app</span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">Request ID</th>
              <th class="py-3 px-4">Driver & Vehicle</th>
              <th class="py-3 px-4">Top-Up Amount</th>
              <th class="py-3 px-4">Current Balance</th>
              <th class="py-3 px-4">Deposit Channel</th>
              <th class="py-3 px-4">Bank Ref / Slip</th>
              <th class="py-3 px-4">Proof</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Verification Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr v-for="req in topUpRequests" :key="req.id" class="hover:bg-neutral-50/50">
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ req.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ req.driverName }}</div>
                <div class="text-[11px] text-neutral-500">
                  {{ req.driverPhone }} · <span class="font-mono">{{ req.vehiclePlate }}</span>
                </div>
              </td>
              <td class="py-3 px-4">
                <span class="text-sm font-bold text-emerald-700"
                  >+${{ req.amount.toFixed(2) }}</span
                >
              </td>
              <td class="py-3 px-4">
                <div
                  class="font-medium"
                  :class="req.currentBalance < 5 ? 'text-rose-600 font-bold' : 'text-neutral-700'"
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
                <button
                  type="button"
                  class="px-2 py-1 rounded bg-neutral-100 hover:bg-neutral-200 text-neutral-700 text-[11px] font-medium flex items-center space-x-1"
                  @click="openProofModal(req)"
                >
                  <Icon icon="lucide:image" class="text-xs" />
                  <span>View Proof</span>
                </button>
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
              <td class="py-3 px-4 text-right space-x-1.5 whitespace-nowrap">
                <template v-if="req.status === 'Pending'">
                  <button
                    type="button"
                    class="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-xs transition-colors shadow-2xs"
                    @click="verifyAndCredit(req)"
                  >
                    Verify & Credit
                  </button>
                  <button
                    type="button"
                    class="px-2.5 py-1.5 rounded-lg border border-neutral-200 hover:bg-rose-50 hover:border-rose-200 hover:text-rose-700 text-neutral-600 font-medium text-xs transition-colors"
                    @click="rejectRequest(req)"
                  >
                    Reject
                  </button>
                </template>
                <span v-else class="text-[11px] text-neutral-400 font-medium italic">
                  Processed
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Proof of Payment Modal -->
    <div
      v-if="selectedProofRequest"
      class="fixed inset-0 z-50 bg-neutral-950/50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-2xl max-w-lg w-full p-6 space-y-4 shadow-xl">
        <div class="flex items-center justify-between border-b border-neutral-100 pb-3">
          <div class="flex items-center space-x-2">
            <Icon icon="lucide:receipt" class="text-lg text-neutral-700" />
            <h3 class="font-bold text-sm text-neutral-900">
              Payment Verification Proof · {{ selectedProofRequest.id }}
            </h3>
          </div>
          <button
            type="button"
            class="text-neutral-400 hover:text-neutral-900"
            @click="closeProofModal"
          >
            <Icon icon="lucide:x" class="text-lg" />
          </button>
        </div>

        <div class="space-y-3 text-xs">
          <div class="bg-neutral-50 p-3 rounded-lg space-y-1">
            <div class="flex justify-between text-neutral-600">
              <span>Driver</span>
              <span class="font-semibold text-neutral-900"
                >{{ selectedProofRequest.driverName }} ({{
                  selectedProofRequest.driverPhone
                }})</span
              >
            </div>
            <div class="flex justify-between text-neutral-600">
              <span>Amount Transferred</span>
              <span class="font-bold text-emerald-700 text-sm"
                >${{ selectedProofRequest.amount.toFixed(2) }}</span
              >
            </div>
            <div class="flex justify-between text-neutral-600">
              <span>Deposit Channel</span>
              <span class="font-medium text-neutral-900">{{
                selectedProofRequest.paymentMethod
              }}</span>
            </div>
            <div class="flex justify-between text-neutral-600">
              <span>Company Account Credited</span>
              <span class="font-mono text-neutral-800">{{
                selectedProofRequest.companyAccountPaid
              }}</span>
            </div>
            <div class="flex justify-between text-neutral-600">
              <span>Transaction Reference</span>
              <span class="font-mono font-bold text-neutral-900">{{
                selectedProofRequest.referenceCode
              }}</span>
            </div>
          </div>

          <div
            class="border-2 border-dashed border-neutral-200 rounded-xl p-6 text-center space-y-2 bg-neutral-50/50"
          >
            <Icon icon="lucide:file-check" class="text-3xl text-emerald-600 mx-auto" />
            <p class="font-bold text-xs text-neutral-800">
              Official Transfer Deposit Receipt Attached
            </p>
            <p class="text-[11px] text-neutral-500">{{ selectedProofRequest.proofNote }}</p>
            <span
              class="inline-block font-mono text-[10px] text-neutral-400 bg-white px-2 py-1 rounded border border-neutral-200"
            >
              SHA256: 8f2a991c0e3b...verified
            </span>
          </div>
        </div>

        <div class="flex justify-end space-x-2 pt-2 border-t border-neutral-100">
          <button
            type="button"
            class="px-4 py-2 border border-neutral-200 rounded-lg text-xs font-medium text-neutral-600 hover:bg-neutral-100"
            @click="closeProofModal"
          >
            Close
          </button>
          <button
            v-if="selectedProofRequest.status === 'Pending'"
            type="button"
            class="px-4 py-2 bg-emerald-600 text-white rounded-lg text-xs font-semibold hover:bg-emerald-700 shadow-sm"
            @click="confirmAndVerify"
          >
            Verify & Credit Wallet Now
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
