<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useTopups, type TopUpRequest } from '@/features/payments/composables/use-topups'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge, { type BadgeTone } from '@/shared/feedback/StatusBadge.vue'
import TablePagination from '@/shared/table/TablePagination.vue'
import { formatPhp } from '@/shared/utils/format'

const router = useRouter()
const { topUpRequests } = useTopups()

const searchQuery = ref('')
const filterMethod = ref<'All' | 'Company QR Code' | 'Company Bank Transfer'>('All')
const filterStatus = ref<'All' | TopUpRequest['status']>('All')
const currentPage = ref(1)
const itemsPerPage = 8

const filteredRequests = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return topUpRequests.value.filter((request) => {
    const matchesMethod =
      filterMethod.value === 'All' || request.paymentMethod === filterMethod.value
    const matchesStatus = filterStatus.value === 'All' || request.status === filterStatus.value
    const matchesQuery =
      !query ||
      request.id.toLowerCase().includes(query) ||
      request.driverName.toLowerCase().includes(query) ||
      request.driverPhone.toLowerCase().includes(query) ||
      request.vehiclePlate.toLowerCase().includes(query) ||
      request.referenceCode.toLowerCase().includes(query)
    return matchesMethod && matchesStatus && matchesQuery
  })
})

const hasActiveFilters = computed(
  () =>
    searchQuery.value.trim().length > 0 ||
    filterMethod.value !== 'All' ||
    filterStatus.value !== 'All',
)

const resetFilters = () => {
  searchQuery.value = ''
  filterMethod.value = 'All'
  filterStatus.value = 'All'
}

const paginatedRequests = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredRequests.value.slice(start, start + itemsPerPage)
})

const pendingCount = computed(
  () => topUpRequests.value.filter((request) => request.status === 'Pending').length,
)

watch([searchQuery, filterMethod, filterStatus], () => {
  currentPage.value = 1
})

function statusTone(status: TopUpRequest['status']): BadgeTone {
  switch (status) {
    case 'Verified':
      return 'success'
    case 'Rejected':
      return 'danger'
    default:
      return 'warning'
  }
}

function navigateToDetails(id: string) {
  void router.push(`/payments/topups/${id}`)
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Top-Ups"
      description="Verify driver payment receipts before crediting prepaid wallets."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3"
      >
        <div class="flex items-center space-x-3">
          <h2 class="font-bold text-sm text-neutral-900">Driver Top-Up Submissions</h2>
          <span
            class="px-2 py-0.5 border border-neutral-200 bg-neutral-100 text-xs font-semibold text-neutral-800 tabular-nums"
          >
            {{ pendingCount }} Pending
          </span>
        </div>

        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <SearchField
            v-model="searchQuery"
            aria-label="Search top-up requests"
            placeholder="Search driver, +63 phone, plate, ref..."
            class="sm:w-64"
          />

          <BaseSelect
            v-model="filterMethod"
            aria-label="Filter by payment method"
            :options="[
              { label: 'All Payment Methods', value: 'All' },
              { label: 'Company QR Code', value: 'Company QR Code' },
              { label: 'Company Bank Transfer', value: 'Company Bank Transfer' },
            ]"
          />

          <BaseSelect
            v-model="filterStatus"
            aria-label="Filter by request status"
            :options="[
              { label: 'All Statuses', value: 'All' },
              { label: 'Pending', value: 'Pending' },
              { label: 'Verified', value: 'Verified' },
              { label: 'Rejected', value: 'Rejected' },
            ]"
          />

          <RouterLink
            to="/payments/methods"
            class="inline-flex items-center justify-center space-x-1.5 px-3 py-1.5 border border-neutral-200 bg-white hover:bg-neutral-50 text-xs font-semibold text-neutral-700 transition-colors shrink-0"
          >
            <Icon icon="lucide:qr-code" class="text-sm text-neutral-500" aria-hidden="true" />
            <span>Channels</span>
          </RouterLink>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs min-w-[820px]">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Request ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Amount</th>
              <th class="py-3 px-4">Prepaid Balance</th>
              <th class="py-3 px-4">Deposit Channel</th>
              <th class="py-3 px-4">Proof &amp; Reference</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="req in paginatedRequests"
              :key="req.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ req.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ req.driverName }}</div>
                <div class="text-[11px] text-neutral-500 font-mono">
                  {{ req.driverPhone }} · {{ req.vehiclePlate }}
                </div>
              </td>
              <td class="py-3 px-4 font-bold text-sm text-neutral-900 font-mono tabular-nums">
                {{ formatPhp(req.amount) }}
              </td>
              <td class="py-3 px-4 font-mono tabular-nums">
                <div
                  :class="
                    req.currentBalance < 50 ? 'text-neutral-900 font-bold' : 'text-neutral-900'
                  "
                >
                  {{ formatPhp(req.currentBalance) }}
                </div>
                <div class="text-[11px] text-neutral-500">
                  After:
                  {{ formatPhp(req.currentBalance + (req.status === 'Pending' ? req.amount : 0)) }}
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
                    aria-hidden="true"
                  />
                  <span>{{ req.channelProvider }}</span>
                </span>
                <div class="text-[11px] text-neutral-500 truncate max-w-[180px]">
                  {{ req.companyAccountPaid }}
                </div>
              </td>
              <td class="py-3 px-4">
                <div class="font-mono text-[11px] font-semibold text-neutral-800">
                  {{ req.referenceCode }}
                </div>
                <div
                  class="inline-flex items-center gap-1 text-[11px] text-neutral-600 font-medium mt-0.5"
                >
                  <Icon icon="lucide:image" class="text-xs" aria-hidden="true" />
                  <span>Receipt Image</span>
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
              v-if="paginatedRequests.length === 0"
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
