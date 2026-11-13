<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import TablePagination from '@/app/components/TablePagination.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

interface RejectedDocument {
  id: string
  driver: string
  driverPhone: string
  city: string
  docType: string
  rejectionReason: string
  rejectedBy: string
  rejectedAt: string
  resubmitted: boolean
  reopened?: boolean
}

const rejectedDocs = ref<RejectedDocument[]>([
  {
    id: 'REJ-401',
    driver: 'Javier Santos',
    driverPhone: '+63 917 987 6543',
    city: 'Brgy. San Pedro',
    docType: 'LTO Driver License Back Photo',
    rejectionReason: 'Reverse barcode scan blurred; LTO restriction codes unreadable',
    rejectedBy: 'Marisol Lim',
    rejectedAt: 'Yesterday 14:20',
    resubmitted: false,
  },
  {
    id: 'REJ-402',
    driver: 'Rodelio Cruz',
    driverPhone: '+63 917 440 2184',
    city: 'Brgy. San Jose',
    docType: 'CTPL Insurance Certificate',
    rejectionReason: 'Policyholder name does not match applicant identity on LTO OR/CR',
    rejectedBy: 'Operations Lead',
    rejectedAt: '3 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-403',
    driver: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    city: 'Brgy. Tuburan',
    docType: 'MTOP Municipal Tricycle Permit',
    rejectionReason: 'Expired MTOP permit without stamped city treasurer official receipt',
    rejectedBy: 'Operations Lead',
    rejectedAt: '4 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-404',
    driver: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    city: 'Brgy. Balangasan',
    docType: 'PNP National Police Clearance',
    rejectionReason: 'Document expired; issuance date exceeds 6 months validity',
    rejectedBy: 'Marisol Lim',
    rejectedAt: '5 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-405',
    driver: 'Eduardo Santos',
    driverPhone: '+63 919 332 4455',
    city: 'Brgy. Kawit',
    docType: 'LTO Certificate of Registration',
    rejectionReason: 'Chassis number illegible on mobile camera photograph',
    rejectedBy: 'Operations Lead',
    rejectedAt: '6 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-406',
    driver: 'Felipe Cruz',
    driverPhone: '+63 916 445 8821',
    city: 'Brgy. Tiguma',
    docType: 'Barangay Driver Clearance',
    rejectionReason: 'Barangay clearance jurisdiction differs from assigned TODA zone',
    rejectedBy: 'Marisol Lim',
    rejectedAt: '1 week ago',
    resubmitted: false,
  },
  {
    id: 'REJ-407',
    driver: 'Antonio Villanueva',
    driverPhone: '+63 939 556 1209',
    city: 'Brgy. Dao',
    docType: 'LTO Driver License Front Side',
    rejectionReason: 'Flash glare obscuring birthdate and driver license number',
    rejectedBy: 'Operations Lead',
    rejectedAt: '10 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-408',
    driver: 'Cristopher Alcantara',
    driverPhone: '+63 921 778 2234',
    city: 'Brgy. Santiago',
    docType: 'Annual Inspection Certificate',
    rejectionReason: 'Inspection report missing official MVIC verifier signature',
    rejectedBy: 'Operations Lead',
    rejectedAt: '12 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-409',
    driver: 'Nestor Macaraeg',
    driverPhone: '+63 947 889 1120',
    city: 'Brgy. Danlugan',
    docType: 'NBI National Criminal Clearance',
    rejectionReason: 'Clearance QR code not scannable; re-upload required',
    rejectedBy: 'Marisol Lim',
    rejectedAt: '2 weeks ago',
    resubmitted: false,
  },
])

const searchQuery = ref('')
const resubFilter = ref<'ALL' | 'RESUBMITTED' | 'AWAITING'>('ALL')
const currentPage = ref(1)
const itemsPerPage = 10
const inspectedRejected = ref<RejectedDocument | null>(null)
const toastMessage = ref<string | null>(null)

const filteredRejected = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return rejectedDocs.value.filter((item) => {
    if (resubFilter.value === 'RESUBMITTED' && !item.resubmitted) return false
    if (resubFilter.value === 'AWAITING' && item.resubmitted) return false
    if (!q) return true
    return (
      item.id.toLowerCase().includes(q) ||
      item.driver.toLowerCase().includes(q) ||
      item.docType.toLowerCase().includes(q) ||
      item.rejectionReason.toLowerCase().includes(q)
    )
  })
})

watch([searchQuery, resubFilter], () => {
  currentPage.value = 1
})

const paginatedRejectedDocs = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredRejected.value.slice(start, start + itemsPerPage)
})

