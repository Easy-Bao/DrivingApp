<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import { useDriverApplications } from '@/features/users/composables/use-driver-applications'

definePage({
  meta: { isDetail: true },
})

const route = useRoute()
const router = useRouter()
const { getApplicationById, approveApplication, rejectApplication } = useDriverApplications()

const applicationId = computed(() => (route.params.id as string) || '')
const application = computed(() => getApplicationById(applicationId.value))

interface ViewerDocument {
  title: string
  subtitle: string
  type: 'license' | 'vehicle_doc' | 'clearance' | 'face'
  docKind?: 'OR' | 'CR' | 'CTPL' | 'MVIR'
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

const canConfirmReject = computed(() => {
  if (!rejectReason.value.trim()) return false
  if (rejectReason.value === 'Other compliance deficiency' && !rejectNotes.value.trim()) {
    return false
  }
  return true
})

const statusTone = computed(() => {
  if (application.value?.status === 'Approved') return 'success' as const
  if (application.value?.status === 'Rejected') return 'danger' as const
  return 'warning' as const
})

function setLicenseSide(side: 'front' | 'back') {
  if (!activeViewerDoc.value || side === activeViewerDoc.value.activeSide) return
  licenseSlideDirection.value = side === 'back' ? 'flip-left' : 'flip-right'
  activeViewerDoc.value.activeSide = side
}

function openLicenseViewer() {
  if (!application.value) return
  licenseSlideDirection.value = 'flip-left'
  activeViewerDoc.value = {
    title: "Driver's License (LTO)",
    subtitle: `${application.value.licenseType} · ${application.value.licenseNumber}`,
    type: 'license',
    frontUrl: application.value.licenseFrontDoc,
    backUrl: application.value.licenseBackDoc,
    activeSide: 'front',
    metadata: {
      'License No.': application.value.licenseNumber,
      'Classification & Code': `${application.value.licenseType} · Code ${application.value.licenseCodes}`,
      Expiration: application.value.licenseExpiry,
      'Issuing Agency': 'Land Transportation Office (LTO)',
    },
  }
}

function openVehicleDocViewer(docKind: 'OR' | 'CR' | 'CTPL' | 'MVIR') {
  if (!application.value) return
  const v = application.value.vehicle

  const configMap: Record<
    'OR' | 'CR' | 'CTPL' | 'MVIR',
    { title: string; subtitle: string; docNo: string; fileName: string }
  > = {
    OR: {
      title: 'LTO Official Receipt (OR)',
      subtitle: v.orNumber,
      docNo: v.orNumber,
      fileName: v.orDoc,
    },
    CR: {
      title: 'LTO Certificate of Registration (CR)',
      subtitle: v.crNumber,
      docNo: v.crNumber,
      fileName: v.crDoc,
    },
    CTPL: {
      title: 'CTPL Insurance Policy',
      subtitle: v.insurancePolicy,
      docNo: v.insurancePolicy,
      fileName: 'ctpl_insurance_policy.pdf',
    },
    MVIR: {
      title: 'MVIR Inspection Certificate',
      subtitle: v.inspectionDoc,
      docNo: 'MVIR-2026-PASSED',
      fileName: v.inspectionDoc,
    },
  }

  const chosen = configMap[docKind]
  activeViewerDoc.value = {
    title: chosen.title,
    subtitle: chosen.subtitle,
    type: 'vehicle_doc',
    docKind,
    metadata: {
      Reference: chosen.docNo,
      File: chosen.fileName,
      'Plate & Body No.': `${v.plate} · ${v.bodyNumber}`,
      'TODA & MTOP': `${v.todaFranchise} · ${v.mtopNumber}`,
      'Engine / Chassis': `${v.engineNumber} / ${v.chassisNumber}`,
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
      Authority: application.value.backgroundProvider,
      'Reference No.': application.value.clearanceNumber,
      Status: application.value.backgroundStatus,
      Remarks: application.value.backgroundNotes,
    },
  }
}

function openFacePhotoViewer() {
  if (!application.value) return
  activeViewerDoc.value = {
    title: 'Applicant Identity Photo',
    subtitle: `${application.value.applicant} · ${application.value.phone}`,
    type: 'face',
    metadata: {
      Applicant: application.value.applicant,
      Phone: application.value.phone,
      'Address / Barangay': `${application.value.barangay}, ${application.value.city}, ${application.value.province}`,
    },
  }
}

function closeViewer() {
  activeViewerDoc.value = null
}

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
  if (!application.value || !canConfirmReject.value) return
  const trimmedNotes = rejectNotes.value.trim()
  const fullReason = trimmedNotes ? `${rejectReason.value} — ${trimmedNotes}` : rejectReason.value
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
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
        <div>
          <div class="flex items-center space-x-3">
            <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
              Application {{ application.id }}
            </h1>
            <StatusBadge :label="application.status" :tone="statusTone" />
          </div>
          <p class="text-sm text-neutral-500 mt-1">Submitted {{ application.appliedTime }}</p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-white border border-neutral-200 p-5 space-y-4">
          <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
            <h2 class="font-bold text-sm text-neutral-900">Applicant Summary</h2>
            <span class="text-neutral-800 text-xs font-semibold inline-flex items-center space-x-1">
              <Icon icon="lucide:check-circle" class="text-xs text-emerald-700" />
              <span>Photo Verified</span>
            </span>
          </div>

