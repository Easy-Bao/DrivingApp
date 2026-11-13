<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import TablePagination from '@/app/components/TablePagination.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

type VerificationStatus = 'Pending Review' | 'Approved' | 'Rejected'

interface PendingDocument {
  id: string
  driver: string
  driverPhone: string
  city: string
  docType: string
  issuingAgency: string
  expiryDate: string
  submittedAt: string
  docImageUrl: string
  hasTwoSides?: boolean
  frontScanUrl?: string
  backScanUrl?: string
  status: VerificationStatus
  rejectionReason?: string
}

function makeDocPreviewSvg(title: string, holder: string, agency: string, docId: string): string {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="520" height="240" viewBox="0 0 520 240">
    <rect width="520" height="240" rx="10" fill="#f8fafc" stroke="#cbd5e1" stroke-width="2"/>
    <rect width="520" height="44" rx="10" fill="#0f172a"/>
    <rect y="34" width="520" height="10" fill="#0f172a"/>
    <text x="20" y="27" fill="#ffffff" font-family="sans-serif" font-size="12" font-weight="700">${agency}</text>
    <text x="500" y="27" text-anchor="end" fill="#94a3b8" font-family="monospace" font-size="11">${docId}</text>
    <rect x="20" y="64" width="84" height="106" rx="6" fill="#e2e8f0" stroke="#cbd5e1"/>
    <circle cx="62" cy="100" r="18" fill="#94a3b8"/>
    <path d="M32 152c0-18 14-28 30-28s30 10 30 28" fill="#94a3b8"/>
    <text x="124" y="84" fill="#64748b" font-family="sans-serif" font-size="10">DOCUMENT CLASSIFICATION</text>
    <text x="124" y="102" fill="#0f172a" font-family="sans-serif" font-size="13" font-weight="700">${title}</text>
    <text x="124" y="128" fill="#64748b" font-family="sans-serif" font-size="10">HOLDER / APPLICANT</text>
    <text x="124" y="146" fill="#0f172a" font-family="sans-serif" font-size="13" font-weight="700">${holder}</text>
    <text x="124" y="176" fill="#059669" font-family="monospace" font-size="11" font-weight="700">LTO / PAGADIAN CITY SEAL PRESENT</text>
    <text x="20" y="218" fill="#64748b" font-family="monospace" font-size="10">REGION IX · PAGADIAN CITY (7016) COMPLIANCE CAPTURE</text>
  </svg>`
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`
}

