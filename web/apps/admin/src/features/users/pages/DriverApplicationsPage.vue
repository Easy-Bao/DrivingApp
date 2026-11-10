<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const mockApplications = ref([
  {
    id: 'APP-901',
    applicant: 'Brandon Lee',
    phone: '+1 (555) 111-2233',
    appliedDate: '2 hours ago',
    city: 'Metro Core',
    backgroundStatus: 'Passed',
    vehicle: 'Tesla Model 3',
  },
  {
    id: 'APP-902',
    applicant: 'Fatima Al-Mansoor',
    phone: '+1 (555) 444-5566',
    appliedDate: '5 hours ago',
    city: 'North District',
    backgroundStatus: 'Pending',
    vehicle: 'Toyota Prius',
  },
  {
    id: 'APP-903',
    applicant: 'Tyler Brooks',
    phone: '+1 (555) 777-8899',
    appliedDate: 'Yesterday',
    city: 'Westside',
    backgroundStatus: 'Passed',
    vehicle: 'Chevrolet Bolt',
  },
])

const actionToast = ref<string | null>(null)

function approveApplication(app: (typeof mockApplications.value)[0]) {
  actionToast.value = `Application ${app.id} for ${app.applicant} approved! Driver credentials dispatched.`
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">Driver Applications Queue</h1>
      <p class="text-sm text-neutral-500 mt-1">
        Review applicant qualifications, background screenings, and vehicle registrations before
        issuing credentials.
      </p>
    </div>

    <div
      v-if="actionToast"
      class="p-4 rounded-xl bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:check-circle" class="text-emerald-400 text-base" />
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null"><Icon icon="lucide:x" /></button>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Pending Onboarding Submissions (8)</h2>
        <span class="text-xs text-neutral-400"
          >Background checks handled via regulatory check api</span
        >
      </div>

      <table class="w-full text-left text-xs">
        <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
          <tr>
            <th class="py-3 px-4">Application ID</th>
            <th class="py-3 px-4">Applicant</th>
            <th class="py-3 px-4">Region</th>
            <th class="py-3 px-4">Vehicle Offered</th>
            <th class="py-3 px-4">Background Screening</th>
            <th class="py-3 px-4 text-right">Decision</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100 text-neutral-700">
          <tr v-for="app in mockApplications" :key="app.id" class="hover:bg-neutral-50/50">
            <td class="py-3 px-4 font-mono font-bold">{{ app.id }}</td>
            <td class="py-3 px-4">
              <span class="font-semibold text-neutral-900">{{ app.applicant }}</span>
              <div class="text-[11px] text-neutral-400">
                {{ app.phone }} · {{ app.appliedDate }}
              </div>
            </td>
            <td class="py-3 px-4">{{ app.city }}</td>
            <td class="py-3 px-4">{{ app.vehicle }}</td>
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
            <td class="py-3 px-4 text-right space-x-2 whitespace-nowrap">
              <button
                type="button"
                class="px-3 py-1.5 bg-neutral-900 text-white rounded-lg text-xs font-semibold hover:bg-neutral-800"
                @click="approveApplication(app)"
              >
                Approve Driver
              </button>
              <button
                type="button"
                class="px-3 py-1.5 border border-neutral-200 text-neutral-600 rounded-lg text-xs font-medium hover:bg-neutral-50"
              >
                Reject
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