const queueForReReview = (item: RejectedDocument) => {
  item.reopened = true
  inspectedRejected.value = null
  toastMessage.value = `${item.id} (${item.driver}) moved back to active verification queue.`
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Rejected Driver Documents
      </h1>
      <p class="text-sm text-neutral-500 mt-1">Rejected driver documents and resubmissions.</p>
    </div>

    <ToastBanner :message="toastMessage" tone="info" @dismiss="toastMessage = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
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
              placeholder="Search log ID, driver, reason..."
              class="w-full pl-8 pr-3 py-1.5 bg-white border border-neutral-200 text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <BaseSelect
            v-model="resubFilter"
            aria-label="Filter by resubmission status"
            :options="[
              { label: 'All Submissions', value: 'ALL' },
              { label: 'Resubmitted Ready', value: 'RESUBMITTED' },
              { label: 'Awaiting Driver Upload', value: 'AWAITING' },
            ]"
          />
        </div>
        <span class="text-xs text-neutral-400">Maintained for legal compliance audits</span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[840px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Log ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Document</th>
              <th class="py-3 px-4">Rejection Grounds</th>
              <th class="py-3 px-4">Auditor</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="item in paginatedRejectedDocs"
              :key="item.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ item.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ item.driver }}</div>
                <div class="text-[11px] text-neutral-400 font-mono">{{ item.driverPhone }}</div>
                <div class="text-[10px] text-neutral-400">{{ item.city }}</div>
              </td>
              <td class="py-3 px-4 font-medium text-neutral-800">{{ item.docType }}</td>
              <td class="py-3 px-4 text-neutral-600 max-w-[240px]">{{ item.rejectionReason }}</td>
              <td class="py-3 px-4 text-neutral-500">
                <div>{{ item.rejectedBy }}</div>
                <div class="font-mono text-[10px] text-neutral-400">{{ item.rejectedAt }}</div>
              </td>
              <td class="py-3 px-4 whitespace-nowrap">
                <StatusBadge
                  :label="
                    item.reopened
                      ? 'Queued for Re-Review'
                      : item.resubmitted
                        ? 'Resubmitted'
                        : 'Awaiting Upload'
                  "
                  :tone="item.reopened ? 'success' : item.resubmitted ? 'info' : 'danger'"
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  @click="inspectedRejected = item"
                  class="text-xs font-semibold text-neutral-800 hover:text-neutral-900 cursor-pointer"
                >
                  Inspect
                </button>
              </td>
            </tr>
            <tr v-if="paginatedRejectedDocs.length === 0">
              <td colspan="7" class="py-8 text-center text-xs text-neutral-500">
                No rejected document logs match the filter.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredRejected.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <Teleport to="body">
      <div
        v-if="inspectedRejected"
        class="fixed inset-0 z-50 flex items-center justify-center bg-neutral-900/50 backdrop-blur-[1px] p-4"
        role="dialog"
        aria-modal="true"
        @click.self="inspectedRejected = null"
      >
        <div class="bg-white border border-neutral-200 shadow-2xl w-full max-w-md p-6 space-y-4">
          <div class="flex items-start justify-between border-b border-neutral-100 pb-3">
            <div>
              <span class="font-mono text-[11px] text-neutral-400">{{ inspectedRejected.id }}</span>
              <h3 class="text-base font-bold text-neutral-900">{{ inspectedRejected.docType }}</h3>
            </div>
            <button
              type="button"
              aria-label="Close modal"
              @click="inspectedRejected = null"
              class="text-neutral-400 hover:text-neutral-700 cursor-pointer"
            >
              <Icon icon="lucide:x" class="w-4 h-4" />
            </button>
          </div>

          <div class="space-y-2 text-xs">
            <div>
              <span class="text-neutral-500">Applicant:</span>
              <span class="font-semibold text-neutral-900 ml-1">{{
                inspectedRejected.driver
              }}</span>
              <span class="font-mono text-neutral-500 ml-1"
                >({{ inspectedRejected.driverPhone }})</span
              >
            </div>
            <div>
              <span class="text-neutral-500">Location:</span>
              <span class="text-neutral-800 ml-1">{{ inspectedRejected.city }}</span>
            </div>
            <div class="p-3 bg-neutral-50 border border-neutral-300 text-neutral-800">
              <div class="font-semibold mb-1">Recorded Rejection Grounds</div>
              <p>{{ inspectedRejected.rejectionReason }}</p>
            </div>
          </div>

          <div class="flex items-center justify-end gap-2 pt-2 border-t border-neutral-100">
            <button
              type="button"
              @click="inspectedRejected = null"
              class="px-4 py-2 bg-white border border-neutral-200 text-xs font-semibold text-neutral-700 hover:bg-neutral-50 cursor-pointer"
            >
              Close
            </button>
            <button
              v-if="inspectedRejected.resubmitted && !inspectedRejected.reopened"
              type="button"
              @click="queueForReReview(inspectedRejected)"
              class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
            >
              Re-Open for Verification
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