const pendingDocs = ref<PendingDocument[]>([
  {
    id: 'DOC-901',
    driver: 'Rodelio Cruz',
    driverPhone: '+63 917 440 2184',
    city: 'Pagadian City (Brgy. San Jose)',
    docType: 'LTO Professional Driver License',
    issuingAgency: 'LTO Region IX — Pagadian District',
    expiryDate: '2029-08-15',
    submittedAt: '3 hours ago',
    docImageUrl: 'lto_license_front_rodelio_cruz.png',
    hasTwoSides: true,
    frontScanUrl: 'lto_license_front_rodelio_cruz.png',
    backScanUrl: 'lto_license_back_rodelio_cruz.png',
    status: 'Pending Review',
  },
  {
    id: 'DOC-902',
    driver: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    city: 'Pagadian City (Brgy. Tuburan)',
    docType: 'Taxicle MTOP & TODA Franchise Permit',
    issuingAgency: 'Pagadian City Tricycle Franchising Board',
    expiryDate: '2027-11-20',
    submittedAt: '4 hours ago',
    docImageUrl: 'mtop_permit_pagadian_4912nc.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-903',
    driver: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    city: 'Pagadian City (Brgy. Balangasan)',
    docType: 'LTO Official Receipt & Registration (OR/CR)',
    issuingAgency: 'LTO Pagadian City Extension Office',
    expiryDate: '2026-10-14',
    submittedAt: '5 hours ago',
    docImageUrl: 'lto_or_cr_taxicle_9021nd.pdf',
    hasTwoSides: true,
    frontScanUrl: 'lto_or_front_9021nd.png',
    backScanUrl: 'lto_cr_back_9021nd.png',
    status: 'Pending Review',
  },
  {
    id: 'DOC-904',
    driver: 'Eduardo Santos',
    driverPhone: '+63 919 332 4455',
    city: 'Pagadian City (Brgy. Kawit)',
    docType: 'NBI National Criminal Clearance',
    issuingAgency: 'NBI Pagadian City District Office',
    expiryDate: '2027-02-18',
    submittedAt: '6 hours ago',
    docImageUrl: 'nbi_clearance_eduardo_santos.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-905',
    driver: 'Maria Lourdes Ramos',
    driverPhone: '+63 920 882 1144',
    city: 'Pagadian City (Brgy. Santa Lucia)',
    docType: 'LTO Professional Driver License',
    issuingAgency: 'LTO Region IX — Pagadian District',
    expiryDate: '2029-03-22',
    submittedAt: '1 day ago',
    docImageUrl: 'lto_license_front_maria_ramos.png',
    hasTwoSides: true,
    frontScanUrl: 'lto_license_front_maria_ramos.png',
    backScanUrl: 'lto_license_back_maria_ramos.png',
    status: 'Pending Review',
  },
  {
    id: 'DOC-906',
    driver: 'Jose Mari Bautista',
    driverPhone: '+63 918 665 4411',
    city: 'Pagadian City (Brgy. Gatas)',
    docType: 'Taxicle Compulsory TPL Insurance Policy',
    issuingAgency: 'Standard Insurance — Pagadian Branch',
    expiryDate: '2027-05-10',
    submittedAt: '1 day ago',
    docImageUrl: 'tpl_insurance_cert_pagadian_8821.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-907',
    driver: 'Javier Santos',
    driverPhone: '+63 917 987 6543',
    city: 'Pagadian City (Brgy. San Pedro)',
    docType: 'PNP National Police Clearance',
    issuingAgency: 'Pagadian City Police Station',
    expiryDate: '2026-12-08',
    submittedAt: '1 day ago',
    docImageUrl: 'pnp_clearance_javier_santos.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-908',
    driver: 'Felipe Cruz',
    driverPhone: '+63 916 445 8821',
    city: 'Pagadian City (Brgy. Tiguma)',
    docType: 'Taxicle Annual Roadworthiness Inspection',
    issuingAgency: 'LTO Motor Vehicle Inspection Center (ZDS)',
    expiryDate: '2027-04-19',
    submittedAt: '2 days ago',
    docImageUrl: 'lto_mvir_inspection_cert_6620nc.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-909',
    driver: 'Antonio Villanueva',
    driverPhone: '+63 939 556 1209',
    city: 'Pagadian City (Brgy. Dao)',
    docType: 'TODA Operating Franchise Endorsement',
    issuingAgency: 'Dao - Provincial Hospital TODA',
    expiryDate: '2028-09-04',
    submittedAt: '2 days ago',
    docImageUrl: 'toda_franchise_endorsement_1109nd.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-910',
    driver: 'Cristopher Alcantara',
    driverPhone: '+63 921 778 2234',
    city: 'Pagadian City (Brgy. Santiago)',
    docType: 'LTO Professional Driver License',
    issuingAgency: 'LTO Region IX — Pagadian District',
    expiryDate: '2031-02-17',
    submittedAt: '3 days ago',
    docImageUrl: 'lto_license_front_cristopher.png',
    hasTwoSides: true,
    frontScanUrl: 'lto_license_front_cristopher.png',
    backScanUrl: 'lto_license_back_cristopher.png',
    status: 'Pending Review',
  },
  {
    id: 'DOC-911',
    driver: 'Nestor Macaraeg',
    driverPhone: '+63 947 889 1120',
    city: 'Pagadian City (Brgy. Danlugan)',
    docType: 'Barangay Commercial Driver Clearance',
    issuingAgency: 'Barangay Danlugan Office',
    expiryDate: '2027-01-20',
    submittedAt: '3 days ago',
    docImageUrl: 'barangay_clearance_nestor_3310nc.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-912',
    driver: 'Ernesto Manalo',
    driverPhone: '+63 915 221 8890',
    city: 'Pagadian City (Brgy. Bulatok)',
    docType: 'LTO Official Receipt & Registration (OR/CR)',
    issuingAgency: 'LTO Pagadian City Extension Office',
    expiryDate: '2027-06-15',
    submittedAt: '4 days ago',
    docImageUrl: 'or_cr_taxicle_4481nd.pdf',
    hasTwoSides: true,
    frontScanUrl: 'lto_or_4481nd.png',
    backScanUrl: 'lto_cr_4481nd.png',
    status: 'Pending Review',
  },
])

const searchQuery = ref('')
const statusFilter = ref<'ALL' | VerificationStatus>('ALL')
const currentPage = ref(1)
const itemsPerPage = 10
const toastMessage = ref<string | null>(null)
const toastTone = ref<'success' | 'warning' | 'error'>('success')

