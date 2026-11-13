<script setup lang="ts">
import { computed, ref } from 'vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'
import { formatPhp } from '@/shared/utils/format'

interface FareAdjustmentClaim {
  id: string
  tripId: string
  claimant: string
  claimType: 'Passenger Cash Rebate' | 'Driver Commission Waiver'
  amountPhp: number
  reason: string
  status: 'Pending Approval' | 'Approved & Credited' | 'Declined'
  resolutionNote?: string
}

const claims = ref<FareAdjustmentClaim[]>([
  {
    id: 'ADJ-7016-501',
    tripId: 'TRP-7016-8918',
    claimant: 'Passenger (Clarisse Joy Tagupa)',
    claimType: 'Passenger Cash Rebate',
    amountPhp: 45.0,
    reason: 'Taxicle dropped passenger shy of Brgy. San Pedro chapel due to flooded alley.',
    status: 'Pending Approval',
  },
  {
    id: 'ADJ-7016-502',
    tripId: 'TRP-7016-8912',
    claimant: 'Driver (Reynaldo Bautista)',
    claimType: 'Driver Commission Waiver',
    amountPhp: 15.0,
    reason: 'GPS geofence dropped early near Dao Provincial Capitol; reverse duplicate 15% debit.',
    status: 'Pending Approval',
  },
  {
    id: 'ADJ-7016-503',
    tripId: 'TRP-7016-8884',
    claimant: 'Passenger (Rafael Dominguiano)',
    claimType: 'Passenger Cash Rebate',
    amountPhp: 30.0,
    reason: 'Duplicate cancellation charge triggered during network timeout.',
    status: 'Approved & Credited',
    resolutionNote: 'Verified duplicate billing event; issued PHP 30.00 promo credit.',
  },
])

const searchQuery = ref('')
const statusFilter = ref<'All' | FareAdjustmentClaim['status']>('All')
const toastMessage = ref<string | null>(null)

const pendingClaim = ref<FareAdjustmentClaim | null>(null)
const pendingAction = ref<'approve' | 'decline'>('approve')
const dialogOpen = ref(false)
const auditReason = ref('')

const filteredClaims = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return claims.value.filter((item) => {
    const matchesStatus = statusFilter.value === 'All' || item.status === statusFilter.value
    const matchesSearch =
      !q ||
      item.id.toLowerCase().includes(q) ||
      item.tripId.toLowerCase().includes(q) ||
      item.claimant.toLowerCase().includes(q) ||
      item.reason.toLowerCase().includes(q)
    return matchesStatus && matchesSearch
  })
})

const pendingCount = computed(
  () => claims.value.filter((c) => c.status === 'Pending Approval').length,
)

const openDecisionDialog = (claim: FareAdjustmentClaim, decision: 'approve' | 'decline') => {
  pendingClaim.value = claim
  pendingAction.value = decision
  auditReason.value = ''
  dialogOpen.value = true
}

