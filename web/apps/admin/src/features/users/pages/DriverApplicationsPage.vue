<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useDriverApplications } from '@/features/users/composables/useDriverApplications'

const router = useRouter()
const { applications } = useDriverApplications()

function navigateToDetails(id: string) {
  void router.push(`/users/driver-applications/${id}`)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Driver Applications Queue
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Review applicant qualifications, background screenings, and vehicle registrations before
          issuing credentials.
        </p>
      </div>

      <div class="flex items-center space-x-3">
        <span
          class="px-3 py-1.5 bg-amber-50 border border-amber-200 text-xs font-semibold text-amber-800"
        >
          {{ applications.filter((a) => a.status === 'Pending Review').length }} Pending
          Applications
        </span>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Onboarding Submissions Queue</h2>
        <span class="text-xs text-neutral-400"
          >Background checks handled via regulatory check api</span
        >
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">Application ID</th>
              <th class="py-3 px-4">Applicant</th>
              <th class="py-3 px-4">Region</th>
              <th class="py-3 px-4">Vehicle Offered</th>
              <th class="py-3 px-4">Background Screening</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr v-for="app in applications" :key="app.id" class="hover:bg-neutral-50/50">
              <td class="py-3 px-4 font-mono font-bold">{{ app.id }}</td>
              <td class="py-3 px-4">
                <span class="font-semibold text-neutral-900">{{ app.applicant }}</span>
                <div class="text-[11px] text-neutral-400">
                  {{ app.phone }} · {{ app.appliedDate }}
                </div>
              </td>
              <td class="py-3 px-4">{{ app.city }}</td>
              <td class="py-3 px-4">
                {{ app.vehicle.make }} {{ app.vehicle.model }} ({{ app.vehicle.year }})
              </td>
              <td class="py-3 px-4">
                <span
                  class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                  :class="
                    app.backgroundStatus === 'Passed'
                      ? 'bg-emerald-100 text-emerald-800'
                      : 'bg-amber-100 text-amber-800'
                  "
                >
                  {{ app.backgroundStatus }}
                </span>
              </td>
              <td class="py-3 px-4">
                <span
                  class="px-2 py-0.5 rounded-full text-[10px] font-bold"
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
                  <span>View Details</span>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