          <div class="flex items-start space-x-4">
            <button
              type="button"
              class="relative w-16 h-16 bg-neutral-900 border border-neutral-300 overflow-hidden shrink-0 group cursor-pointer"
              title="View applicant photo"
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

            <div class="min-w-0 flex-1 space-y-1">
              <h3 class="font-bold text-base text-neutral-900">{{ application.applicant }}</h3>
              <p class="text-xs text-neutral-500 truncate">{{ application.email }}</p>
              <p class="text-xs font-mono font-semibold text-neutral-800">
                {{ application.phone }}
              </p>
            </div>
          </div>

          <div
            class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-3 border-t border-neutral-100 text-xs"
          >
            <div>
              <div class="text-neutral-400 text-[11px] font-medium">Address / Barangay</div>
              <div class="font-semibold text-neutral-900 mt-0.5">
                {{ application.barangay }}, {{ application.city }}, {{ application.province }}
              </div>
            </div>
            <div>
              <div class="text-neutral-400 text-[11px] font-medium">Submitted On</div>
              <div class="font-mono font-semibold text-neutral-900 mt-0.5">
                {{ application.appliedDate }}
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4">
          <div class="space-y-4">
            <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
              <h2 class="font-bold text-sm text-neutral-900">Driver's License (LTO)</h2>
              <button
                type="button"
                class="px-3 py-1.5 text-xs font-semibold bg-neutral-900 hover:bg-neutral-800 text-white transition-colors cursor-pointer"
                @click="openLicenseViewer"
              >
                View License
              </button>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
              <div>
                <div class="text-neutral-400 text-[11px] font-medium">License No.</div>
                <div class="font-mono font-bold text-neutral-900 mt-0.5">
                  {{ application.licenseNumber }}
                </div>
              </div>
              <div>
                <div class="text-neutral-400 text-[11px] font-medium">
                  Classification &amp; Code
                </div>
                <div class="font-semibold text-neutral-900 mt-0.5">
                  {{ application.licenseType }} · Code {{ application.licenseCodes }}
                </div>
              </div>
              <div>
                <div class="text-neutral-400 text-[11px] font-medium">Expiration</div>
                <div class="font-mono font-semibold text-neutral-900 mt-0.5">
                  {{ application.licenseExpiry }}
                </div>
              </div>
            </div>
          </div>

          <button
            type="button"
            class="w-full p-3 bg-neutral-50 border border-neutral-200 flex items-center justify-between text-xs hover:border-neutral-400 transition-colors cursor-pointer text-left"
            @click="openLicenseViewer"
          >
            <span class="font-mono text-neutral-700 truncate pr-3">{{
              application.licenseFrontDoc
            }}</span>
            <span class="font-semibold text-neutral-900 shrink-0 hover:underline">View Scan</span>
          </button>
        </div>

