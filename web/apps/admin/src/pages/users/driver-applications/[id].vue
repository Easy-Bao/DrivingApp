<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import {
  ToastBanner,
  useSafeBack,
  useSafeRouteParam,
  type BadgeTone,
  type ToastTone,
} from '@/shared'
import {
  ApplicationDecisionModals,
  ApplicationDocumentViewerModal,
  ApplicationProfileSections,
  useDriverApplications,
  type ApplicationViewerDocument,
  type DriverApplication,
} from '@/features/users'

definePage({
  meta: {
    isDetail: true,
  },
})

const applicationId = useSafeRouteParam('id')
const goBack = useSafeBack('/users/driver-applications')
const { getApplicationById, approveApplication, rejectApplication } = useDriverApplications()

const application = computed(() =>
  applicationId.value ? getApplicationById(applicationId.value) : undefined,
)

const activeDoc = ref<ApplicationViewerDocument | null>(null)
const showApproveDialog = ref(false)
const showRejectDialog = ref(false)
const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('success')

function getStatusTone(status: DriverApplication['status']): BadgeTone {
  if (status === 'Approved') return 'success'
  if (status === 'Rejected') return 'danger'
  return 'warning'
}

function openFacePhotoViewer() {
  const app = application.value
  if (!app) return
  activeDoc.value = {
    docId: app.id,
    title: 'Applicant Portrait',
    subtitle: `${app.applicant} · Identity Capture`,
    category: 'photo',
    filename: `portrait_${app.id.toLowerCase()}.jpg`,
    imageUrl: app.facePhotoUrl,
    meta: [
      { label: 'Applicant', value: app.applicant },
      { label: 'Contact', value: app.phone },
      { label: 'Barangay', value: `${app.barangay}, ${app.city}` },
    ],
  }
}

function openLicenseViewer() {
  const app = application.value
  if (!app) return
  activeDoc.value = {
    docId: app.licenseNumber,
    title: 'LTO Driver License',
    subtitle: `${app.licenseType} · Code ${app.licenseCodes}`,
    category: 'license',
    filename: app.licenseFrontDoc,
    backFilename: app.licenseBackDoc,
    meta: [
      { label: 'License Number', value: app.licenseNumber },
      { label: 'Classification', value: `${app.licenseType} (Code ${app.licenseCodes})` },
      { label: 'Expiration Date', value: app.licenseExpiry },
    ],
  }
}

function openVehicleDocViewer(docKind: 'OR' | 'CR' | 'CTPL' | 'MVIR') {
  const app = application.value
  if (!app) return
  const docMap: Record<typeof docKind, ApplicationViewerDocument> = {
    OR: {
      docId: app.vehicle.orNumber,
      title: 'LTO Official Receipt (OR)',
      subtitle: `${app.vehicle.plate} · ${app.vehicle.make} ${app.vehicle.model}`,
      category: 'vehicle',
      filename: app.vehicle.orDoc,
      meta: [
        { label: 'OR Number', value: app.vehicle.orNumber },
        { label: 'Plate & Body', value: `${app.vehicle.plate} · ${app.vehicle.bodyNumber}` },
        {
          label: 'Engine / Chassis',
          value: `${app.vehicle.engineNumber} / ${app.vehicle.chassisNumber}`,
        },
      ],
    },
    CR: {
      docId: app.vehicle.crNumber,
      title: 'LTO Certificate of Registration (CR)',
      subtitle: `${app.vehicle.plate} · ${app.vehicle.year} ${app.vehicle.make}`,
      category: 'vehicle',
      filename: app.vehicle.crDoc,
      meta: [
        { label: 'CR Number', value: app.vehicle.crNumber },
        { label: 'TODA Franchise', value: app.vehicle.todaFranchise },
        { label: 'MTOP Permit', value: app.vehicle.mtopNumber },
      ],
    },
    CTPL: {
      docId: app.vehicle.insurancePolicy,
      title: 'Compulsory TPL Insurance Policy',
      subtitle: `${app.vehicle.plate} · Active Passenger Liability Coverage`,
      category: 'vehicle',
      filename: `ctpl_${app.vehicle.plate.toLowerCase()}.pdf`,
      meta: [
        { label: 'Policy Reference', value: app.vehicle.insurancePolicy },
        {
          label: 'Covered Unit',
          value: `${app.vehicle.year} ${app.vehicle.make} ${app.vehicle.model}`,
        },
      ],
    },
    MVIR: {
      docId: app.vehicle.mtopNumber,
      title: 'Motor Vehicle Inspection Report (MVIR)',
      subtitle: `${app.vehicle.plate} · City Roadworthiness Clearance`,
      category: 'vehicle',
      filename: app.vehicle.inspectionDoc,
      meta: [
        { label: 'MTOP Permit', value: app.vehicle.mtopNumber },
        { label: 'Franchise Corridor', value: app.vehicle.todaFranchise },
      ],
    },
  }
  activeDoc.value = docMap[docKind]
}

function openClearanceViewer() {
  const app = application.value
  if (!app) return
  activeDoc.value = {
    docId: app.clearanceNumber,
    title: app.clearanceType,
    subtitle: app.backgroundProvider,
    category: 'clearance',
    filename: app.clearanceDoc,
    meta: [
      { label: 'Issuing Authority', value: app.backgroundProvider },
      { label: 'Clearance Reference', value: app.clearanceNumber },
      { label: 'Verification Status', value: app.backgroundStatus },
    ],
  }
}

function handleApprove() {
  if (!application.value) return
  const result = approveApplication(application.value.id)
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  showApproveDialog.value = false
  toastTone.value = 'success'
  toastMessage.value = result.message
}

function handleReject(reason: string) {
  if (!application.value) return
  const result = rejectApplication(application.value.id, reason)
  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }
  showRejectDialog.value = false
  toastTone.value = 'warning'
  toastMessage.value = result.message
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between gap-4">
      <button
        type="button"
        class="inline-flex items-center space-x-1.5 text-xs font-semibold text-neutral-700 hover:text-neutral-900 cursor-pointer"
        @click="goBack"
      >
        <Icon icon="lucide:arrow-left" class="text-sm" />
        <span>Back</span>
      </button>
    </div>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div v-if="application" class="space-y-6">
      <ApplicationProfileSections
        :application="application"
        :status-tone="getStatusTone(application.status)"
        @open-photo="openFacePhotoViewer"
        @open-license="openLicenseViewer"
        @open-vehicle-doc="openVehicleDocViewer"
        @open-clearance="openClearanceViewer"
      />

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
            @click="showRejectDialog = true"
          >
            Reject Application
          </button>
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="showApproveDialog = true"
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

    <ApplicationDocumentViewerModal
      :document="activeDoc"
      :applicant-name="application?.applicant ?? ''"
      @close="activeDoc = null"
    />

    <ApplicationDecisionModals
      :application="application ?? null"
      :show-approve="showApproveDialog"
      :show-reject="showRejectDialog"
      @update:show-approve="showApproveDialog = $event"
      @update:show-reject="showRejectDialog = $event"
      @confirm-approve="handleApprove"
      @confirm-reject="handleReject"
    />
  </div>
</template>
