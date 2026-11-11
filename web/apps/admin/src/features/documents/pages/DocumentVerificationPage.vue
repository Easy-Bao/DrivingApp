<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { Icon } from '@iconify/vue'
import TablePagination from '@/app/components/TablePagination.vue'

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
  status: 'Pending Review' | 'Approved' | 'Rejected'
}

const pendingDocs = ref<PendingDocument[]>([
  {
    id: 'DOC-901',
    driver: 'Brandon Lee',
    driverPhone: '+63 917 111 2233',
    city: 'Quezon City, Metro Manila',
    docType: "Philippine LTO Driver's License (Professional)",
    issuingAgency: 'Land Transportation Office (LTO Philippines)',
    expiryDate: '2029-08-15',
    submittedAt: '3 hours ago',
    docImageUrl: 'lto_license_front_brandon_lee.png',
    hasTwoSides: true,
    frontScanUrl: 'lto_license_front_brandon_lee.png',
    backScanUrl: 'lto_license_back_brandon_lee.png',
    status: 'Pending Review',
  },
  {
    id: 'DOC-902',
    driver: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    city: 'Pasig City, Metro Manila',
    docType: 'Taxicle MTOP & TODA Franchise Permit',
    issuingAgency: 'Pasig Tricycle Regulatory Unit (TRU)',
    expiryDate: '2027-11-20',
    submittedAt: '4 hours ago',
    docImageUrl: 'mtop_permit_pasig_4912nc.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-903',
    driver: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    city: 'Manila City, Metro Manila',
    docType: 'LTO Official Receipt & Registration (OR/CR)',
    issuingAgency: 'LTO Manila District Office',
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
    city: 'Taguig City, Metro Manila',
    docType: 'NBI National Criminal Clearance',
    issuingAgency: 'National Bureau of Investigation (NBI)',
    expiryDate: '2027-02-18',
    submittedAt: '6 hours ago',
    docImageUrl: 'nbi_clearance_eduardo_santos.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-905',
    driver: 'Maria Lourdes Ramos',
    driverPhone: '+63 920 882 1144',
    city: 'Cebu City',
    docType: "Philippine LTO Driver's License (Back-to-Back)",
    issuingAgency: 'LTO Central Visayas Region 7',
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
    city: 'Davao City',
    docType: 'Taxicle Compulsory TPL Insurance Policy',
    issuingAgency: 'Alpha Insurance & Surety Co.',
    expiryDate: '2027-05-10',
    submittedAt: '1 day ago',
    docImageUrl: 'tpl_insurance_cert_dvo_8821.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-907',
    driver: 'Ramon Valderama',
    driverPhone: '+63 927 334 9912',
    city: 'Caloocan City, Metro Manila',
    docType: 'PNP National Police Clearance',
    issuingAgency: 'Philippine National Police (PNP)',
    expiryDate: '2026-12-08',
    submittedAt: '1 day ago',
    docImageUrl: 'pnp_clearance_ramon_valderama.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-908',
    driver: 'Felipe Cruz',
    driverPhone: '+63 916 445 8821',
    city: 'Pasay City, Metro Manila',
    docType: 'Taxicle Annual Roadworthiness Inspection',
    issuingAgency: 'LTO Motor Vehicle Inspection Center (MVIC)',
    expiryDate: '2027-04-19',
    submittedAt: '2 days ago',
    docImageUrl: 'lto_mvir_inspection_cert_6620nc.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-909',
    driver: 'Antonio Villanueva',
    driverPhone: '+63 939 556 1209',
    city: 'Mandaluyong City, Metro Manila',
    docType: 'TODA Operating Franchise Endorsement',
    issuingAgency: 'Boni-Pioneer TODA Association',
    expiryDate: '2028-09-04',
    submittedAt: '2 days ago',
    docImageUrl: 'toda_franchise_endorsement_1109nd.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-910',
    driver: 'Cristopher Alcantara',
    driverPhone: '+63 921 778 2234',
    city: 'Marikina City, Metro Manila',
    docType: "Philippine LTO Driver's License (Back-to-Back)",
    issuingAgency: 'LTO NCR East Licensing Center',
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
    city: 'Valenzuela City, Metro Manila',
    docType: 'Barangay Commercial Driver Clearance',
    issuingAgency: 'Barangay Malanday Office of the Punong Barangay',
    expiryDate: '2027-01-20',
    submittedAt: '3 days ago',
    docImageUrl: 'barangay_clearance_nestor_3310nc.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-912',
    driver: 'Rodelio Manalo',
    driverPhone: '+63 915 221 8890',
    city: 'Las Pinas City, Metro Manila',
    docType: 'LTO Official Receipt & Registration (OR/CR)',
    issuingAgency: 'LTO Las Pinas District Office',
    expiryDate: '2027-06-15',
    submittedAt: '4 days ago',
    docImageUrl: 'or_cr_taxicle_4481nd.pdf',
    hasTwoSides: true,
    frontScanUrl: 'lto_or_4481nd.png',
    backScanUrl: 'lto_cr_4481nd.png',
    status: 'Pending Review',
  },
  {
    id: 'DOC-913',
    driver: 'Gilberto Soriano',
    driverPhone: '+63 926 771 3344',
    city: 'Paranaque City, Metro Manila',
    docType: 'NBI National Criminal Clearance',
    issuingAgency: 'National Bureau of Investigation (NBI)',
    expiryDate: '2027-03-10',
    submittedAt: '4 days ago',
    docImageUrl: 'nbi_clearance_gilberto_soriano.pdf',
    status: 'Pending Review',
  },
  {
    id: 'DOC-914',
    driver: 'Arnel Pascual',
    driverPhone: '+63 930 119 5566',
    city: 'Antipolo City, Rizal',
    docType: 'Taxicle MTOP & TODA Franchise Permit',
    issuingAgency: 'Antipolo City Tricycle Franchising Board',
    expiryDate: '2028-08-25',
    submittedAt: '5 days ago',
    docImageUrl: 'mtop_permit_antipolo_1920nd.pdf',
    status: 'Pending Review',
  },
])