        <div class="bg-white border border-neutral-200 p-5 space-y-4">
          <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
            <h2 class="font-bold text-sm text-neutral-900">Vehicle &amp; Franchise</h2>
            <span
              class="text-xs font-semibold px-2 py-0.5 bg-neutral-100 text-neutral-700 border border-neutral-200"
            >
              {{ application.vehicle.type }}
            </span>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
            <div>
              <div class="text-neutral-400 text-[11px] font-medium">Model &amp; Year</div>
              <div class="font-semibold text-neutral-900 mt-0.5">
                {{ application.vehicle.year }} {{ application.vehicle.make }}
                {{ application.vehicle.model }}
              </div>
            </div>
            <div>
              <div class="text-neutral-400 text-[11px] font-medium">Plate &amp; Body No.</div>
              <div class="font-mono font-bold text-neutral-900 mt-0.5">
                {{ application.vehicle.plate }} · {{ application.vehicle.bodyNumber }}
              </div>
            </div>
            <div>
              <div class="text-neutral-400 text-[11px] font-medium">TODA &amp; MTOP</div>
              <div class="font-semibold text-neutral-800 mt-0.5">
                {{ application.vehicle.todaFranchise }} · {{ application.vehicle.mtopNumber }}
              </div>
            </div>
            <div>
              <div class="text-neutral-400 text-[11px] font-medium">Engine / Chassis</div>
              <div class="font-mono text-neutral-700 mt-0.5">
                {{ application.vehicle.engineNumber }} / {{ application.vehicle.chassisNumber }}
              </div>
            </div>
          </div>

          <div
            class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 text-xs pt-2 border-t border-neutral-100"
          >
            <button
              type="button"
              class="p-2.5 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer text-left group"
              @click="openVehicleDocViewer('OR')"
            >
              <div class="min-w-0 pr-2">
                <div class="text-[11px] text-neutral-400 font-medium">LTO OR</div>
                <div class="font-mono font-semibold text-neutral-800 truncate">
                  {{ application.vehicle.orNumber }}
                </div>
              </div>
              <span class="text-xs font-semibold text-neutral-900 group-hover:underline shrink-0">
                View
              </span>
            </button>

            <button
              type="button"
              class="p-2.5 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer text-left group"
              @click="openVehicleDocViewer('CR')"
            >
              <div class="min-w-0 pr-2">
                <div class="text-[11px] text-neutral-400 font-medium">LTO CR</div>
                <div class="font-mono font-semibold text-neutral-800 truncate">
                  {{ application.vehicle.crNumber }}
                </div>
              </div>
              <span class="text-xs font-semibold text-neutral-900 group-hover:underline shrink-0">
                View
              </span>
            </button>

            <button
              type="button"
              class="p-2.5 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer text-left group"
              @click="openVehicleDocViewer('CTPL')"
            >
              <div class="min-w-0 pr-2">
                <div class="text-[11px] text-neutral-400 font-medium">CTPL Policy</div>
                <div class="font-semibold text-neutral-800 truncate">
                  {{ application.vehicle.insurancePolicy }}
                </div>
              </div>
              <span class="text-xs font-semibold text-neutral-900 group-hover:underline shrink-0">
                View
              </span>
            </button>

            <button
              type="button"
              class="p-2.5 bg-neutral-50 border border-neutral-200 flex items-center justify-between hover:border-neutral-400 transition-colors cursor-pointer text-left group"
              @click="openVehicleDocViewer('MVIR')"
            >
              <div class="min-w-0 pr-2">
                <div class="text-[11px] text-neutral-400 font-medium">MVIR Certificate</div>
                <div class="font-mono text-neutral-800 truncate">
                  {{ application.vehicle.inspectionDoc }}
                </div>
              </div>
              <span class="text-xs font-semibold text-neutral-900 group-hover:underline shrink-0">
                View
              </span>
            </button>
          </div>
        </div>

