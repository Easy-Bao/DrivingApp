<script setup lang="ts">
import { computed, ref } from 'vue'
import TablePagination from '@/app/components/TablePagination.vue'

const rejectedDocs = ref([
  {
    id: 'REJ-401',
    driver: 'Javier Santos',
    driverPhone: '+63 917 987 6543',
    city: 'Quezon City',
    docType: "LTO Driver's License Back Photo",
    rejectionReason: 'Reverse barcode scan blurred; LTO restriction codes unreadable',
    rejectedBy: 'Admin User',
    rejectedAt: 'Yesterday 14:20',
    resubmitted: false,
  },
  {
    id: 'REJ-402',
    driver: 'Fatima Al-Mansoor',
    driverPhone: '+63 928 444 5566',
    city: 'Pasig City',
    docType: 'Taxicle CTPL Insurance Certificate',
    rejectionReason: 'Policyholder name does not match applicant identity on LTO OR/CR',
    rejectedBy: 'Super Admin',
    rejectedAt: '3 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-403',
    driver: 'Vicente Legaspi',
    driverPhone: '+63 917 882 4433',
    city: 'Davao City',
    docType: 'Davao MTOP Municipal Tricycle Permit',
    rejectionReason: 'Expired MTOP permit without stamped city treasurer official receipt',
    rejectedBy: 'Operations Lead',
    rejectedAt: '4 days ago',
    resubmitted: false,
  },
  {
    id: 'REJ-404',
    driver: 'Ramon Valderama',
    driverPhone: '+63 927 334 9912',
    city: 'Caloocan City',
    docType: 'PNP National Police Clearance',
    rejectionReason: 'Document expired; issuance date exceeds 6 months validity',
    rejectedBy: 'Admin User',
    rejectedAt: '5 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-405',
    driver: 'Eduardo Santos',
    driverPhone: '+63 919 332 4455',
    city: 'Taguig City',
    docType: 'LTO Certificate of Registration (CR)',
    rejectionReason: 'Chassis number illegible on mobile camera photograph',
    rejectedBy: 'Super Admin',
    rejectedAt: '6 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-406',
    driver: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    city: 'Pasig City',
    docType: 'TODA Operating Franchise Endorsement',
    rejectionReason: 'Missing TODA president signature and association dry seal',
    rejectedBy: 'Operations Lead',
    rejectedAt: '1 week ago',
    resubmitted: true,
  },
  {
    id: 'REJ-407',
    driver: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    city: 'Manila City',
    docType: 'LTO Official Receipt (OR)',
    rejectionReason: 'Expired official receipt; proof of annual MV registration needed',
    rejectedBy: 'Admin User',
    rejectedAt: '1 week ago',
    resubmitted: true,
  },
  {
    id: 'REJ-408',
    driver: 'Felipe Cruz',
    driverPhone: '+63 916 445 8821',
    city: 'Pasay City',
    docType: 'Barangay Commercial Driver Clearance',
    rejectionReason: 'Barangay clearance jurisdiction differs from assigned operating zone',
    rejectedBy: 'Admin User',
    rejectedAt: '1 week ago',
    resubmitted: false,
  },
  {
    id: 'REJ-409',
    driver: 'Antonio Villanueva',
    driverPhone: '+63 939 556 1209',
    city: 'Mandaluyong City',
    docType: "LTO Driver's License Front Side",
    rejectionReason: 'Flash glare obscuring birthdate and driver license number',
    rejectedBy: 'Super Admin',
    rejectedAt: '10 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-410',
    driver: 'Cristopher Alcantara',
    driverPhone: '+63 921 778 2234',
    city: 'Marikina City',
    docType: 'Taxicle Annual Inspection Certificate',
    rejectionReason: 'Inspection report failed emissions and noise standard check',
    rejectedBy: 'Operations Lead',
    rejectedAt: '12 days ago',
    resubmitted: true,
  },
  {
    id: 'REJ-411',
    driver: 'Nestor Macaraeg',
    driverPhone: '+63 947 889 1120',
    city: 'Valenzuela City',
    docType: 'NBI National Criminal Clearance',
    rejectionReason: 'Clearance QR code not scannable; re-upload required',
    rejectedBy: 'Admin User',
    rejectedAt: '2 weeks ago',
    resubmitted: false,
  },
])

const currentPage = ref(1)
const itemsPerPage = 10

const paginatedRejectedDocs = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return rejectedDocs.value.slice(start, start + itemsPerPage)
})
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
        Rejected Driver Documents
      </h1>
      <p class="text-sm text-neutral-500 mt-1">
        Audit log of failed Philippine driver document submissions, regulatory rejection grounds, and resubmissions.
      </p>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Rejected Regulatory Documents</h2>
        <span class="text-xs text-neutral-400">Maintained for legal compliance audits</span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Log ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Document</th>
              <th class="py-3 px-4">Rejection Grounds</th>
              <th class="py-3 px-4">Auditor</th>
              <th class="py-3 px-4">Date</th>
              <th class="py-3 px-4 text-right">Status</th>
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
              </td>
              <td class="py-3 px-4 font-medium text-neutral-800">{{ item.docType }}</td>
              <td class="py-3 px-4 text-neutral-600 max-w-[240px]">{{ item.rejectionReason }}</td>
              <td class="py-3 px-4 text-neutral-500">{{ item.rejectedBy }}</td>
              <td class="py-3 px-4 text-neutral-500 font-mono text-[11px]">{{ item.rejectedAt }}</td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <span
                  v-if="item.resubmitted"
                  class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-blue-100 text-blue-800"
                >
                  Resubmitted
                </span>
                <span
                  v-else
                  class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-rose-100 text-rose-800"
                >
                  Pending Driver Action
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="rejectedDocs.length"
        :items-per-page="itemsPerPage"
      />
    </div>
  </div>
</template>