const confirmDecision = () => {
  if (!pendingClaim.value || !auditReason.value.trim()) return
  pendingClaim.value.status = pendingAction.value === 'approve' ? 'Approved & Credited' : 'Declined'
  pendingClaim.value.resolutionNote = auditReason.value.trim()
  toastMessage.value = `${pendingClaim.value.id} marked ${pendingClaim.value.status}.`
  dialogOpen.value = false
  pendingClaim.value = null
  auditReason.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner
      v-if="toastMessage"
      :message="toastMessage"
      tone="success"
      @dismiss="toastMessage = null"
    />

    <div
      class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white border border-neutral-200 rounded-md p-4"
    >
      <div>
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold text-neutral-900">
            Fare Adjustments &amp; Commission Fee Waivers
          </h2>
          <StatusBadge
            :label="`${pendingCount} Pending Review`"
            :tone="pendingCount > 0 ? 'warning' : 'success'"
          />
        </div>
        <p class="text-xs text-neutral-500 mt-0.5">
          Audit claims for passenger cash fare rebates and driver prepaid commission reversals
          across Pagadian City trips.
        </p>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search adjustment ID, trip ID, or claimant..."
          class="w-full md:w-80 px-3 py-1.5 border border-neutral-300 rounded-none text-xs bg-white text-neutral-900 focus:outline-none focus:border-neutral-900"
        />

        <BaseSelect
          v-model="statusFilter"
          aria-label="Filter by claim status"
          :options="[
            { label: 'All Claim Statuses', value: 'All' },
            { label: 'Pending Approval', value: 'Pending Approval' },
            { label: 'Approved & Credited', value: 'Approved & Credited' },
            { label: 'Declined', value: 'Declined' },
          ]"
        />
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[820px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Claim ID &amp; Trip</th>
              <th class="py-3 px-4">Claimant &amp; Type</th>
              <th class="py-3 px-4">Amount (PHP)</th>
              <th class="py-3 px-4">Dispute Justification</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="item in filteredClaims"
              :key="item.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3.5 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ item.id }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ item.tripId }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-semibold text-neutral-900">{{ item.claimant }}</div>
                <div class="text-[11px] text-neutral-500">{{ item.claimType }}</div>
              </td>
              <td class="py-3.5 px-4 font-mono font-bold text-neutral-900 tabular-nums">
                {{ formatPhp(item.amountPhp) }}
              </td>
              <td class="py-3.5 px-4 text-neutral-600 max-w-sm">
                <div>{{ item.reason }}</div>
                <div v-if="item.resolutionNote" class="text-[11px] text-neutral-500 mt-1 italic">
                  Note: {{ item.resolutionNote }}
                </div>
              </td>
              <td class="py-3.5 px-4">
                <StatusBadge
                  :label="item.status"
                  :tone="
                    item.status === 'Approved & Credited'
                      ? 'success'
                      : item.status === 'Declined'
                        ? 'danger'
                        : 'warning'
                  "
                />
              </td>
              <td class="py-3.5 px-4 text-right whitespace-nowrap">
                <div
                  v-if="item.status === 'Pending Approval'"
                  class="inline-flex items-center gap-2"
                >
                  <button
                    type="button"
                    class="px-2.5 py-1 border border-neutral-300 bg-white text-neutral-700 rounded-none text-xs font-medium hover:bg-neutral-50"
                    @click="openDecisionDialog(item, 'decline')"
                  >
                    Decline
                  </button>
                  <button
                    type="button"
                    class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold"
                    @click="openDecisionDialog(item, 'approve')"
                  >
                    Approve &amp; Credit
                  </button>
                </div>
                <span v-else class="text-neutral-400 text-xs">Finalized</span>
              </td>
            </tr>
            <tr v-if="filteredClaims.length === 0">
              <td colspan="6" class="py-10 px-4 text-center text-xs text-neutral-500">
                No adjustment claims match your search or status filter.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <ConfirmDialog
      v-model:open="dialogOpen"
      v-model:reason="auditReason"
      :title="
        pendingAction === 'approve'
          ? `Approve Adjustment · ${pendingClaim?.id ?? ''}`
          : `Decline Claim · ${pendingClaim?.id ?? ''}`
      "
      :description="
        pendingAction === 'approve'
          ? `Confirm release of ${formatPhp(pendingClaim?.amountPhp ?? 0)} for ${pendingClaim?.claimant ?? ''}.`
          : `Document why adjustment claim ${pendingClaim?.id ?? ''} is being declined.`
      "
      :confirm-label="pendingAction === 'approve' ? 'Approve Credit' : 'Decline Claim'"
      :tone="pendingAction === 'approve' ? 'emerald' : 'rose'"
      :require-reason="true"
      reason-label="Mandatory Finance Audit Note"
      reason-placeholder="Enter reference verification or trip log finding..."
      @confirm="confirmDecision"
      @cancel="dialogOpen = false"
    />
  </div>
</template>