        <div class="bg-white border border-neutral-200 p-5 flex flex-col justify-between space-y-4">
          <div class="space-y-4">
            <div class="flex items-center justify-between pb-3 border-b border-neutral-100">
              <h2 class="font-bold text-sm text-neutral-900">Background Clearance</h2>
              <button
                type="button"
                class="px-2.5 py-1 text-xs font-semibold bg-neutral-100 hover:bg-neutral-200 text-neutral-800 border border-neutral-200 cursor-pointer transition-colors"
                @click="openClearanceViewer"
              >
                View Clearance Certificate
              </button>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div>
                <div class="text-neutral-400 text-[11px] font-medium">Authority</div>
                <div class="font-semibold text-neutral-900 mt-0.5 flex items-center gap-2">
                  <span>{{ application.backgroundProvider }}</span>
                  <span
                    class="px-1.5 py-0.5 text-[10px] font-semibold"
                    :class="
                      application.backgroundStatus === 'Passed'
                        ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                        : 'bg-amber-50 text-amber-700 border border-amber-200'
                    "
                  >
                    {{ application.backgroundStatus }}
                  </span>
                </div>
              </div>
              <div>
                <div class="text-neutral-400 text-[11px] font-medium">Reference No.</div>
                <div class="font-mono font-semibold text-neutral-900 mt-0.5">
                  {{ application.clearanceNumber }}
                </div>
              </div>
            </div>

            <div class="p-3 bg-neutral-50 border border-neutral-200 text-xs">
              <div class="font-semibold text-neutral-900">Remarks</div>
              <p class="text-neutral-600 mt-1 leading-relaxed">{{ application.backgroundNotes }}</p>
            </div>
          </div>

          <button
            type="button"
            class="w-full p-3 bg-neutral-50 border border-neutral-200 flex items-center justify-between text-xs hover:border-neutral-400 transition-colors cursor-pointer text-left"
            @click="openClearanceViewer"
          >
            <span class="font-mono text-neutral-700 truncate pr-3">{{
              application.clearanceDoc
            }}</span>
            <span class="font-semibold text-neutral-900 shrink-0 hover:underline">
              View Certificate
            </span>
          </button>
        </div>
      </div>

      <div
        class="bg-white border border-neutral-200 p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
      >
        <div class="text-xs text-neutral-600">
          <span v-if="application.status === 'Pending Review'">
            Verify all submitted documents before approving this application.
          </span>
          <span
            v-else-if="application.status === 'Approved'"
            class="text-emerald-700 font-semibold"
          >
            Application approved. Driver credentials and dispatch access active.
          </span>
          <span v-else class="text-rose-700 font-semibold">
            Application rejected<template v-if="application.rejectionReason"
              >: {{ application.rejectionReason }}</template
            >.
          </span>
        </div>

        <div
          v-if="application.status === 'Pending Review'"
          class="flex flex-wrap items-center gap-3 shrink-0"
        >
          <button
            type="button"
            class="px-4 py-2 border border-rose-300 text-rose-700 hover:bg-rose-50 text-xs font-semibold transition-colors cursor-pointer"
            @click="openRejectDialog"
          >
            Reject Application
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="openApproveDialog"
          >
            Approve &amp; Activate Driver
          </button>
        </div>
      </div>
    </div>

    <div v-else class="bg-white border border-neutral-200 p-8 text-center text-xs text-neutral-500">
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

    <ModalDialog
      :open="showApproveDialog && Boolean(application)"
      title="Approve Driver Application"
      :subtitle="
        application ? `Application ${application.id} · ${application.applicant}` : undefined
      "
      size="md"
      close-label="Close modal"
      @update:open="showApproveDialog = $event"
    >
      <div v-if="application" class="space-y-4 text-xs">
        <p class="text-neutral-700 leading-relaxed">
          Approve this application to activate the driver account, grant dispatch access, and send
          SMS confirmation to
          <span class="font-mono font-bold text-neutral-900">{{ application.phone }}</span
          >.
        </p>

