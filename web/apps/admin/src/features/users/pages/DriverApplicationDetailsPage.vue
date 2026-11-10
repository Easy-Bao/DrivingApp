<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useDriverApplications } from '@/features/users/composables/useDriverApplications'

const route = useRoute()
const router = useRouter()
const { getApplicationById, approveApplication, rejectApplication } = useDriverApplications()

const applicationId = computed(() => (route.params.id as string) || '')
const application = computed(() => getApplicationById(applicationId.value))

const actionToast = ref<string | null>(null)

function handleApprove() {
  if (!application.value) return
  approveApplication(application.value)
  actionToast.value = `Driver Application ${application.value.id} for ${application.value.applicant} approved! Driver credentials and welcome instructions dispatched.`
}

function handleReject() {
  if (!application.value) return
  rejectApplication(application.value, 'Documentation review failed regulatory compliance')
  actionToast.value = `Application ${application.value.id} has been marked as Rejected.`
}

function goBack() {
  if (window.history.state && window.history.state.back) {
    router.back()
  } else {
    void router.push('/users/driver-applications')
  }
}
</script>

<template>
  <div class="space-y-6 max-w-4xl">
    <!-- Back Button: Inside the page content area (not in header or breadcrumbs) -->
    <div>
      <button
        type="button"
        class="inline-flex items-center space-x-2 text-xs font-semibold text-neutral-700 hover:text-neutral-900 bg-white border border-neutral-200 hover:bg-neutral-50 px-3 py-1.5 rounded-lg shadow-2xs transition-colors group cursor-pointer"
        @click="goBack"
      >
        <Icon
          icon="lucide:arrow-left"
          class="text-sm text-neutral-500 group-hover:text-neutral-900 transition-transform group-hover:-translate-x-0.5"
        />
        <span>Back to Driver Applications</span>
      </button>
    </div>

    <!-- Alert / Toast Banner -->
    <div
      v-if="actionToast"
      class="p-4 rounded-xl bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:check-circle" class="text-emerald-400 text-base" />
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <!-- Application Details Card if found -->
    <div v-if="application" class="space-y-6">
      <!-- Title & Status Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div class="flex items-center space-x-3">
            <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
              Application {{ application.id }}
            </h1>
            <span
              class="px-2.5 py-0.5 rounded-full text-xs font-bold"
              :class="{
                'bg-emerald-100 text-emerald-800': application.status === 'Approved',
                'bg-rose-100 text-rose-800': application.status === 'Rejected',
                'bg-amber-100 text-amber-800': application.status === 'Pending Review',
              }"
            >
              {{ application.status }}
            </span>
          </div>
          <p class="text-sm text-neutral-500 mt-1">
            Submitted {{ application.appliedDate }} for {{ application.city }} operating zone.
          </p>
        </div>

        <div class="flex items-center space-x-2">
          <span
            class="px-3 py-1.5 rounded-lg text-xs font-semibold border flex items-center space-x-1.5"
            :class="
              application.backgroundStatus === 'Passed'
                ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                : 'bg-amber-50 text-amber-700 border-amber-200'
            "
          >
            <Icon
              :icon="
                application.backgroundStatus === 'Passed'
                  ? 'lucide:shield-check'
                  : 'lucide:shield-alert'
              "
              class="text-sm"
            />
            <span>Screening: {{ application.backgroundStatus }}</span>
          </span>
        </div>
      </div>

      <!-- Applicant Identity Section -->
      <div class="bg-white border border-neutral-200 rounded-xl p-5 shadow-2xs space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <div class="flex items-center space-x-3">
            <div
              class="w-10 h-10 rounded-full bg-neutral-900 text-white flex items-center justify-center font-bold text-sm"
            >
              {{ application.applicant.charAt(0) }}
            </div>
            <div>
              <h2 class="font-bold text-sm text-neutral-900">{{ application.applicant }}</h2>
              <p class="text-xs text-neutral-500">{{ application.email }}</p>
            </div>
          </div>
          <div class="text-right text-xs">
            <span class="text-neutral-400">Phone: </span>
            <span class="font-semibold text-neutral-800">{{ application.phone }}</span>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Assigned Operating City</div>
            <div class="font-semibold text-neutral-900 mt-0.5">{{ application.city }}</div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Driver's License Number</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ application.licenseNumber }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">License Expiration</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ application.licenseExpiry }}
            </div>
          </div>
        </div>

        <div
          class="p-3 rounded-lg bg-neutral-50 border border-neutral-200 flex items-center justify-between text-xs"
        >
          <div class="flex items-center space-x-2">
            <Icon icon="lucide:file-text" class="text-neutral-500 text-sm" />
            <span class="font-medium text-neutral-700"
              >Driver License File: {{ application.licenseDoc }}</span
            >
          </div>
          <span class="text-[11px] font-semibold text-emerald-600 flex items-center space-x-1">
            <Icon icon="lucide:check" class="text-xs" />
            <span>Document Verified</span>
          </span>
        </div>
      </div>

      <!-- Vehicle & Registration Section -->
      <div class="bg-white border border-neutral-200 rounded-xl p-5 shadow-2xs space-y-4">
        <div class="flex items-center space-x-2 pb-3 border-b border-neutral-100">
          <Icon icon="lucide:car" class="text-neutral-500 text-base" />
          <h2 class="font-bold text-sm text-neutral-900">Vehicle Specification & Insurance</h2>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Vehicle Make & Model</div>
            <div class="font-semibold text-neutral-900 mt-0.5">
              {{ application.vehicle.year }} {{ application.vehicle.make }}
              {{ application.vehicle.model }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">License Plate</div>
            <div class="font-mono font-bold text-neutral-900 mt-0.5">
              {{ application.vehicle.plate }} ({{ application.vehicle.color }})
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Vehicle Identification (VIN)</div>
            <div class="font-mono text-neutral-700 mt-0.5">{{ application.vehicle.vin }}</div>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs pt-2">
          <div
            class="p-3 rounded-lg bg-neutral-50 border border-neutral-200 flex items-center justify-between"
          >
            <div>
              <div class="text-[11px] text-neutral-400">Commercial Auto Policy</div>
              <div class="font-semibold text-neutral-800 mt-0.5">
                {{ application.vehicle.insurancePolicy }}
              </div>
            </div>
            <Icon icon="lucide:shield-check" class="text-emerald-500 text-base" />
          </div>

          <div
            class="p-3 rounded-lg bg-neutral-50 border border-neutral-200 flex items-center justify-between"
          >
            <div>
              <div class="text-[11px] text-neutral-400">Annual Safety Certificate</div>
              <div class="font-mono text-neutral-800 mt-0.5">
                {{ application.vehicle.inspectionDoc }}
              </div>
            </div>
            <Icon icon="lucide:file-check" class="text-emerald-500 text-base" />
          </div>
        </div>
      </div>

      <!-- Regulatory Background Verification Section -->
      <div class="bg-white border border-neutral-200 rounded-xl p-5 shadow-2xs space-y-4">
        <div class="flex items-center space-x-2 pb-3 border-b border-neutral-100">
          <Icon icon="lucide:shield" class="text-neutral-500 text-base" />
          <h2 class="font-bold text-sm text-neutral-900">Background & Motor Vehicle Screening</h2>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Audited By</div>
            <div class="font-semibold text-neutral-900 mt-0.5">
              {{ application.backgroundProvider }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Screening Status</div>
            <div
              class="font-bold mt-0.5"
              :class="
                application.backgroundStatus === 'Passed' ? 'text-emerald-600' : 'text-amber-600'
              "
            >
              {{ application.backgroundStatus }}
            </div>
          </div>
        </div>

        <div class="p-4 rounded-xl bg-neutral-50 border border-neutral-200 space-y-1 text-xs">
          <div class="font-semibold text-neutral-900 flex items-center space-x-1.5">
            <Icon icon="lucide:info" class="text-neutral-400" />
            <span>Auditor Verification Remarks</span>
          </div>
          <p class="text-neutral-600 leading-relaxed">{{ application.backgroundNotes }}</p>
        </div>
      </div>

      <!-- Action Footer -->
      <div
        class="bg-white border border-neutral-200 rounded-xl p-4 shadow-2xs flex items-center justify-between"
      >
        <div class="text-xs text-neutral-500">
          <span v-if="application.status === 'Pending Review'">
            Carefully verify background checks and safety inspection before approving driver access.
          </span>
          <span
            v-else-if="application.status === 'Approved'"
            class="text-emerald-600 font-semibold"
          >
            ✓ Driver application has been approved and activated.
          </span>
          <span v-else class="text-rose-600 font-semibold"> ✕ Application was rejected. </span>
        </div>

        <div v-if="application.status === 'Pending Review'" class="flex items-center space-x-3">
          <button
            type="button"
            class="px-4 py-2 border border-rose-200 text-rose-700 hover:bg-rose-50 rounded-lg text-xs font-semibold transition-colors cursor-pointer"
            @click="handleReject"
          >
            Reject Application
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-lg text-xs font-semibold transition-colors shadow-xs cursor-pointer"
            @click="handleApprove"
          >
            Approve Driver & Issue Credentials
          </button>
        </div>
      </div>
    </div>

    <!-- Application Not Found Fallback -->
    <div
      v-else
      class="bg-white border border-neutral-200 rounded-xl p-8 text-center text-xs text-neutral-500 shadow-2xs"
    >
      <Icon icon="lucide:alert-circle" class="text-2xl text-neutral-400 mx-auto mb-2" />
      <p class="font-semibold text-neutral-900">Application Not Found</p>
      <p class="mt-1">No driver application matches ID {{ applicationId }}.</p>
      <button
        type="button"
        class="mt-4 px-3 py-1.5 bg-neutral-900 text-white rounded-lg text-xs font-semibold cursor-pointer"
        @click="goBack"
      >
        Back to Applications Queue
      </button>
    </div>
  </div>
</template>
