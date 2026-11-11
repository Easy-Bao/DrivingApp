<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { useDriverApplications } from '@/features/users/composables/useDriverApplications'

const route = useRoute()
const router = useRouter()
const { getApplicationById, approveApplication, rejectApplication } = useDriverApplications()

const applicationId = computed(() => (route.params.id as string) || '')
const application = computed(() => getApplicationById(applicationId.value))

interface ViewerDocument {
  title: string
  subtitle: string
  type: 'license' | 'taxicle_orcr' | 'clearance' | 'face'
  frontUrl?: string
  backUrl?: string
  activeSide?: 'front' | 'back'
  metadata?: Record<string, string>
}

const activeViewerDoc = ref<ViewerDocument | null>(null)
const licenseSlideDirection = ref<'flip-left' | 'flip-right'>('flip-left')

const showApproveDialog = ref(false)
const showRejectDialog = ref(false)
const rejectReason = ref('Incomplete or unreadable LTO driver license scan')
const rejectNotes = ref('')

function setLicenseSide(side: 'front' | 'back') {
  if (!activeViewerDoc.value || side === activeViewerDoc.value.activeSide) return
  licenseSlideDirection.value = side === 'back' ? 'flip-left' : 'flip-right'
  activeViewerDoc.value.activeSide = side
}

function openLicenseViewer() {
  if (!application.value) return
  licenseSlideDirection.value = 'flip-left'
  activeViewerDoc.value = {
    title: "Driver's License",
    subtitle: `${application.value.licenseType} · ${application.value.licenseNumber}`,
    type: 'license',
    frontUrl: application.value.licenseFrontDoc,
    backUrl: application.value.licenseBackDoc,
    activeSide: 'front',
    metadata: {
      'License Number': application.value.licenseNumber,
      'Classification': application.value.licenseType,
      'Authorized DL Code': application.value.licenseCodes,
      'Expiration Date': application.value.licenseExpiry,
      'Issuing Agency': 'Land Transportation Office (LTO Philippines)',
    },
  }
}

function openTaxicleDocViewer(docType: 'OR' | 'CR') {
  if (!application.value) return
  const isOR = docType === 'OR'
  activeViewerDoc.value = {
    title: isOR ? 'LTO Official Receipt (OR)' : 'LTO Certificate of Registration (CR)',
    subtitle: isOR ? application.value.vehicle.orNumber : application.value.vehicle.crNumber,
    type: 'taxicle_orcr',
    metadata: {
      'Document No.': isOR
        ? application.value.vehicle.orNumber
        : application.value.vehicle.crNumber,
      'Taxicle Plate': application.value.vehicle.plate,
      'TODA Association': application.value.vehicle.todaFranchise,
      'MTOP Permit': application.value.vehicle.mtopNumber,
      'Engine Number': application.value.vehicle.engineNumber,
      'Chassis Number': application.value.vehicle.chassisNumber,
    },
  }
}

function openClearanceViewer() {
  if (!application.value) return
  activeViewerDoc.value = {
    title: application.value.clearanceType,
    subtitle: `Reference No: ${application.value.clearanceNumber}`,
    type: 'clearance',
    metadata: {
      'Clearance ID': application.value.clearanceNumber,
      'Issuing Body': application.value.backgroundProvider,
      'Screening Status': application.value.backgroundStatus,
      'Auditor Finding': application.value.backgroundNotes,
    },
  }
}

function openFacePhotoViewer() {
  if (!application.value) return
  activeViewerDoc.value = {
    title: 'Driver Biometric Face Photo',
    subtitle: `${application.value.applicant} · ${application.value.phone}`,
    type: 'face',
    metadata: {
      'Applicant': application.value.applicant,
      'Mobile Number (PH)': application.value.phone,
      'Operating Region': application.value.city,
    },
  }
}

function closeViewer() {
  activeViewerDoc.value = null
}

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') {
    if (showApproveDialog.value) showApproveDialog.value = false
    else if (showRejectDialog.value) showRejectDialog.value = false
    else if (activeViewerDoc.value) closeViewer()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})

function openApproveDialog() {
  showApproveDialog.value = true
}

function confirmApprove() {
  if (!application.value) return
  approveApplication(application.value)
  showApproveDialog.value = false
}

