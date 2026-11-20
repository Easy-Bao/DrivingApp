<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import {
  BaseSelect,
  EmptyTableRow,
  exportToCsv,
  formatCentavos,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  useDataTable,
} from '@/shared'
import { useTopups } from '@/features/payments'
import type { TopUpStatus } from '@/features/payments'

const router = useRouter()
const { topUpRequests, pendingTopups, minDispatchBalanceCentavos } = useTopups()

const searchQuery = ref('')
const statusFilter = ref<'All' | TopUpStatus>('All')
const methodFilter = ref<'All' | 'Company QR Code' | 'Company Bank Transfer'>('All')

const verifiedTotalCentavos = computed(() =>
  topUpRequests.value
    .filter((item) => item.status === 'Verified')
    .reduce((sum, item) => sum + item.amountCentavos, 0),
)

const filteredRequests = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return topUpRequests.value.filter((request) => {
    const matchesQuery =
      !query ||
      request.id.toLowerCase().includes(query) ||
      request.driverName.toLowerCase().includes(query) ||
      request.vehiclePlate.toLowerCase().includes(query) ||
      request.referenceCode.toLowerCase().includes(query)
    const matchesStatus = statusFilter.value === 'All' || request.status === statusFilter.value
    const matchesMethod =
      methodFilter.value === 'All' || request.paymentMethod === methodFilter.value
    return matchesQuery && matchesStatus && matchesMethod
  })
})

const hasActiveFilters = computed(
  () =>
    searchQuery.value.trim().length > 0 ||
    statusFilter.value !== 'All' ||
    methodFilter.value !== 'All',
)

const { currentPage, itemsPerPage, paginatedItems, resetPage } = useDataTable(filteredRequests, {
  initialPageSize: 10,
})

watch([searchQuery, statusFilter, methodFilter], resetPage)

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'All'
  methodFilter.value = 'All'
}

function statusTone(status: TopUpStatus) {
  if (status === 'Verified') return 'success'
  if (status === 'Pending') return 'warning'
  return 'danger'
}

function navigateToDetails(id: string) {
  router.push(`/payments/topups/${id}`)
}

function exportRequestsCsv() {
  exportToCsv(
    'easyride-topup-verification-queue',
    ['Request ID', 'Driver', 'Plate', 'Amount PHP', 'Method', 'Channel', 'Reference', 'Status'],
    filteredRequests.value.map((request) => [
      request.id,
      request.driverName,
      request.vehiclePlate,
      (request.amountCentavos / 100).toFixed(2),
      request.paymentMethod,
      request.channelProvider,
      request.referenceCode,
      request.status,
    ]),
  )
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Driver Top-Up Requests"
      description="Inspect uploaded QRPh and corporate bank deposit receipts before crediting driver prepaid wallets."
    >
      <template #actions>
        <div
          class="inline-flex items-center gap-2 border border-neutral-200 bg-white px-3 py-1.5 text-xs font-semibold text-neutral-900"
        >
          <span>{{ pendingTopups.length }} Pending</span>
          <span class="text-neutral-300">·</span>
          <span class="font-mono text-neutral-600">
            {{ formatCentavos(verifiedTotalCentavos) }} Verified Today
          </span>
        </div>
      </template>
    </PageHeader>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search top-up ID, driver, plate, or ref..."
          aria-label="Search top-up requests"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter by verification status"
            :options="[
              { label: 'All Statuses', value: 'All' },
              { label: 'Pending', value: 'Pending' },
              { label: 'Verified', value: 'Verified' },
              { label: 'Rejected', value: 'Rejected' },
            ]"
          />
          <BaseSelect
            v-model="methodFilter"
            aria-label="Filter by payment method"
            :options="[
              { label: 'All Methods', value: 'All' },
              { label: 'Company QR Code', value: 'Company QR Code' },
              { label: 'Company Bank Transfer', value: 'Company Bank Transfer' },
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
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 bg-white text-neutral-700 text-xs font-medium hover:bg-neutral-50 cursor-pointer"
            @click="exportRequestsCsv"
          >
            Export CSV
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[920px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Request ID</th>
              <th class="py-3 px-4">Driver &amp; Unit</th>
              <th class="py-3 px-4">Prepaid Balance</th>
              <th class="py-3 px-4">Top-Up Amount</th>
              <th class="py-3 px-4">Payment Channel</th>
              <th class="py-3 px-4">Reference</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="req in paginatedItems"
              :key="req.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ req.id }}</div>
                <div class="text-[11px] text-neutral-400">{{ req.submittedAt }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ req.driverName }}</div>
                <div class="text-[11px] text-neutral-500">
                  {{ req.vehiclePlate }} · {{ req.bodyUnit }}
                </div>
              </td>
              <td class="py-3 px-4 font-mono tabular-nums">
                <div class="font-semibold text-neutral-900">
                  {{ formatCentavos(req.currentBalanceCentavos) }}
                </div>
                <div
                  v-if="req.currentBalanceCentavos < minDispatchBalanceCentavos"
                  class="text-[10px] font-sans text-rose-700 font-medium"
                >
                  Below {{ formatCentavos(minDispatchBalanceCentavos) }} min
                </div>
              </td>
              <td class="py-3 px-4 font-mono font-bold text-sm tabular-nums text-neutral-900">
                {{ formatCentavos(req.amountCentavos) }}
              </td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-900">{{ req.channelProvider }}</div>
                <div class="text-[11px] text-neutral-500">{{ req.paymentMethod }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-mono text-[11px] font-semibold text-neutral-800">
                  {{ req.referenceCode }}
                </div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="req.status" :tone="statusTone(req.status)" />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white font-semibold text-xs transition-colors inline-flex items-center space-x-1 cursor-pointer"
                  @click="navigateToDetails(req.id)"
                >
                  <span>Inspect Proof</span>
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="8"
              title="No matching top-up requests"
              description="No top-up requests match the selected search and filters."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredRequests.length"
        :items-per-page="itemsPerPage"
      />
    </div>
  </div>
</template>
