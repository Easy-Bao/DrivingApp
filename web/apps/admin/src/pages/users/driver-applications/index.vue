<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useDriverApplications } from '@/features/users/composables/useDriverApplications'
import TablePagination from '@/shared/components/TablePagination.vue'

const router = useRouter()
const { applications } = useDriverApplications()

const currentPage = ref(1)
const itemsPerPage = 10

const paginatedApplications = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return applications.value.slice(start, start + itemsPerPage)
})

function navigateToDetails(id: string) {
  void router.push(`/users/driver-applications/${id}`)
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Driver Applications Queue
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Applicant qualifications, LTO licenses, and franchise permits.
      </p>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between gap-3">
        <h2 class="font-bold text-sm text-neutral-900">Onboarding Queue</h2>
        <span
          class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold tabular-nums text-neutral-800"
        >
          Pending: {{ applications.filter((a) => a.status === 'Pending Review').length }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">Application ID</th>
              <th class="py-3 px-4">Driver Applicant</th>
              <th class="py-3 px-4">Date Applied</th>
              <th class="py-3 px-4">City / Barangay</th>
              <th class="py-3 px-4">Taxicle Unit & Body No.</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr
              v-for="app in paginatedApplications"
              :key="app.id"
              class="hover:bg-neutral-50/50 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900 whitespace-nowrap">
                {{ app.id }}
              </td>
              <td class="py-3 px-4">
                <div class="flex items-center space-x-2.5">
                  <img
                    :src="app.facePhotoUrl"
                    :alt="app.applicant"
                    class="w-7 h-7 object-cover bg-neutral-900 border border-neutral-300 shrink-0"
                  />
                  <div>
                    <span class="font-semibold text-neutral-900 block">{{ app.applicant }}</span>
                    <span class="text-[11px] text-neutral-400 font-mono">{{ app.phone }}</span>
                  </div>
                </div>
              </td>
              <td class="py-3 px-4 whitespace-nowrap">
                <div class="font-medium text-neutral-900">{{ app.appliedDate }}</div>
                <div class="text-[11px] text-neutral-400">{{ app.appliedTime }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ app.city }}</div>
                <div class="text-[11px] text-neutral-500">
                  {{ app.barangay }}, {{ app.province }}
                </div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">
                  {{ app.vehicle.make }} {{ app.vehicle.model }}
                </div>
                <div class="text-[11px] text-neutral-400 font-mono">
                  {{ app.vehicle.plate }} ({{ app.vehicle.bodyNumber }})
                </div>
              </td>
              <td class="py-3 px-4 whitespace-nowrap">
                <span
                  class="px-2 py-0.5 rounded-none text-[10px] font-bold"
                  :class="{
                    'bg-emerald-100 text-emerald-800': app.status === 'Approved',
                    'bg-rose-100 text-rose-800': app.status === 'Rejected',
                    'bg-amber-100 text-amber-800': app.status === 'Pending Review',
                  }"
                >
                  {{ app.status }}
                </span>
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white font-semibold text-xs transition-colors inline-flex items-center space-x-1 cursor-pointer"
                  @click="navigateToDetails(app.id)"
                >
                  <span>Review Application</span>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="applications.length"
        :items-per-page="itemsPerPage"
      />
    </div>
  </div>
</template>
