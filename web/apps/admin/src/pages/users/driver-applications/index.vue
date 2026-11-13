<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useDriverApplications } from '@/features/users/composables/useDriverApplications'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import EmptyTableRow from '@/shared/components/EmptyTableRow.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import SearchField from '@/shared/components/SearchField.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import TablePagination from '@/shared/components/TablePagination.vue'

const router = useRouter()
const { applications } = useDriverApplications()

const searchQuery = ref('')
const statusFilter = ref<'ALL' | 'Pending Review' | 'Approved' | 'Rejected'>('ALL')
const currentPage = ref(1)
const itemsPerPage = 10

const statusOptions = [
  { label: 'All Statuses', value: 'ALL' },
  { label: 'Pending Review', value: 'Pending Review' },
  { label: 'Approved', value: 'Approved' },
  { label: 'Rejected', value: 'Rejected' },
]

const filteredApplications = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return applications.value.filter((application) => {
    const matchesStatus = statusFilter.value === 'ALL' || application.status === statusFilter.value
    const matchesQuery =
      !query ||
      application.id.toLowerCase().includes(query) ||
      application.applicant.toLowerCase().includes(query) ||
      application.phone.toLowerCase().includes(query) ||
      application.city.toLowerCase().includes(query) ||
      application.barangay.toLowerCase().includes(query) ||
      application.vehicle.plate.toLowerCase().includes(query) ||
      application.vehicle.model.toLowerCase().includes(query)
    return matchesStatus && matchesQuery
  })
})

const pendingCount = computed(
  () => applications.value.filter((application) => application.status === 'Pending Review').length,
)

const hasActiveFilters = computed(() => searchQuery.value !== '' || statusFilter.value !== 'ALL')

const paginatedApplications = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredApplications.value.slice(start, start + itemsPerPage)
})

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'ALL'
  currentPage.value = 1
}

function getStatusTone(status: 'Pending Review' | 'Approved' | 'Rejected') {
  if (status === 'Approved') return 'success'
  if (status === 'Rejected') return 'danger'
  return 'warning'
}

function navigateToDetails(id: string) {
  void router.push(`/users/driver-applications/${id}`)
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Driver Applications Queue"
      description="Applicant qualifications, LTO licenses, and 3-wheeled Taxicle franchise permits."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col lg:flex-row lg:items-center justify-between gap-3"
      >
        <div class="flex flex-wrap items-center gap-2">
          <div class="w-full sm:w-64">
            <SearchField
              v-model="searchQuery"
              placeholder="Search applicant, plate, city..."
              aria-label="Search driver applications"
              @update:model-value="currentPage = 1"
            />
          </div>
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter applications by status"
            :options="statusOptions"
            @update:model-value="currentPage = 1"
          />
        </div>
        <span
          class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold tabular-nums text-neutral-800 self-start lg:self-auto"
        >
          Pending: {{ pendingCount }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[840px] text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">Application ID</th>
              <th class="py-3 px-4">Driver Applicant</th>
              <th class="py-3 px-4">Date Applied</th>
              <th class="py-3 px-4">City / Barangay</th>
              <th class="py-3 px-4">3-Wheeled Unit & Body No.</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr
              v-for="application in paginatedApplications"
              :key="application.id"
              class="hover:bg-neutral-50/50 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900 whitespace-nowrap">
                {{ application.id }}
              </td>
              <td class="py-3 px-4">
                <div class="flex items-center space-x-2.5">
                  <img
                    :src="application.facePhotoUrl"
                    :alt="application.applicant"
                    class="w-7 h-7 object-cover bg-neutral-900 border border-neutral-300 shrink-0"
                  />
                  <div>
                    <span class="font-semibold text-neutral-900 block">{{
                      application.applicant
                    }}</span>
                    <span class="text-[11px] text-neutral-400 font-mono">{{
                      application.phone
                    }}</span>
                  </div>
                </div>
              </td>
              <td class="py-3 px-4 whitespace-nowrap">
                <div class="font-medium text-neutral-900">{{ application.appliedDate }}</div>
                <div class="text-[11px] text-neutral-400">{{ application.appliedTime }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ application.city }}</div>
                <div class="text-[11px] text-neutral-500">
                  {{ application.barangay }}, {{ application.province }}
                </div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">
                  {{ application.vehicle.make }} {{ application.vehicle.model }}
                </div>
                <div class="text-[11px] text-neutral-400 font-mono">
                  {{ application.vehicle.plate }} ({{ application.vehicle.bodyNumber }})
                </div>
              </td>
              <td class="py-3 px-4 whitespace-nowrap">
                <StatusBadge
                  :label="application.status"
                  :tone="getStatusTone(application.status)"
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white font-semibold text-xs transition-colors inline-flex items-center space-x-1 cursor-pointer"
                  @click="navigateToDetails(application.id)"
                >
                  <span>Review Application</span>
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedApplications.length === 0"
              :colspan="7"
              title="No matching driver applications"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredApplications.length"
        :items-per-page="itemsPerPage"
      />
    </div>
  </div>
</template>