        <div class="p-3 bg-neutral-50 border border-neutral-200 text-xs space-y-1">
          <div class="font-semibold text-neutral-900 flex items-center space-x-1.5">
            <Icon icon="lucide:check-circle" class="text-neutral-700" />
            <span>Verification Summary</span>
          </div>
          <ul class="text-neutral-700 space-y-0.5 text-[11px] list-disc list-inside">
            <li>
              LTO License: {{ application.licenseNumber }} (Code {{ application.licenseCodes }})
            </li>
            <li>
              Vehicle: {{ application.vehicle.year }} {{ application.vehicle.make }}
              {{ application.vehicle.model }} ({{ application.vehicle.plate }})
            </li>
            <li>TODA &amp; MTOP: {{ application.vehicle.todaFranchise }}</li>
            <li>
              Address: {{ application.barangay }}, {{ application.city }},
              {{ application.province }}
            </li>
            <li>Clearance: {{ application.clearanceType }} ({{ application.backgroundStatus }})</li>
          </ul>
        </div>
      </div>

      <template #footer>
        <div class="flex items-center justify-end space-x-2">
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
            Confirm &amp; Activate Driver
          </button>
        </div>
      </template>
    </ModalDialog>

    <ModalDialog
      :open="showRejectDialog && Boolean(application)"
      title="Reject Driver Application"
      :subtitle="
        application ? `Application ${application.id} · ${application.applicant}` : undefined
      "
      size="md"
      close-label="Close modal"
      @update:open="showRejectDialog = $event"
    >
      <div v-if="application" class="space-y-4 text-xs">
        <p class="text-neutral-700 leading-relaxed">
          Select the reason for rejecting this application so the applicant knows which document or
          requirement needs correction.
        </p>

