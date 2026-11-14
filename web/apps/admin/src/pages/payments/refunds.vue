<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import {
  BaseSelect,
  ConfirmDialog,
  EmptyTableRow,
  formatCentavos,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  ToastBanner,
  useDataTable,
} from '@/shared'
import type { ToastTone } from '@/shared'
import { useRefundClaims } from '@/features/payments'
import type { AdjustmentClaimStatus, FareAdjustmentClaim } from '@/features/payments'

const { claims, resolveClaim } = useRefundClaims()

const searchQuery = ref('')
const statusFilter = ref<'All' | AdjustmentClaimStatus>('All')
const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('success')

const showResolveConfirm = ref(false)
const selectedClaim = ref<FareAdjustmentClaim | null>(null)
const decisionMode = ref<'approve' | 'decline'>('approve')
const resolutionNote = ref('')

const pendingCount = computed(
  () => claims.value.filter((claim) => claim.status === 'Pending Approval').length,
)

const filteredClaims = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return claims.value.filter((claim) => {
    const matchesQuery =
      !query ||
      claim.id.toLowerCase().includes(query) ||
      claim.tripId.toLowerCase().includes(query) ||
      claim.claimant.toLowerCase().includes(query) ||
      claim.reason.toLowerCase().includes(query)
    const matchesStatus = statusFilter.value === 'All' || claim.status === statusFilter.value
    return matchesQuery && matchesStatus
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || statusFilter.value !== 'All',
)

const { currentPage, itemsPerPage, paginatedItems, resetPage } = useDataTable(filteredClaims, {
  initialPageSize: 10,
})

watch([searchQuery, statusFilter], resetPage)

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'All'
}

function statusTone(status: AdjustmentClaimStatus) {
  if (status === 'Approved & Credited') return 'success'
  if (status === 'Pending Approval') return 'warning'
  return 'danger'
}

function openDecisionDialog(claim: FareAdjustmentClaim, mode: 'approve' | 'decline') {
  selectedClaim.value = claim
  decisionMode.value = mode
  resolutionNote.value = ''
  showResolveConfirm.value = true
}

function submitDecision() {
  if (!selectedClaim.value) return
  const result = resolveClaim(selectedClaim.value.id, decisionMode.value, resolutionNote.value)
  if (!result.ok) {
    toastMessage.value = result.error
    toastTone.value = 'warning'
    return
  }
  showResolveConfirm.value = false
  resolutionNote.value = ''
  toastMessage.value = result.message ?? `Updated ${selectedClaim.value.id}`
  toastTone.value = decisionMode.value === 'approve' ? 'success' : 'warning'
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <PageHeader
      title="Refunds & Fare Adjustments"
      description="Adjudicate passenger cash rebates, duplicate cancellation fees, and prepaid driver commission waivers."
    >
      <template #actions>
        <div
          class="inline-flex items-center border border-neutral-200 bg-white px-3 py-1.5 text-xs font-semibold text-neutral-900"
        >
          {{ pendingCount }} Pending Review
        </div>
      </template>
    </PageHeader>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search claim ID, trip ID, claimant..."
          aria-label="Search fare adjustment claims"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
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
          <button
            v-if="hasActiveFilters"
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-700 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
            @click="resetFilters"
          >
            Reset
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[880px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Claim &amp; Trip</th>
              <th class="py-3 px-4">Claimant &amp; Type</th>
              <th class="py-3 px-4">Amount</th>
              <th class="py-3 px-4">Justification</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="claim in paginatedItems"
              :key="claim.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ claim.id }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ claim.tripId }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ claim.claimant }}</div>
                <div class="text-[11px] text-neutral-500">{{ claim.claimType }}</div>
              </td>
              <td class="py-3 px-4 font-mono font-bold tabular-nums text-neutral-900">
                {{ formatCentavos(claim.amountCentavos) }}
              </td>
              <td class="py-3 px-4 max-w-sm">
                <p class="text-neutral-700 leading-snug">{{ claim.reason }}</p>
                <p
                  v-if="claim.resolutionNote"
                  class="text-[11px] font-medium text-neutral-500 mt-1"
                >
                  Resolution: {{ claim.resolutionNote }}
                </p>
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="claim.status" :tone="statusTone(claim.status)" />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <div
                  v-if="claim.status === 'Pending Approval'"
                  class="inline-flex items-center gap-2"
                >
                  <button
                    type="button"
                    class="px-2.5 py-1 border border-neutral-300 bg-white text-neutral-800 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
                    @click="openDecisionDialog(claim, 'decline')"
                  >
                    Decline
                  </button>
                  <button
                    type="button"
                    class="px-2.5 py-1 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
                    @click="openDecisionDialog(claim, 'approve')"
                  >
                    Approve &amp; Credit
                  </button>
                </div>
                <span v-else class="text-[11px] text-neutral-400">Resolved</span>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="6"
              title="No matching adjustment claims"
              description="No refund or fee waiver claims match your current filter."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredClaims.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ConfirmDialog
      v-model:open="showResolveConfirm"
      v-model:reason="resolutionNote"
      :title="
        decisionMode === 'approve'
          ? `Approve Adjustment · ${selectedClaim?.id ?? ''}`
          : `Decline Adjustment · ${selectedClaim?.id ?? ''}`
      "
      :description="
        decisionMode === 'approve'
          ? `Approve ${formatCentavos(selectedClaim?.amountCentavos ?? 0)} for ${selectedClaim?.claimant ?? ''}?`
          : `Decline claim ${selectedClaim?.id ?? ''} and notify claimant.`
      "
      :confirm-label="decisionMode === 'approve' ? 'Approve Credit' : 'Confirm Decline'"
      :tone="decisionMode === 'approve' ? 'neutral' : 'rose'"
      :require-reason="true"
      reason-label="Mandatory Audit Justification"
      reason-placeholder="Enter GPS verification or dispatch investigation note..."
      @confirm="submitDecision"
    />
  </div>
</template>