const filteredDocs = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return pendingDocs.value.filter((doc) => {
    if (statusFilter.value !== 'ALL' && doc.status !== statusFilter.value) {
      return false
    }
    if (!q) return true
    return (
      doc.id.toLowerCase().includes(q) ||
      doc.driver.toLowerCase().includes(q) ||
      doc.docType.toLowerCase().includes(q) ||
      doc.issuingAgency.toLowerCase().includes(q) ||
      doc.city.toLowerCase().includes(q)
    )
  })
})

watch([searchQuery, statusFilter], () => {
  currentPage.value = 1
})

const paginatedDocs = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredDocs.value.slice(start, start + itemsPerPage)
})

const selectedDoc = ref<PendingDocument | null>(null)
const activeSide = ref<'front' | 'back'>('front')
const rejectionReason = ref('')
const isRejecting = ref(false)

const checks = ref({
  clearScan: false,
  sealVerified: false,
  nameMatches: false,
  validExpiry: false,
})

const allChecksPassed = computed(
  () =>
    checks.value.clearScan &&
    checks.value.sealVerified &&
    checks.value.nameMatches &&
    checks.value.validExpiry,
)

const activePreviewDataUrl = computed(() => {
  if (!selectedDoc.value) return ''
  const label = selectedDoc.value.hasTwoSides
    ? `${selectedDoc.value.docType} (${activeSide.value === 'front' ? 'Front' : 'Back'})`
    : selectedDoc.value.docType
  return makeDocPreviewSvg(
    label,
    selectedDoc.value.driver,
    selectedDoc.value.issuingAgency,
    selectedDoc.value.id,
  )
})

function openReview(doc: PendingDocument) {
  selectedDoc.value = doc
  activeSide.value = 'front'
  isRejecting.value = false
  rejectionReason.value = doc.rejectionReason ?? ''
  checks.value = {
    clearScan: doc.status === 'Approved',
    sealVerified: doc.status === 'Approved',
    nameMatches: doc.status === 'Approved',
    validExpiry: doc.status === 'Approved',
  }
}

function closeReview() {
  selectedDoc.value = null
  isRejecting.value = false
  rejectionReason.value = ''
}

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape' && selectedDoc.value) {
    closeReview()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})

function verifyDoc(decision: 'Approved' | 'Rejected') {
  if (!selectedDoc.value) return
  if (decision === 'Approved' && !allChecksPassed.value) return
  if (decision === 'Rejected' && !rejectionReason.value.trim()) return

  selectedDoc.value.status = decision
  selectedDoc.value.rejectionReason =
    decision === 'Rejected' ? rejectionReason.value.trim() : undefined

  toastTone.value = decision === 'Approved' ? 'success' : 'warning'
  toastMessage.value =
    decision === 'Approved'
      ? `${selectedDoc.value.id} approved for ${selectedDoc.value.driver}.`
      : `${selectedDoc.value.id} rejected (${rejectionReason.value.trim()}).`
  closeReview()
}

