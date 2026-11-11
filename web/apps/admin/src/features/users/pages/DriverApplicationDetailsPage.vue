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

// Viewer Modal State
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

function openLicenseViewer() {
  if (!application.value) return
  activeViewerDoc.value = {
    title: "Philippine LTO Driver's License",
    subtitle: `${application.value.licenseType} · ${application.value.licenseNumber}`,
    type: 'license',
    frontUrl: application.value.licenseFrontDoc,
    backUrl: application.value.licenseBackDoc,
    activeSide: 'front',
    metadata: {
      'License Number': application.value.licenseNumber,
      'Classification': application.value.licenseType,
      'Authorized DL Codes': application.value.licenseCodes,
      'Expiration Date': application.value.licenseExpiry,
      'Issuing Agency': 'Land Transportation Office (LTO Philippines)',
    },
  }
}

function openTaxicleDocViewer(docType: 'OR' | 'CR') {
  if (!application.value) return
  const isOR = docType === 'OR'
  activeViewerDoc.value = {
    title: isOR
      ? 'LTO Official Receipt (OR)'
      : 'LTO Certificate of Registration (CR)',
    subtitle: isOR
      ? application.value.vehicle.orNumber
      : application.value.vehicle.crNumber,
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
  if (e.key === 'Escape' && activeViewerDoc.value) {
    closeViewer()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})

function handleApprove() {
  if (!application.value) return
  approveApplication(application.value)
}

function handleReject() {
  if (!application.value) return
  rejectApplication(application.value, 'Documentation review failed regulatory compliance')
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
    <!-- Back Button -->
    <div>
      <button
        type="button"
        class="inline-flex items-center space-x-2 text-xs font-semibold text-neutral-700 hover:text-neutral-900 bg-white border border-neutral-200 hover:bg-neutral-50 px-3 py-1.5 transition-colors group cursor-pointer"
        @click="goBack"
      >
        <Icon
          icon="lucide:arrow-left"
          class="text-sm text-neutral-500 group-hover:text-neutral-900 transition-transform group-hover:-translate-x-0.5"
        />
        <span>Back to Driver Applications</span>
      </button>
    </div>

    <!-- Application Details Card if found -->
    <div v-if="application" class="space-y-6">
      <!-- Title & Status Header (single source of truth for status) -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div class="flex items-center space-x-3">
            <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
              Application {{ application.id }}
            </h1>
            <span
              class="px-2.5 py-0.5 text-xs font-bold"
              :class="{
                'bg-emerald-100 text-emerald-800 border border-emerald-200': application.status === 'Approved',
                'bg-rose-100 text-rose-800 border border-rose-200': application.status === 'Rejected',
                'bg-amber-100 text-amber-800 border border-amber-200': application.status === 'Pending Review',
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

      <!-- Applicant Identity & Driver Face Photo Section -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-neutral-100 gap-4">
          <div class="flex items-center space-x-4">
            <!-- Driver Face Picture with click to zoom -->
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
              <div class="absolute inset-0 bg-neutral-900/30 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity">
                <Icon icon="lucide:zoom-in" class="text-white text-base" />
              </div>
            </button>

            <div>
              <div class="flex items-center space-x-2">
                <h2 class="font-bold text-base text-neutral-900">{{ application.applicant }}</h2>
                <span class="px-2 py-0.5 text-[10px] font-semibold bg-neutral-100 text-neutral-700 border border-neutral-200">
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

      <!-- Philippine LTO Driver's License Section (Back-to-Back with Viewer) -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <div class="flex items-center space-x-2">
            <Icon icon="lucide:id-card" class="text-neutral-700 text-base" />
            <h2 class="font-bold text-sm text-neutral-900">
              Philippine LTO Driver's License (Back-to-Back)
            </h2>
          </div>
          <button
            type="button"
            class="px-2.5 py-1 text-xs font-semibold bg-neutral-100 hover:bg-neutral-200 text-neutral-800 border border-neutral-200 flex items-center space-x-1 cursor-pointer transition-colors"
            @click="openLicenseViewer"
          >
            <Icon icon="lucide:scan" class="text-xs" />
            <span>Open Back-to-Back Viewer</span>
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
            <div class="text-neutral-400 text-[11px] font-medium">Authorized DL Codes</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ application.licenseCodes }}
            </div>
          </div>
          <div>
            <div class="text-neutral-400 text-[11px] font-medium">LTO License Expiration</div>
            <div class="font-mono font-semibold text-neutral-900 mt-0.5">
              {{ application.licenseExpiry }}
            </div>
          </div>
        </div>

        <!-- Back to Back License Preview Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
          <!-- Front Side -->
          <div
            class="p-4 bg-neutral-50 border border-neutral-200 hover:border-neutral-400 transition-colors cursor-pointer group"
            @click="openLicenseViewer"
          >
            <div class="flex items-center justify-between pb-2 border-b border-neutral-200">
              <span class="text-xs font-bold text-neutral-900 flex items-center space-x-1.5">
                <Icon icon="lucide:file-text" class="text-neutral-500" />
                <span>Driver License (Front Side)</span>
              </span>
              <span class="text-[11px] font-semibold text-emerald-700">Official Hologram OK</span>
            </div>
            <div class="mt-3 flex items-center justify-between text-xs text-neutral-600">
              <span class="font-mono text-[11px]">{{ application.licenseFrontDoc }}</span>
              <span class="text-neutral-900 font-semibold group-hover:underline flex items-center space-x-1">
                <span>View Full Scan</span>
                <Icon icon="lucide:external-link" class="text-xs" />
              </span>
            </div>
          </div>

          <!-- Back Side -->
          <div
            class="p-4 bg-neutral-50 border border-neutral-200 hover:border-neutral-400 transition-colors cursor-pointer group"
            @click="openLicenseViewer"
          >
            <div class="flex items-center justify-between pb-2 border-b border-neutral-200">
              <span class="text-xs font-bold text-neutral-900 flex items-center space-x-1.5">
                <Icon icon="lucide:file-text" class="text-neutral-500" />
                <span>Driver License (Back Side)</span>
              </span>
              <span class="text-[11px] font-semibold text-emerald-700">LTO Barcode Verified</span>
            </div>
            <div class="mt-3 flex items-center justify-between text-xs text-neutral-600">
              <span class="font-mono text-[11px]">{{ application.licenseBackDoc }}</span>
              <span class="text-neutral-900 font-semibold group-hover:underline flex items-center space-x-1">
                <span>View Full Scan</span>
                <Icon icon="lucide:external-link" class="text-xs" />
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Taxicle (Tricycle Taxi) Specification & Franchise Section -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <div class="flex items-center space-x-2">
            <Icon icon="lucide:car-taxi-front" class="text-neutral-700 text-base" />
            <h2 class="font-bold text-sm text-neutral-900">
              Taxicle (Tricycle Cab) Specification & Franchise
            </h2>
          </div>
          <span class="text-xs font-semibold px-2 py-0.5 bg-neutral-100 text-neutral-700 border border-neutral-200">
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

        <!-- Official Receipt (OR) and Certificate of Registration (CR) -->
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
            <span class="text-xs font-semibold text-neutral-900 group-hover:underline flex items-center space-x-1">
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
            <span class="text-xs font-semibold text-neutral-900 group-hover:underline flex items-center space-x-1">
              <span>View CR</span>
              <Icon icon="lucide:external-link" class="text-xs" />
            </span>
          </div>
        </div>

        <!-- Insurance and Inspection -->
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

      <!-- Philippine Regulatory Background Verification Section -->
      <div class="bg-white border border-neutral-200 p-5 space-y-4">
        <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
          <div class="flex items-center space-x-2">
            <Icon icon="lucide:shield-check" class="text-neutral-700 text-base" />
            <h2 class="font-bold text-sm text-neutral-900">
              Philippine Regulatory Background Screening
            </h2>
          </div>
          <button
            type="button"
            class="px-2.5 py-1 text-xs font-semibold bg-neutral-100 hover:bg-neutral-200 text-neutral-800 border border-neutral-200 flex items-center space-x-1 cursor-pointer transition-colors"
            @click="openClearanceViewer"
          >
            <Icon icon="lucide:file-check" class="text-xs" />
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

      <!-- Action Footer (Clean and non-redundant) -->
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
            @click="handleReject"
          >
            Reject Application
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
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
      class="bg-white border border-neutral-200 p-8 text-center text-xs text-neutral-500"
    >
      <p class="font-semibold text-neutral-900">Application Not Found</p>
      <p class="mt-1">No driver application matches ID {{ applicationId }}.</p>
      <button
        type="button"
        class="mt-4 px-3 py-1.5 bg-neutral-900 text-white text-xs font-semibold cursor-pointer"
        @click="goBack"
      >
        Back to Applications Queue
      </button>
    </div>

    <!-- Interactive Document & License Viewer Modal (Full Exit / Close Controls) -->
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
        <!-- Modal Header with Explicit Close Exit Button -->
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

        <!-- Modal Body -->
        <div class="p-5 space-y-4 max-h-[75vh] overflow-y-auto text-xs">
          <!-- Back-to-Back Side Switcher for Driver's License -->
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
              @click="activeViewerDoc.activeSide = 'front'"
            >
              Front Side (Photo & Personal Details)
            </button>
            <button
              type="button"
              class="px-3 py-1.5 font-semibold text-xs border transition-colors cursor-pointer"
              :class="
                activeViewerDoc.activeSide === 'back'
                  ? 'bg-neutral-900 text-white border-neutral-900'
                  : 'bg-white text-neutral-700 border-neutral-200 hover:bg-neutral-100'
              "
              @click="activeViewerDoc.activeSide = 'back'"
            >
              Back Side (Barcode & Restrictions)
            </button>
          </div>

          <!-- Document Preview Canvas -->
          <div class="border border-neutral-200 bg-neutral-100 p-6 flex flex-col items-center justify-center min-h-[220px]">
            <!-- Driver Face Photo Viewer -->
            <div v-if="activeViewerDoc.type === 'face' && application" class="text-center">
              <img
                :src="application.facePhotoUrl"
                :alt="application.applicant"
                class="w-40 h-40 object-cover border-2 border-white shadow-md mx-auto"
              />
              <p class="text-xs font-bold text-neutral-900 mt-3">{{ application.applicant }}</p>
              <p class="text-[11px] text-neutral-500 font-mono">{{ application.phone }}</p>
            </div>

            <!-- License Front Viewer -->
            <div
              v-else-if="activeViewerDoc.type === 'license' && activeViewerDoc.activeSide === 'front' && application"
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
                <span>DL Codes: {{ application.licenseCodes }}</span>
                <span>Conditions: NONE</span>
              </div>
            </div>

            <!-- License Back Viewer -->
            <div
              v-else-if="activeViewerDoc.type === 'license' && activeViewerDoc.activeSide === 'back' && application"
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

            <!-- Taxicle OR/CR Viewer -->
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

            <!-- Clearance Viewer -->
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

          <!-- Document Metadata Table -->
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

        <!-- Modal Footer with Clear Close & Dismiss Button -->
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
