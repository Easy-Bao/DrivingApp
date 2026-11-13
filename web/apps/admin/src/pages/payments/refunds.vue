<script setup lang="ts">
import { computed, ref } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import ConfirmDialog from '@/shared/dialogs/ConfirmDialog.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
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
    reason: 'Driver dropped passenger shy of Brgy. San Pedro chapel due to flooded alley.',
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
  const query = searchQuery.value.trim().toLowerCase()
  return claims.value.filter((item) => {
    const matchesStatus = statusFilter.value === 'All' || item.status === statusFilter.value
    const matchesSearch =
      !query ||
      item.id.toLowerCase().includes(query) ||
      item.tripId.toLowerCase().includes(query) ||
      item.claimant.toLowerCase().includes(query) ||
      item.reason.toLowerCase().includes(query)
    return matchesStatus && matchesSearch
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || statusFilter.value !== 'All',
)

const resetFilters = () => {
  searchQuery.value = ''
  statusFilter.value = 'All'
}

const pendingCount = computed(
  () => claims.value.filter((claim) => claim.status === 'Pending Approval').length,
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

    <PageHeader
      title="Refunds"
      description="Review passenger fare rebates and driver commission reversals."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search adjustment ID, trip ID, or claimant..."
          aria-label="Search adjustment claims"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
          <StatusBadge :label="`${pendingCount} Pending Review`" tone="neutral" />
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
            <EmptyTableRow
              v-if="filteredClaims.length === 0"
              :colspan="6"
              title="No matching adjustment claims"
              description="No adjustment claims match your search or status filter."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
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