// Pagination State (10 items max per table)
const currentPage = ref(1)
const itemsPerPage = 10

const paginatedDocs = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return pendingDocs.value.slice(start, start + itemsPerPage)
})

// Review Modal State
const selectedDoc = ref<PendingDocument | null>(null)
const activeSide = ref<'front' | 'back'>('front')
const rejectionReason = ref('')
const isRejecting = ref(false)

// Validation Checklist State
const checks = ref({
  clearScan: true,
  sealVerified: true,
  nameMatches: true,
  validExpiry: true,
})

function openReview(doc: PendingDocument) {
  selectedDoc.value = doc
  activeSide.value = 'front'
  isRejecting.value = false
  rejectionReason.value = ''
  checks.value = {
    clearScan: true,
    sealVerified: true,
    nameMatches: true,
    validExpiry: true,
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
  selectedDoc.value.status = decision
  closeReview()
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
          Review Philippine LTO driver licenses, MTOP tricycle permits, OR/CR registrations, and NBI clearances.
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <span
          class="px-3 py-1.5 bg-blue-50 border border-blue-200 text-xs font-semibold text-blue-800"
        >
          {{ pendingDocs.filter((d) => d.status === 'Pending Review').length }} Pending Verifications
        </span>
      </div>
    </div>

    <!-- Verification Table Container -->
    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Compliance & Regulatory Queue</h2>
        <span class="text-xs text-neutral-400">
          Philippine LTO, NBI, and TRU compliance standards active
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Document ID</th>
              <th class="py-3 px-4">Driver & Contact</th>
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
                <div v-if="doc.hasTwoSides" class="text-[10px] text-emerald-600 font-semibold flex items-center space-x-1 mt-0.5">
                  <Icon icon="lucide:layers" class="text-xs" />
                  <span>2-Sided (Back-to-Back)</span>
                </div>
              </td>
              <td class="py-3 px-4 text-neutral-600">{{ doc.issuingAgency }}</td>
              <td class="py-3 px-4 font-mono">{{ doc.expiryDate }}</td>
              <td class="py-3 px-4">
                <span
                  class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                  :class="
                    doc.status === 'Approved'
                      ? 'bg-emerald-100 text-emerald-800'
                      : doc.status === 'Rejected'
                        ? 'bg-rose-100 text-rose-800'
                        : 'bg-blue-100 text-blue-800'
                  "
                >
                  {{ doc.status }}
                </span>
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  type="button"
                  class="px-3 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer inline-flex items-center space-x-1"
                  @click="openReview(doc)"
                >
                  <Icon icon="lucide:scan" class="text-xs" />
                  <span>Review Document</span>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Table Pagination (10 per page) -->
      <TablePagination
        v-model:current-page="currentPage"
        :total-items="pendingDocs.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <!-- Review & Audit Modal (Fixed Width, Full Close/Exit Capabilities) -->
    <div
      v-if="selectedDoc"
      class="fixed inset-0 z-50 bg-neutral-900/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto"
      @click.self="closeReview"
    >
      <div
        class="bg-white w-full max-w-[680px] shadow-2xl border border-neutral-300 flex flex-col my-auto"
        role="dialog"
        aria-modal="true"
        aria-label="Document Verification Modal"
      >
        <!-- Modal Header with Explicit Close Button -->
        <div class="px-6 py-4 border-b border-neutral-200 flex items-center justify-between bg-neutral-50">
          <div>
            <h3 class="font-bold text-base text-neutral-900">Audit Document Submission</h3>
            <div class="flex items-center space-x-2 text-xs text-neutral-500 mt-0.5">
              <span class="font-mono font-bold text-neutral-800">{{ selectedDoc.id }}</span>
              <span>·</span>
              <span>Submitted {{ selectedDoc.submittedAt }}</span>
            </div>
          </div>
          <!-- Close Button -->
          <button
            type="button"
            class="w-8 h-8 flex items-center justify-center text-neutral-500 hover:text-neutral-900 hover:bg-neutral-200 border border-neutral-200 transition-colors cursor-pointer"
            title="Close modal (Esc)"
            aria-label="Close modal"
            @click="closeReview"
          >
            <Icon icon="lucide:x" class="text-base" />
          </button>
        </div>

        <!-- Modal Content -->
        <div class="p-6 space-y-4 max-h-[75vh] overflow-y-auto text-xs">
          <!-- Driver & Document Metadata Grid -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 p-3 bg-neutral-50 border border-neutral-200">
            <div>
              <span class="text-neutral-400 text-[11px] font-medium">Driver Applicant</span>
              <div class="font-bold text-neutral-900 mt-0.5">{{ selectedDoc.driver }}</div>
              <div class="text-[11px] font-mono text-neutral-600">{{ selectedDoc.driverPhone }}</div>
            </div>
            <div>
              <span class="text-neutral-400 text-[11px] font-medium">Operating City / TODA</span>
              <div class="font-semibold text-neutral-900 mt-0.5">{{ selectedDoc.city }}</div>
            </div>
            <div>
              <span class="text-neutral-400 text-[11px] font-medium">Document Classification</span>
              <div class="font-semibold text-neutral-900 mt-0.5">{{ selectedDoc.docType }}</div>
            </div>
            <div>
              <span class="text-neutral-400 text-[11px] font-medium">Expiration Date</span>
              <div class="font-mono font-bold text-neutral-900 mt-0.5">{{ selectedDoc.expiryDate }}</div>
            </div>
          </div>

          <!-- Back-to-Back Side Toggle (if 2-sided document) -->
          <div v-if="selectedDoc.hasTwoSides" class="flex items-center space-x-2 pt-1">
            <button
              type="button"
              class="px-3 py-1.5 text-xs font-semibold border transition-colors cursor-pointer"
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
              class="px-3 py-1.5 text-xs font-semibold border transition-colors cursor-pointer"
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

          <!-- Document Inspection Canvas -->
          <div class="p-6 bg-neutral-100 border border-neutral-300 text-center space-y-2">
            <div class="w-full max-w-[420px] mx-auto bg-white border border-neutral-300 p-4 shadow-sm text-left">
              <div class="flex items-center justify-between pb-2 border-b border-neutral-200">
                <span class="font-bold text-[11px] text-neutral-900 uppercase">
                  {{ selectedDoc.issuingAgency }}
                </span>
                <span class="text-[10px] font-mono font-semibold text-emerald-700">
                  Seal Valid
                </span>
              </div>
              <div class="py-3 text-xs space-y-1">
                <div class="font-semibold text-neutral-900">{{ selectedDoc.docType }}</div>
                <div class="text-[11px] text-neutral-600">Attached File: {{ selectedDoc.hasTwoSides ? (activeSide === 'front' ? selectedDoc.frontScanUrl : selectedDoc.backScanUrl) : selectedDoc.docImageUrl }}</div>
                <div class="font-mono text-[10px] text-neutral-400">Cryptographic Hash: sha256:7f99120...verified</div>
              </div>
              <div class="pt-2 border-t border-neutral-100 flex items-center justify-between text-[11px]">
                <span class="text-neutral-500">Applicant: {{ selectedDoc.driver }}</span>
                <span class="font-mono text-neutral-700">{{ selectedDoc.expiryDate }}</span>
              </div>
            </div>
          </div>

          <!-- Regulatory Checklist -->
          <div class="border border-neutral-200 p-3 bg-neutral-50/50 space-y-2">
            <div class="font-bold text-neutral-900 text-xs">Official Compliance Verification Checklist</div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
              <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer">
                <input v-model="checks.clearScan" type="checkbox" class="text-neutral-900 accent-neutral-900" />
                <span>Legible high-resolution submission</span>
              </label>
              <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer">
                <input v-model="checks.sealVerified" type="checkbox" class="text-neutral-900 accent-neutral-900" />
                <span>Philippine agency watermark / QR valid</span>
              </label>
              <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer">
                <input v-model="checks.nameMatches" type="checkbox" class="text-neutral-900 accent-neutral-900" />
                <span>Name matches driver identity</span>
              </label>
              <label class="flex items-center space-x-2 text-neutral-700 cursor-pointer">
                <input v-model="checks.validExpiry" type="checkbox" class="text-neutral-900 accent-neutral-900" />
                <span>Active validity (> 6 months period)</span>
              </label>
            </div>
          </div>

          <!-- Rejection Ground Input (if rejecting) -->
          <div v-if="isRejecting" class="p-3 bg-rose-50 border border-rose-200 space-y-2">
            <div class="font-bold text-rose-900 text-xs">Specify Regulatory Rejection Grounds</div>
            <select
              v-model="rejectionReason"
              class="w-full p-2 bg-white border border-rose-300 text-xs text-neutral-800 focus:outline-none focus:ring-1 focus:ring-rose-500"
            >
              <option value="">-- Select Rejection Ground --</option>
              <option value="Image blurred or unreadable official seal">Image blurred or unreadable official seal</option>
              <option value="Document expired or near expiration (< 60 days)">Document expired or near expiration (&lt; 60 days)</option>
              <option value="Applicant identity does not match LTO / TRU records">Applicant identity does not match LTO / TRU records</option>
              <option value="Missing reverse/back side scan of government ID">Missing reverse/back side scan of government ID</option>
              <option value="Invalid TODA franchise or expired MTOP municipal permit">Invalid TODA franchise or expired MTOP municipal permit</option>
            </select>
          </div>
        </div>

        <!-- Modal Footer: Explicit Cancel/Exit Button + Actions -->
        <div class="px-6 py-4 border-t border-neutral-200 bg-neutral-50 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <!-- Cancel / Close button -->
          <button
            type="button"
            class="px-4 py-2 border border-neutral-300 text-neutral-700 hover:bg-neutral-100 text-xs font-semibold transition-colors cursor-pointer"
            @click="closeReview"
          >
            Cancel & Exit
          </button>

          <div class="flex items-center space-x-2">
            <button
              v-if="!isRejecting"
              type="button"
              class="px-4 py-2 border border-rose-300 text-rose-700 hover:bg-rose-50 text-xs font-semibold transition-colors cursor-pointer"
              @click="isRejecting = true"
            >
              Reject Document
            </button>
            <button
              v-else
              type="button"
              class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold transition-colors cursor-pointer"
              @click="verifyDoc('Rejected')"
            >
              Confirm Rejection
            </button>

            <button
              type="button"
              class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
              @click="verifyDoc('Approved')"
            >
              Approve & Validate
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