function openRejectDialog() {
  rejectReason.value = 'Incomplete or unreadable LTO driver license scan'
  rejectNotes.value = ''
  showRejectDialog.value = true
}

function confirmReject() {
  if (!application.value) return
  const fullReason = rejectNotes.value.trim()
    ? `${rejectReason.value}: ${rejectNotes.value.trim()}`
    : rejectReason.value
  rejectApplication(application.value, fullReason)
  showRejectDialog.value = false
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
  <div class="space-y-6 w-full">
    <div>
      <button
        type="button"
        class="inline-flex items-center space-x-1.5 text-xs font-semibold text-neutral-700 hover:text-neutral-900 bg-white border border-neutral-200 hover:bg-neutral-50 px-3 py-1.5 transition-colors group cursor-pointer"
        @click="goBack"
      >
        <Icon
          icon="lucide:arrow-left"
          class="text-sm text-neutral-500 group-hover:text-neutral-900 transition-transform group-hover:-translate-x-0.5"
        />
        <span>Back</span>
      </button>
    </div>

    <div v-if="application" class="space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div class="flex items-center space-x-3">
            <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
              Application {{ application.id }}
            </h1>
            <span
              class="px-2.5 py-0.5 text-xs font-bold"
              :class="{
                'bg-emerald-100 text-emerald-800 border border-emerald-200':
                  application.status === 'Approved',
                'bg-rose-100 text-rose-800 border border-rose-200':
                  application.status === 'Rejected',
                'bg-amber-100 text-amber-800 border border-amber-200':
                  application.status === 'Pending Review',
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
            class="px-3 py-1.5 text-xs font-semibold border flex items-center space-x-1.5"
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
            <span>Clearance: {{ application.backgroundStatus }}</span>
          </span>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div
          class="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-neutral-100 gap-4"
        >
          <div class="flex items-center space-x-4">
            <button
              type="button"
              class="relative w-16 h-16 bg-neutral-900 border border-neutral-300 overflow-hidden shrink-0 group cursor-pointer"
              title="Click to view full-size photo"
              @click="openFacePhotoViewer"
            >
              <img
                :src="application.facePhotoUrl"
                :alt="application.applicant"
                class="w-full h-full object-cover group-hover:scale-105 transition-transform"
              />
              <div
                class="absolute inset-0 bg-neutral-900/30 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity"
              >
                <Icon icon="lucide:zoom-in" class="text-white text-base" />
              </div>
            </button>

            <div>
              <div class="flex items-center space-x-2">
                <h2 class="font-bold text-base text-neutral-900">{{ application.applicant }}</h2>
                <span
                  class="px-2 py-0.5 text-[10px] font-semibold bg-neutral-100 text-neutral-700 border border-neutral-200"
                >
                  Taxicle Operator
                </span>
              </div>
              <p class="text-xs text-neutral-500 mt-0.5">{{ application.email }}</p>
              <p class="text-xs font-mono font-semibold text-neutral-800 mt-0.5">
                {{ application.phone }}
              </p>
            </div>
          </div>

          <div class="text-left sm:text-right text-xs">
            <span class="text-neutral-400">Operating Territory</span>
            <div class="font-semibold text-neutral-900 mt-0.5">{{ application.city }}</div>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs pt-1">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Assigned TODA / City</div>
            <div class="font-semibold text-neutral-900 mt-0.5">{{ application.city }}</div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Contact Phone (PH Mobile)</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ application.phone }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Driver Face Verification</div>
            <div class="text-emerald-700 font-semibold mt-0.5 flex items-center space-x-1">
              <Icon icon="lucide:check-circle" class="text-xs" />
              <span>Biometric Photo Verified</span>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">
            Driver's License
          </h2>
          <button
            type="button"
            class="px-3 py-1.5 text-xs font-semibold bg-neutral-900 hover:bg-neutral-800 text-white transition-colors cursor-pointer"
            @click="openLicenseViewer"
          >
            View License
          </button>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-4 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">LTO License Number</div>
            <div class="font-mono font-bold text-neutral-900 mt-0.5">
              {{ application.licenseNumber }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Classification</div>
            <div class="font-semibold text-neutral-900 mt-0.5">
              {{ application.licenseType }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Authorized DL Code</div>
            <div class="font-mono font-bold text-neutral-900 mt-0.5">
              {{ application.licenseCodes }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Expiration Date</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ application.licenseExpiry }}
            </div>
          </div>
        </div>

        <div
          class="p-3 bg-neutral-50 border border-neutral-200 flex items-center justify-between text-xs hover:border-neutral-400 transition-colors cursor-pointer"
          @click="openLicenseViewer"
        >
          <div class="flex items-center space-x-2">
            <span class="font-medium text-neutral-800">Official License Scans</span>
            <span class="text-[11px] font-mono text-neutral-400">· {{ application.licenseFrontDoc }}</span>
          </div>
          <span class="text-xs font-semibold text-neutral-900 hover:underline">
            View License Scan →
          </span>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">
            Vehicle Specification & Franchise
          </h2>
          <span
            class="text-xs font-semibold px-2 py-0.5 bg-neutral-100 text-neutral-700 border border-neutral-200"
          >
            {{ application.vehicle.type }}
          </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Tricycle Make & Model</div>
            <div class="font-semibold text-neutral-900 mt-0.5">
              {{ application.vehicle.year }} {{ application.vehicle.make }} {{ application.vehicle.model }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Plate & Body / Sidecar No.</div>
            <div class="font-mono font-bold text-neutral-900 mt-0.5">
              {{ application.vehicle.plate }} · {{ application.vehicle.bodyNumber }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">TODA Franchise Association</div>
            <div class="font-semibold text-neutral-800 mt-0.5">
              {{ application.vehicle.todaFranchise }}
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs pt-1">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">MTOP Municipal Permit No.</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ application.vehicle.mtopNumber }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Engine Number</div>
            <div class="font-mono text-neutral-700 mt-0.5">{{ application.vehicle.engineNumber }}</div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Chassis / Frame Number</div>
            <div class="font-mono text-neutral-700 mt-0.5">{{ application.vehicle.chassisNumber }}</div>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs pt-2">
          <div
            class="p-3 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer group"
            @click="openTaxicleDocViewer('OR')"
          >
            <div>
              <div class="text-[11px] text-neutral-400 font-medium">LTO Official Receipt (OR)</div>
              <div class="font-mono font-semibold text-neutral-800 mt-0.5">
                {{ application.vehicle.orNumber }}
              </div>
              <div class="text-[11px] text-neutral-500 mt-0.5 font-mono">
                {{ application.vehicle.orDoc }}
              </div>
            </div>
            <span
              class="text-xs font-semibold text-neutral-900 group-hover:underline flex items-center space-x-1"
            >
              <span>View OR</span>
              <Icon icon="lucide:external-link" class="text-xs" />
            </span>
          </div>

          <div
            class="p-3 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer group"
            @click="openTaxicleDocViewer('CR')"
          >
            <div>
              <div class="text-[11px] text-neutral-400 font-medium">LTO Certificate of Registration (CR)</div>
              <div class="font-mono font-semibold text-neutral-800 mt-0.5">
                {{ application.vehicle.crNumber }}
              </div>
              <div class="text-[11px] text-neutral-500 mt-0.5 font-mono">
                {{ application.vehicle.crDoc }}
              </div>
            </div>
            <span
              class="text-xs font-semibold text-neutral-900 group-hover:underline flex items-center space-x-1"
            >
              <span>View CR</span>
              <Icon icon="lucide:external-link" class="text-xs" />
            </span>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs pt-1">
          <div class="p-3 bg-neutral-50 border border-neutral-200 flex items-center justify-between">
            <div>
              <div class="text-[11px] text-neutral-400">Compulsory Third-Party Liability (CTPL)</div>
              <div class="font-semibold text-neutral-800 mt-0.5">
                {{ application.vehicle.insurancePolicy }}
              </div>
            </div>
            <span class="text-[11px] font-semibold text-emerald-700">Active Policy</span>
          </div>

          <div class="p-3 bg-neutral-50 border border-neutral-200 flex items-center justify-between">
            <div>
              <div class="text-[11px] text-neutral-400">Roadworthiness & TRU Inspection Certificate</div>
              <div class="font-mono text-neutral-800 mt-0.5">
                {{ application.vehicle.inspectionDoc }}
              </div>
            </div>
            <span class="text-[11px] font-semibold text-emerald-700">Inspected</span>
          </div>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <h2 class="font-bold text-sm text-neutral-900">
            Regulatory Background Screening
          </h2>
          <button
            type="button"
            class="px-2.5 py-1 text-xs font-semibold bg-neutral-100 hover:bg-neutral-200 text-neutral-800 border border-neutral-200 flex items-center space-x-1 cursor-pointer transition-colors"
            @click="openClearanceViewer"
          >
            <span>View Clearance Certificate</span>
          </button>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Clearance Agency / Authority</div>
            <div class="font-semibold text-neutral-900 mt-0.5">
              {{ application.backgroundProvider }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Clearance Reference ID</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ application.clearanceNumber }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">Screening Status</div>
            <div
              class="font-bold mt-0.5"
              :class="
                application.backgroundStatus === 'Passed' ? 'text-emerald-700' : 'text-amber-700'
              "
            >
              {{ application.backgroundStatus }}
            </div>
          </div>
        </div>

        <div class="p-3 bg-neutral-50 border border-neutral-200 text-xs">
          <div class="font-semibold text-neutral-900">Official Findings & Remarks</div>
          <p class="text-neutral-600 mt-1 leading-relaxed">{{ application.backgroundNotes }}</p>
        </div>
      </div>

      <div class="bg-white border border-neutral-200 p-4 flex items-center justify-between">
        <div class="text-xs text-neutral-600">
          <span v-if="application.status === 'Pending Review'">
            Carefully verify LTO license, TODA/MTOP franchise, and NBI clearance before issuing driver credentials.
          </span>
          <span v-else-if="application.status === 'Approved'" class="text-emerald-700 font-semibold">
            Application approved. Taxicle driver credentials and dispatch access active.
          </span>
          <span v-else class="text-rose-700 font-semibold">
            Application rejected on regulatory compliance grounds.
          </span>
        </div>

        <div v-if="application.status === 'Pending Review'" class="flex items-center space-x-3">
          <button
            type="button"
            class="px-4 py-2 border border-rose-200 text-rose-700 hover:bg-rose-50 text-xs font-semibold transition-colors cursor-pointer"
            @click="openRejectDialog"
          >
            Reject Application
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="openApproveDialog"
          >
            Approve Driver & Issue Credentials
          </button>
        </div>
      </div>
    </div>

    <div
      v-else
      class="bg-white border border-neutral-200 p-8 text-center text-xs text-neutral-500"
    >
      <p class="font-semibold text-neutral-900">Application Not Found</p>
      <p class="mt-1">No driver application matches ID {{ applicationId }}.</p>
      <button
        type="button"
        class="mt-4 px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold cursor-pointer"
        @click="goBack"
      >
        Back
      </button>
    </div>

    <div
      v-if="showApproveDialog && application"
      class="fixed inset-0 z-50 bg-neutral-900/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto"
      @click.self="showApproveDialog = false"
    >
      <div
        class="bg-white w-full max-w-[500px] border border-neutral-300 shadow-2xl flex flex-col my-auto"
        role="dialog"
        aria-modal="true"
        aria-label="Approve Application Confirmation"
      >
        <div class="px-5 py-4 border-b border-neutral-200 flex items-center justify-between bg-neutral-50">
          <div>
            <h3 class="font-bold text-sm text-neutral-900">Approve Driver Application</h3>
            <p class="text-xs text-neutral-500 mt-0.5">Application {{ application.id }} · {{ application.applicant }}</p>
          </div>
          <button
            type="button"
            class="w-8 h-8 flex items-center justify-center text-neutral-500 hover:text-neutral-900 hover:bg-neutral-200 border border-neutral-200 transition-colors cursor-pointer"
            title="Close dialog (Esc)"
            @click="showApproveDialog = false"
          >
            <Icon icon="lucide:x" class="text-base" />
          </button>
        </div>

        <div class="p-5 space-y-4 text-xs">
          <p class="text-neutral-700 leading-relaxed">
            Are you sure you want to approve this driver application? This will issue platform credentials, grant taxicle dispatch privileges, and notify the driver at <span class="font-mono font-bold text-neutral-900">{{ application.phone }}</span>.
          </p>

          <div class="p-3 bg-emerald-50 border border-emerald-200 text-xs space-y-1">
            <div class="font-semibold text-emerald-900 flex items-center space-x-1.5">
              <Icon icon="lucide:check-circle" class="text-emerald-700" />
              <span>Verified Qualifications Summary</span>
            </div>
            <ul class="text-emerald-800 space-y-0.5 text-[11px] list-disc list-inside">
              <li>LTO License: {{ application.licenseNumber }} (DL Code: {{ application.licenseCodes }})</li>
              <li>Unit: {{ application.vehicle.year }} {{ application.vehicle.make }} {{ application.vehicle.model }} (Plate: {{ application.vehicle.plate }})</li>
              <li>TODA / Franchise: {{ application.vehicle.todaFranchise }}</li>
              <li>Clearance: {{ application.clearanceType }} (Status: {{ application.backgroundStatus }})</li>
            </ul>
          </div>
        </div>

        <div class="px-5 py-3 border-t border-neutral-200 bg-neutral-50 flex items-center justify-end space-x-2">
          <button
            type="button"
            class="px-4 py-2 border border-neutral-300 text-neutral-700 hover:bg-neutral-100 text-xs font-semibold transition-colors cursor-pointer"
            @click="showApproveDialog = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="confirmApprove"
          >
            Confirm & Approve Driver
          </button>
        </div>
      </div>
    </div>

    <div
      v-if="showRejectDialog && application"
      class="fixed inset-0 z-50 bg-neutral-900/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto"
      @click.self="showRejectDialog = false"
    >
      <div
        class="bg-white w-full max-w-[500px] border border-neutral-300 shadow-2xl flex flex-col my-auto"
        role="dialog"
        aria-modal="true"
        aria-label="Reject Application Confirmation"
      >
        <div class="px-5 py-4 border-b border-neutral-200 flex items-center justify-between bg-neutral-50">
          <div>
            <h3 class="font-bold text-sm text-neutral-900">Reject Driver Application</h3>
            <p class="text-xs text-neutral-500 mt-0.5">Application {{ application.id }} · {{ application.applicant }}</p>
          </div>
          <button
            type="button"
            class="w-8 h-8 flex items-center justify-center text-neutral-500 hover:text-neutral-900 hover:bg-neutral-200 border border-neutral-200 transition-colors cursor-pointer"
            title="Close dialog (Esc)"
            @click="showRejectDialog = false"
          >
            <Icon icon="lucide:x" class="text-base" />
          </button>
        </div>

        <div class="p-5 space-y-4 text-xs">
          <p class="text-neutral-700 leading-relaxed">
            Please specify the regulatory compliance or documentation grounds for rejecting this application. This reason will be logged for regulatory audit.
          </p>

          <div class="space-y-1.5">
            <label class="font-semibold text-neutral-800">Primary Rejection Ground</label>
            <select
              v-model="rejectReason"
              class="w-full p-2 bg-neutral-50 border border-neutral-200 text-xs text-neutral-800 focus:outline-none focus:ring-1 focus:ring-neutral-900"
            >
              <option value="Incomplete or unreadable LTO driver license scan">Incomplete or unreadable LTO driver license scan</option>
              <option value="Expired or unverified MTOP municipal tricycle permit">Expired or unverified MTOP municipal tricycle permit</option>
              <option value="TODA franchise association endorsement missing or invalid">TODA franchise association endorsement missing or invalid</option>
              <option value="Failed NBI or PNP criminal background screening">Failed NBI or PNP criminal background screening</option>
              <option value="Mismatched vehicle registration (OR/CR) details">Mismatched vehicle registration (OR/CR) details</option>
              <option value="Other regulatory compliance deficiency">Other regulatory compliance deficiency</option>
            </select>
          </div>

          <div class="space-y-1.5">
            <label class="font-semibold text-neutral-800">Auditor Notes (Optional)</label>
            <textarea
              v-model="rejectNotes"
              rows="3"
              placeholder="Provide specific details or instructions for driver re-submission..."
              class="w-full p-2 bg-neutral-50 border border-neutral-200 text-xs text-neutral-800 focus:outline-none focus:ring-1 focus:ring-neutral-900"
            />
          </div>
        </div>

        <div class="px-5 py-3 border-t border-neutral-200 bg-neutral-50 flex items-center justify-end space-x-2">
          <button
            type="button"
            class="px-4 py-2 border border-neutral-300 text-neutral-700 hover:bg-neutral-100 text-xs font-semibold transition-colors cursor-pointer"
            @click="showRejectDialog = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="confirmReject"
          >
            Confirm Rejection
          </button>
        </div>
      </div>
    </div>

    <div
      v-if="activeViewerDoc"
      class="fixed inset-0 z-50 bg-neutral-900/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto"
      @click.self="closeViewer"
    >
      <div
        class="bg-white w-full max-w-[680px] border border-neutral-300 shadow-2xl flex flex-col my-auto"
        role="dialog"
        aria-modal="true"
        aria-label="Document Viewer"
      >
        <div class="px-5 py-4 border-b border-neutral-200 flex items-center justify-between bg-neutral-50">
          <div>
            <h3 class="font-bold text-sm text-neutral-900">{{ activeViewerDoc.title }}</h3>
            <p class="text-xs text-neutral-500 mt-0.5">{{ activeViewerDoc.subtitle }}</p>
          </div>
          <button
            type="button"
            class="w-8 h-8 flex items-center justify-center text-neutral-500 hover:text-neutral-900 hover:bg-neutral-200 border border-neutral-200 transition-colors cursor-pointer"
            title="Close viewer (Esc)"
            aria-label="Close viewer"
            @click="closeViewer"
          >
            <Icon icon="lucide:x" class="text-base" />
          </button>
        </div>

        <div class="p-5 space-y-4 max-h-[75vh] overflow-y-auto text-xs">
          <div
            v-if="activeViewerDoc.type === 'license'"
            class="flex items-center space-x-2 pb-2 border-b border-neutral-100"
          >
            <button
              type="button"
              class="px-3 py-1.5 font-semibold text-xs border transition-colors cursor-pointer"
              :class="
                activeViewerDoc.activeSide === 'front'
                  ? 'bg-neutral-900 text-white border-neutral-900'
                  : 'bg-white text-neutral-700 border-neutral-200 hover:bg-neutral-100'
              "
              @click="setLicenseSide('front')"
            >
              Front Side
            </button>
            <button
              type="button"
              class="px-3 py-1.5 font-semibold text-xs border transition-colors cursor-pointer"
              :class="
                activeViewerDoc.activeSide === 'back'
                  ? 'bg-neutral-900 text-white border-neutral-900'
                  : 'bg-white text-neutral-700 border-neutral-200 hover:bg-neutral-100'
              "
              @click="setLicenseSide('back')"
            >
              Back Side
            </button>
          </div>

          <div
            class="border border-neutral-200 bg-neutral-100 p-6 flex flex-col items-center justify-center min-h-[220px] overflow-hidden"
          >
            <div v-if="activeViewerDoc.type === 'face' && application" class="text-center">
              <img
                :src="application.facePhotoUrl"
                :alt="application.applicant"
                class="w-40 h-40 object-cover border-2 border-white shadow-md mx-auto"
              />
              <p class="text-xs font-bold text-neutral-900 mt-3">{{ application.applicant }}</p>
              <p class="text-[11px] text-neutral-500 font-mono">{{ application.phone }}</p>
            </div>

            <Transition
              v-else-if="activeViewerDoc.type === 'license' && application"
              :name="licenseSlideDirection"
              mode="out-in"
            >
              <div
                v-if="activeViewerDoc.activeSide === 'front'"
                key="license-front"
                class="w-full max-w-[480px] bg-sky-50 border-2 border-sky-300 p-4 shadow-sm relative overflow-hidden"
              >
                <div class="text-center pb-2 border-b border-sky-200">
                  <div class="text-[10px] uppercase font-bold text-sky-900 tracking-wider">
                    Republic of the Philippines · Department of Transportation
                  </div>
                  <div class="text-xs font-bold text-sky-950 uppercase">
                    Land Transportation Office
                  </div>
                  <div class="text-[10px] font-semibold text-sky-800">
                    Driver's License
                  </div>
                </div>

                <div class="flex items-center space-x-3 mt-3">
                  <img
                    :src="application.facePhotoUrl"
                    :alt="application.applicant"
                    class="w-16 h-16 object-cover border border-sky-400 bg-sky-200 shrink-0"
                  />
                  <div class="text-xs space-y-0.5">
                    <div class="font-bold text-neutral-900">{{ application.applicant }}</div>
                    <div class="font-mono text-[11px] text-neutral-800">
                      License No: {{ application.licenseNumber }}
                    </div>
                    <div class="text-[10px] text-neutral-600">
                      Nationality: FILIPINO · Sex: M
                    </div>
                    <div class="text-[10px] text-neutral-600 font-mono">
                      Expires: {{ application.licenseExpiry }}
                    </div>
                  </div>
                </div>

                <div class="mt-3 pt-2 border-t border-sky-200 flex justify-between text-[10px] text-sky-900 font-mono">
                  <span>Authorized DL Code: {{ application.licenseCodes }}</span>
                  <span>Conditions: NONE</span>
                </div>
              </div>

              <div
                v-else
                key="license-back"
                class="w-full max-w-[480px] bg-neutral-50 border-2 border-neutral-300 p-4 shadow-sm relative"
              >
                <div class="text-center pb-2 border-b border-neutral-200">
                  <div class="text-[10px] uppercase font-bold text-neutral-700 tracking-wider">
                    Official LTO Security Barcode & Restriction Matrix
                  </div>
                </div>

                <div class="mt-3 space-y-2 text-xs">
                  <div class="h-10 bg-neutral-900 flex items-center justify-center text-white font-mono text-xs tracking-widest">
                    ||||| | |||| |||||| ||| ||||||| |||||||||| ||||
                  </div>
                  <div class="text-[10px] text-neutral-500 font-mono text-center">
                    *{{ application.licenseNumber }}*
                  </div>
                  <div class="p-2 bg-white border border-neutral-200 text-[11px] space-y-1">
                    <div><span class="text-neutral-400">Address:</span> {{ application.city }}</div>
                    <div><span class="text-neutral-400">Emergency Contact:</span> {{ application.phone }}</div>
                  </div>
                </div>
              </div>
            </Transition>

            <div
              v-else-if="activeViewerDoc.type === 'taxicle_orcr' && application"
              class="w-full max-w-[480px] bg-amber-50/50 border-2 border-amber-300 p-4 shadow-sm"
            >
              <div class="text-center pb-2 border-b border-amber-200">
                <div class="text-[10px] uppercase font-bold text-amber-900 tracking-wider">
                  Republic of the Philippines · Land Transportation Office
                </div>
                <div class="text-xs font-bold text-amber-950 uppercase">
                  Motor Vehicle Registration Document
                </div>
              </div>
              <div class="grid grid-cols-2 gap-2 mt-3 text-xs">
                <div><span class="text-neutral-400">Plate Number:</span> <span class="font-mono font-bold">{{ application.vehicle.plate }}</span></div>
                <div><span class="text-neutral-400">Body / Sidecar:</span> <span class="font-bold">{{ application.vehicle.bodyNumber }}</span></div>
                <div><span class="text-neutral-400">Make & Model:</span> <span class="font-semibold">{{ application.vehicle.make }} {{ application.vehicle.model }}</span></div>
                <div><span class="text-neutral-400">TODA Franchise:</span> <span class="font-semibold">{{ application.vehicle.todaFranchise }}</span></div>
              </div>
            </div>

            <div
              v-else-if="activeViewerDoc.type === 'clearance' && application"
              class="w-full max-w-[480px] bg-emerald-50/50 border-2 border-emerald-300 p-4 shadow-sm text-center"
            >
              <Icon icon="lucide:award" class="text-4xl text-emerald-600 mx-auto mb-1" />
              <div class="text-xs font-bold text-emerald-950 uppercase">{{ application.clearanceType }}</div>
              <div class="text-[11px] font-mono text-emerald-800 mt-0.5">ID: {{ application.clearanceNumber }}</div>
              <div class="mt-2 text-xs text-neutral-700 bg-white border border-emerald-200 p-2">
                {{ application.backgroundNotes }}
              </div>
            </div>
          </div>

          <div v-if="activeViewerDoc.metadata" class="border border-neutral-200 divide-y divide-neutral-100">
            <div
              v-for="(val, key) in activeViewerDoc.metadata"
              :key="key"
              class="px-3 py-1.5 flex justify-between text-xs"
            >
              <span class="text-neutral-500">{{ key }}</span>
              <span class="font-semibold text-neutral-900 font-mono">{{ val }}</span>
            </div>
          </div>
        </div>

        <div class="px-5 py-3 border-t border-neutral-200 bg-neutral-50 flex items-center justify-end">
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="closeViewer"
          >
            Close Viewer
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