        <div class="space-y-1.5">
          <label class="font-semibold text-neutral-800">Rejection Reason</label>
          <BaseSelect
            v-model="rejectReason"
            aria-label="Rejection reason"
            :full-width="true"
            :options="[
              'Incomplete or unreadable LTO driver license scan',
              'Expired or unverified MTOP municipal permit',
              'TODA franchise endorsement missing or invalid',
              'Failed NBI or PNP background clearance',
              'Mismatched vehicle registration (OR/CR) details',
              'Other compliance deficiency',
            ]"
          />
        </div>

        <div class="space-y-1.5">
          <label class="font-semibold text-neutral-800">
            Instructions for Applicant
            <span v-if="rejectReason === 'Other compliance deficiency'" class="text-rose-700">
              *
            </span>
          </label>
          <textarea
            v-model="rejectNotes"
            rows="3"
            placeholder="Specify which scan or field needs to be re-submitted..."
            class="w-full p-2 bg-neutral-50 border border-neutral-200 text-xs text-neutral-800 focus:outline-none focus:ring-1 focus:ring-neutral-900"
          />
        </div>
      </div>

      <template #footer>
        <div class="flex items-center justify-end space-x-2">
          <button
            type="button"
            class="px-4 py-2 border border-neutral-300 text-neutral-700 hover:bg-neutral-100 text-xs font-semibold transition-colors cursor-pointer"
            @click="showRejectDialog = false"
          >
            Cancel
          </button>
          <button
            type="button"
            :disabled="!canConfirmReject"
            class="px-4 py-2 bg-rose-600 hover:bg-rose-700 disabled:opacity-40 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="confirmReject"
          >
            Confirm Rejection
          </button>
        </div>
      </template>
    </ModalDialog>

    <ModalDialog
      :open="Boolean(activeViewerDoc)"
      :title="activeViewerDoc?.title ?? ''"
      :subtitle="activeViewerDoc?.subtitle"
      size="xl"
      close-label="Close viewer"
      @update:open="(open) => !open && closeViewer()"
    >
      <div v-if="activeViewerDoc" class="space-y-4 text-xs">
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
                <div class="text-[10px] font-semibold text-sky-800">Driver's License</div>
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
                  <div class="text-[10px] text-neutral-600">Nationality: FILIPINO</div>
                  <div class="text-[10px] text-neutral-600 font-mono">
                    Expires: {{ application.licenseExpiry }}
                  </div>
                </div>
              </div>

              <div
                class="mt-3 pt-2 border-t border-sky-200 flex justify-between text-[10px] text-sky-900 font-mono"
              >
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
                  Official LTO Security Barcode &amp; Restriction Matrix
                </div>
              </div>

              <div class="mt-3 space-y-2 text-xs">
                <div
                  class="h-10 bg-neutral-900 flex items-center justify-center text-white font-mono text-xs tracking-widest"
                >
                  ||||| | |||| |||||| ||| ||||||| |||||||||| ||||
                </div>
                <div class="text-[10px] text-neutral-500 font-mono text-center">
                  *{{ application.licenseNumber }}*
                </div>
                <div class="p-2 bg-white border border-neutral-200 text-[11px] space-y-1">
                  <div>
                    <span class="text-neutral-400">Address:</span> {{ application.barangay }},
                    {{ application.city }}, {{ application.province }}
                  </div>
                  <div>
                    <span class="text-neutral-400">Contact:</span>
                    {{ application.phone }}
                  </div>
                </div>
              </div>
            </div>
          </Transition>

          <div
            v-else-if="activeViewerDoc.type === 'vehicle_doc' && application"
            class="w-full max-w-[480px] bg-amber-50/50 border-2 border-amber-300 p-4 shadow-sm"
          >
            <div class="text-center pb-2 border-b border-amber-200">
              <div class="text-[10px] uppercase font-bold text-amber-900 tracking-wider">
                Republic of the Philippines · Compliance Record
              </div>
              <div class="text-xs font-bold text-amber-950 uppercase">
                {{ activeViewerDoc.title }}
              </div>
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-3 text-xs">
              <div>
                <span class="text-neutral-400">Plate Number:</span>
                <span class="font-mono font-bold">{{ application.vehicle.plate }}</span>
              </div>
              <div>
                <span class="text-neutral-400">Body Unit:</span>
                <span class="font-bold">{{ application.vehicle.bodyNumber }}</span>
              </div>
              <div>
                <span class="text-neutral-400">Vehicle:</span>
                <span class="font-semibold">
                  {{ application.vehicle.make }} {{ application.vehicle.model }}
                </span>
              </div>
              <div>
                <span class="text-neutral-400">TODA Franchise:</span>
                <span class="font-semibold">{{ application.vehicle.todaFranchise }}</span>
              </div>
            </div>
          </div>

          <div
            v-else-if="activeViewerDoc.type === 'clearance' && application"
            class="w-full max-w-[480px] bg-emerald-50/50 border-2 border-emerald-300 p-4 shadow-sm text-center"
          >
            <Icon icon="lucide:award" class="text-4xl text-emerald-600 mx-auto mb-1" />
            <div class="text-xs font-bold text-emerald-950 uppercase">
              {{ application.clearanceType }}
            </div>
            <div class="text-[11px] font-mono text-emerald-800 mt-0.5">
              ID: {{ application.clearanceNumber }}
            </div>
            <div class="mt-2 text-xs text-neutral-700 bg-white border border-emerald-200 p-2">
              {{ application.backgroundNotes }}
            </div>
          </div>
        </div>

        <div
          v-if="activeViewerDoc.metadata"
          class="border border-neutral-200 divide-y divide-neutral-100"
        >
          <div
            v-for="(val, key) in activeViewerDoc.metadata"
            :key="key"
            class="px-3 py-1.5 flex flex-col sm:flex-row sm:justify-between gap-1 text-xs"
          >
            <span class="text-neutral-500">{{ key }}</span>
            <span class="font-semibold text-neutral-900 font-mono">{{ val }}</span>
          </div>
        </div>
      </div>

      <template #footer>
        <div class="flex items-center justify-end">
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="closeViewer"
          >
            Close Viewer
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