const statusTone = (status: VerificationStatus) => {
  if (status === 'Approved') return 'success'
  if (status === 'Rejected') return 'danger'
  return 'info'
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Driver Document Verification Queue
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Verify Pagadian LTO licenses, MTOP tricycle permits, OR/CR registrations, and NBI
          clearances.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span
          class="px-3 py-1.5 bg-blue-50 border border-blue-200 rounded-md text-xs font-semibold text-blue-800"
        >
          {{ pendingDocs.filter((d) => d.status === 'Pending Review').length }} Pending
          Verifications
        </span>
      </div>
    </div>

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="bg-white rounded-lg border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col md:flex-row md:items-center justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="relative w-full sm:w-64">
            <Icon
              icon="lucide:search"
              class="w-3.5 h-3.5 text-neutral-400 absolute left-3 top-1/2 -translate-y-1/2"
            />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search doc ID, driver, barangay..."
              class="w-full pl-8 pr-3 py-1.5 bg-white border border-neutral-200 rounded-md text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <select
            v-model="statusFilter"
            aria-label="Filter documents by verification status"
            class="px-3 py-1.5 bg-white border border-neutral-200 rounded-md text-xs font-medium text-neutral-700 focus:outline-none focus:border-neutral-900 cursor-pointer"
          >
            <option value="ALL">All Statuses</option>
            <option value="Pending Review">Pending Review</option>
            <option value="Approved">Approved</option>
            <option value="Rejected">Rejected</option>
          </select>
        </div>
        <span class="text-xs text-neutral-400">
          LTO, NBI, and Pagadian City TRU compliance standards
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[840px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Document ID</th>
              <th class="py-3 px-4">Driver &amp; Contact</th>
              <th class="py-3 px-4">Document Type</th>
              <th class="py-3 px-4">Issuing Authority</th>
              <th class="py-3 px-4">Expiry Date</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="doc in paginatedDocs"
              :key="doc.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ doc.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ doc.driver }}</div>
                <div class="text-[11px] text-neutral-400 font-mono">{{ doc.driverPhone }}</div>
                <div class="text-[10px] text-neutral-400">{{ doc.city }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-900">{{ doc.docType }}</div>
                <div
                  v-if="doc.hasTwoSides"
                  class="text-[10px] text-emerald-600 font-semibold flex items-center space-x-1 mt-0.5"
                >
                  <Icon icon="lucide:layers" class="text-xs" />
                  <span>2-Sided (Front &amp; Back)</span>
                </div>
              </td>
              <td class="py-3 px-4 text-neutral-600">{{ doc.issuingAgency }}</td>
              <td class="py-3 px-4 font-mono">{{ doc.expiryDate }}</td>
              <td class="py-3 px-4">
                <StatusBadge :label="doc.status" :tone="statusTone(doc.status)" />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white rounded-md text-xs font-semibold transition-colors cursor-pointer inline-flex items-center space-x-1"
                  @click="openReview(doc)"
                >
                  <Icon icon="lucide:scan" class="text-xs" />
                  <span>Review Document</span>
                </button>
              </td>
            </tr>
            <tr v-if="paginatedDocs.length === 0">
              <td colspan="7" class="py-8 text-center text-xs text-neutral-500">
                No documents match the active filter criteria.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredDocs.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <Teleport to="body">
      <div
        v-if="selectedDoc"
        class="fixed inset-0 z-50 bg-neutral-900/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto"
        @click.self="closeReview"
      >
        <div
          class="bg-white rounded-lg w-full max-w-[680px] shadow-2xl border border-neutral-200 flex flex-col my-auto overflow-hidden"
          role="dialog"
          aria-modal="true"
          aria-label="Document Verification Modal"
        >
          <div
            class="px-6 py-4 border-b border-neutral-200 flex items-center justify-between bg-neutral-50"
          >
            <div>
              <h3 class="font-bold text-base text-neutral-900">Audit Document Submission</h3>
              <div class="flex items-center space-x-2 text-xs text-neutral-500 mt-0.5">
                <span class="font-mono font-bold text-neutral-800">{{ selectedDoc.id }}</span>
                <span>·</span>
                <span>Submitted {{ selectedDoc.submittedAt }}</span>
              </div>
            </div>
            <button
              type="button"
              class="w-8 h-8 flex items-center justify-center text-neutral-500 hover:text-neutral-900 hover:bg-neutral-200 rounded-md border border-neutral-200 transition-colors cursor-pointer"
              title="Close modal (Esc)"
              aria-label="Close modal"
              @click="closeReview"
            >
              <Icon icon="lucide:x" class="text-base" />
            </button>
          </div>

          <div class="p-6 space-y-4 max-h-[75vh] overflow-y-auto text-xs">
            <div
              class="grid grid-cols-1 sm:grid-cols-2 gap-3 p-3 bg-neutral-50 rounded-md border border-neutral-200"
            >
              <div>
                <span class="text-neutral-400 text-[11px] font-medium">Driver Applicant</span>
                <div class="font-bold text-neutral-900 mt-0.5">{{ selectedDoc.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-600">
                  {{ selectedDoc.driverPhone }}
                </div>
              </div>
              <div>
                <span class="text-neutral-400 text-[11px] font-medium">Operating City / TODA</span>
                <div class="font-semibold text-neutral-900 mt-0.5">{{ selectedDoc.city }}</div>
              </div>
              <div>
                <span class="text-neutral-400 text-[11px] font-medium"
                  >Document Classification</span
                >
                <div class="font-semibold text-neutral-900 mt-0.5">{{ selectedDoc.docType }}</div>
              </div>
              <div>
                <span class="text-neutral-400 text-[11px] font-medium">Expiration Date</span>
                <div class="font-mono font-bold text-neutral-900 mt-0.5">
                  {{ selectedDoc.expiryDate }}
                </div>
              </div>
            </div>

            <div v-if="selectedDoc.hasTwoSides" class="flex items-center space-x-2 pt-1">
              <button
                type="button"
                class="px-3 py-1.5 rounded-md text-xs font-semibold border transition-colors cursor-pointer"
                :class="
                  activeSide === 'front'
                    ? 'bg-neutral-900 text-white border-neutral-900'
                    : 'bg-white text-neutral-700 border-neutral-200 hover:bg-neutral-100'
                "
                @click="activeSide = 'front'"
              >
                Front Side Scan
              </button>
              <button
                type="button"
                class="px-3 py-1.5 rounded-md text-xs font-semibold border transition-colors cursor-pointer"
                :class="
                  activeSide === 'back'
                    ? 'bg-neutral-900 text-white border-neutral-900'
                    : 'bg-white text-neutral-700 border-neutral-200 hover:bg-neutral-100'
                "
                @click="activeSide = 'back'"
              >
                Back Side Scan
              </button>
            </div>

            <div class="p-3 bg-neutral-100 rounded-md border border-neutral-200 space-y-2">
              <img
                :src="activePreviewDataUrl"
                :alt="`${selectedDoc.docType} scan for ${selectedDoc.driver}`"
                class="w-full rounded border border-neutral-300 bg-white object-contain max-h-56"
              />
              <div
                class="flex items-center justify-between text-[11px] font-mono text-neutral-600 px-1"
              >
                <span>
                  File:
                  {{
                    selectedDoc.hasTwoSides
                      ? activeSide === 'front'
                        ? selectedDoc.frontScanUrl
                        : selectedDoc.backScanUrl
                      : selectedDoc.docImageUrl
                  }}
                </span>
                <span class="text-emerald-700 font-semibold">sha256 verified</span>
              </div>
            </div>

            <div class="border border-neutral-200 rounded-md p-3 bg-neutral-50/50 space-y-2">
              <div class="font-bold text-neutral-900 text-xs">
                Official Compliance Verification Checklist (all required to approve)
              </div>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer">
                  <input v-model="checks.clearScan" type="checkbox" class="accent-neutral-900" />
                  <span>Legible high-resolution submission</span>
                </label>
                <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer">
                  <input v-model="checks.sealVerified" type="checkbox" class="accent-neutral-900" />
                  <span>Agency watermark / QR code valid</span>
                </label>
                <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer">
                  <input v-model="checks.nameMatches" type="checkbox" class="accent-neutral-900" />
                  <span>Name matches driver identity</span>
                </label>
                <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer">
                  <input v-model="checks.validExpiry" type="checkbox" class="accent-neutral-900" />
                  <span>Active validity (&gt; 6 months period)</span>
                </label>
              </div>
            </div>

            <div
              v-if="isRejecting"
              class="p-3 bg-rose-50 border border-rose-200 rounded-md space-y-2"
            >
              <div class="font-bold text-rose-900 text-xs">
                Specify Regulatory Rejection Grounds (mandatory)
              </div>
              <select
                v-model="rejectionReason"
                aria-label="Regulatory rejection ground"
                class="w-full p-2 bg-white border border-rose-300 rounded-md text-xs text-neutral-800 focus:outline-none focus:ring-1 focus:ring-rose-500"
              >
                <option value="">-- Select Rejection Ground --</option>
                <option value="Image blurred or unreadable official seal">
                  Image blurred or unreadable official seal
                </option>
                <option value="Document expired or near expiration (&lt; 60 days)">
                  Document expired or near expiration (&lt; 60 days)
                </option>
                <option value="Applicant identity does not match LTO / TRU records">
                  Applicant identity does not match LTO / TRU records
                </option>
                <option value="Missing reverse/back side scan of government ID">
                  Missing reverse/back side scan of government ID
                </option>
                <option value="Invalid TODA franchise or expired MTOP municipal permit">
                  Invalid TODA franchise or expired MTOP municipal permit
                </option>
              </select>
            </div>
          </div>

          <div
            class="px-6 py-4 border-t border-neutral-200 bg-neutral-50 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3"
          >
            <button
              type="button"
              class="px-4 py-2 border border-neutral-300 text-neutral-700 hover:bg-neutral-100 rounded-md text-xs font-semibold transition-colors cursor-pointer"
              @click="closeReview"
            >
              Cancel &amp; Exit
            </button>

            <div class="flex items-center space-x-2">
              <button
                v-if="!isRejecting"
                type="button"
                class="px-4 py-2 border border-rose-300 text-rose-700 hover:bg-rose-50 rounded-md text-xs font-semibold transition-colors cursor-pointer"
                @click="isRejecting = true"
              >
                Reject Document
              </button>
              <button
                v-else
                type="button"
                :disabled="!rejectionReason.trim()"
                class="px-4 py-2 bg-rose-600 hover:bg-rose-700 disabled:opacity-40 text-white rounded-md text-xs font-semibold transition-colors cursor-pointer"
                @click="verifyDoc('Rejected')"
              >
                Confirm Rejection
              </button>

              <button
                type="button"
                :disabled="!allChecksPassed"
                class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 disabled:opacity-40 text-white rounded-md text-xs font-semibold transition-colors cursor-pointer"
                @click="verifyDoc('Approved')"
              >
                Approve &amp; Validate
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
