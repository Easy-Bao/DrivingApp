<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useTopups, type TopUpRequest } from '@/features/payments/composables/useTopups'
import StatusBadge, { type BadgeTone } from '@/shared/components/StatusBadge.vue'
import TablePagination from '@/app/components/TablePagination.vue'
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
  return topUpRequests.value.filter((req) => {
    const matchesMethod = filterMethod.value === 'All' || req.paymentMethod === filterMethod.value
    const matchesStatus = filterStatus.value === 'All' || req.status === filterStatus.value
    const matchesQuery =
      !query ||
      req.id.toLowerCase().includes(query) ||
      req.driverName.toLowerCase().includes(query) ||
      req.driverPhone.toLowerCase().includes(query) ||
      req.vehiclePlate.toLowerCase().includes(query) ||
      req.referenceCode.toLowerCase().includes(query)
    return matchesMethod && matchesStatus && matchesQuery
  })
})

const paginatedRequests = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredRequests.value.slice(start, start + itemsPerPage)
})

const pendingCount = computed(
  () => topUpRequests.value.filter((req) => req.status === 'Pending').length,
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
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Driver Wallet Top-Ups
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Verify driver GCash, Maya QRPh, and Philippine bank transfer receipts before crediting
          prepaid commission wallets.
        </p>
      </div>

      <div class="flex items-center space-x-3 shrink-0">
        <RouterLink
          to="/payments/methods"
          class="inline-flex items-center space-x-1.5 px-3 py-1.5 border border-neutral-200 bg-white hover:bg-neutral-50 text-xs font-semibold text-neutral-700 transition-colors"
        >
          <Icon icon="lucide:qr-code" class="text-sm text-neutral-500" aria-hidden="true" />
          <span>Manage Company Bank &amp; QR</span>
        </RouterLink>
      </div>
    </div>

    <div class="bg-blue-50/70 border border-blue-200 p-4 text-xs text-blue-900 leading-relaxed">
      <span class="font-bold">Manual Settlement Process:</span>
      Taxicle drivers transfer funds via company QRPh or bank deposit from the driver app and attach
      their transaction receipt image. Open any request below to inspect the uploaded proof image
      and reference code before releasing wallet credits.
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3"
      >
        <div class="flex items-center space-x-3">
          <h2 class="font-bold text-sm text-neutral-900">Driver Top-Up Submissions</h2>
          <span class="px-2 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-800">
            {{ pendingCount }} Pending
          </span>
        </div>

        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="relative sm:w-64">
            <Icon
              icon="lucide:search"
              class="absolute left-3 top-2.5 text-neutral-400 text-sm"
              aria-hidden="true"
            />
            <input
              v-model="searchQuery"
              type="text"
              aria-label="Search top-up requests"
              placeholder="Search driver, +63 phone, plate, ref..."
              class="w-full pl-9 pr-3 py-1.5 bg-neutral-50 border border-neutral-200 text-xs focus:outline-none focus:border-neutral-900"
            />
          </div>

          <select
            v-model="filterMethod"
            aria-label="Filter by payment method"
            class="px-3 py-1.5 bg-white border border-neutral-200 text-xs font-medium text-neutral-900"
          >
            <option value="All">All Payment Methods</option>
            <option value="Company QR Code">Company QR Code</option>
            <option value="Company Bank Transfer">Company Bank Transfer</option>
          </select>

          <select
            v-model="filterStatus"
            aria-label="Filter by request status"
            class="px-3 py-1.5 bg-white border border-neutral-200 text-xs font-medium text-neutral-900"
          >
            <option value="All">All Statuses</option>
            <option value="Pending">Pending</option>
            <option value="Verified">Verified</option>
            <option value="Rejected">Rejected</option>
          </select>
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
                  :class="req.currentBalance < 50 ? 'text-rose-600 font-bold' : 'text-neutral-900'"
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
                  class="inline-flex items-center gap-1 text-[11px] text-emerald-700 font-medium mt-0.5"
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
            <tr v-if="paginatedRequests.length === 0">
              <td colspan="8" class="py-10 px-4 text-center text-xs text-neutral-500">
                No top-up requests match the selected search and filters.
              </td>
            </tr>
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
