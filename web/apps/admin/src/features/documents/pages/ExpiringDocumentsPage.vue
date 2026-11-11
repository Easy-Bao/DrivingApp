<script setup lang="ts">
import { computed, ref } from 'vue'
import { Icon } from '@iconify/vue'
import TablePagination from '@/app/components/TablePagination.vue'

const expiringDocs = ref([
  {
    id: 'EXP-101',
    driver: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    city: 'Pasig City',
    docType: 'Taxicle MTOP Municipal Permit',
    expiryDate: '2026-11-15',
    daysLeft: 4,
    status: 'Action Required',
  },
  {
    id: 'EXP-102',
    driver: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    city: 'Manila City',
    docType: 'Taxicle Compulsory TPL Insurance',
    expiryDate: '2026-11-20',
    daysLeft: 9,
    status: 'Notice Sent',
  },
  {
    id: 'EXP-103',
    driver: 'Ramon Valderama',
    driverPhone: '+63 927 334 9912',
    city: 'Caloocan City',
    docType: "Philippine LTO Driver's License",
    expiryDate: '2026-11-28',
    daysLeft: 17,
    status: 'Notice Sent',
  },
  {
    id: 'EXP-104',
    driver: 'Eduardo Santos',
    driverPhone: '+63 919 332 4455',
    city: 'Taguig City',
    docType: 'LTO Roadworthiness & TRU Certificate',
    expiryDate: '2026-12-05',
    daysLeft: 24,
    status: 'Grace Period',
  },
  {
    id: 'EXP-105',
    driver: 'Maria Lourdes Ramos',
    driverPhone: '+63 920 882 1144',
    city: 'Cebu City',
    docType: 'Metro Cebu TODA Franchise Renewal',
    expiryDate: '2026-12-10',
    daysLeft: 29,
    status: 'Grace Period',
  },
  {
    id: 'EXP-106',
    driver: 'Jose Mari Bautista',
    driverPhone: '+63 918 665 4411',
    city: 'Davao City',
    docType: 'Davao City MTOP Tricycle Permit',
    expiryDate: '2026-12-15',
    daysLeft: 34,
    status: 'Notice Sent',
  },
  {
    id: 'EXP-107',
    driver: 'Felipe Cruz',
    driverPhone: '+63 916 445 8821',
    city: 'Pasay City',
    docType: 'Pasay TODA Association Clearance',
    expiryDate: '2026-12-22',
    daysLeft: 41,
    status: 'Grace Period',
  },
  {
    id: 'EXP-108',
    driver: 'Antonio Villanueva',
    driverPhone: '+63 939 556 1209',
    city: 'Mandaluyong City',
    docType: 'LTO Motor Vehicle Inspection Report',
    expiryDate: '2027-01-05',
    daysLeft: 55,
    status: 'Notice Sent',
  },
  {
    id: 'EXP-109',
    driver: 'Cristopher Alcantara',
    driverPhone: '+63 921 778 2234',
    city: 'Marikina City',
    docType: 'Marikina TRU Annual Inspection Certificate',
    expiryDate: '2027-01-14',
    daysLeft: 64,
    status: 'Grace Period',
  },
  {
    id: 'EXP-110',
    driver: 'Nestor Macaraeg',
    driverPhone: '+63 947 889 1120',
    city: 'Valenzuela City',
    docType: 'Barangay Commercial Driver Permit',
    expiryDate: '2027-01-20',
    daysLeft: 70,
    status: 'Grace Period',
  },
  {
    id: 'EXP-111',
    driver: 'Rodelio Manalo',
    driverPhone: '+63 915 221 8890',
    city: 'Las Pinas City',
    docType: 'LTO Taxicle Registration (OR/CR)',
    expiryDate: '2027-01-30',
    daysLeft: 80,
    status: 'Grace Period',
  },
  {
    id: 'EXP-112',
    driver: 'Gilberto Soriano',
    driverPhone: '+63 926 771 3344',
    city: 'Paranaque City',
    docType: 'TODA Commercial Operating Franchise',
    expiryDate: '2027-02-12',
    daysLeft: 93,
    status: 'Grace Period',
  },
])

const currentPage = ref(1)
const itemsPerPage = 10

const paginatedExpiringDocs = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return expiringDocs.value.slice(start, start + itemsPerPage)
})

const actionToast = ref<string | null>(null)

function sendUrgentReminder(doc: (typeof expiringDocs.value)[0]) {
  actionToast.value = `Urgent renewal SMS dispatched to ${doc.driver} (${doc.driverPhone}).`
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Expiring Driver Documents
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Monitor Philippine LTO driver licenses, MTOP municipal permits, and TODA franchise renewals.
        </p>
      </div>
      <div class="flex items-center space-x-3">
        <span
          class="px-3 py-1.5 bg-amber-50 border border-amber-200 text-xs font-semibold text-amber-800"
        >
          {{ expiringDocs.filter((d) => d.daysLeft <= 15).length }} Critical Expirations (&lt; 15 Days)
        </span>
      </div>
    </div>

    <div
      v-if="actionToast"
      class="p-4 bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Driver Document Expiry Tracking</h2>
        <span class="text-xs text-neutral-400">Automated SMS renewal alerts enabled</span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Doc ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Document Type</th>
              <th class="py-3 px-4">Expiration Date</th>
              <th class="py-3 px-4">Days Remaining</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="doc in paginatedExpiringDocs"
              :key="doc.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ doc.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ doc.driver }}</div>
                <div class="text-[11px] text-neutral-400 font-mono">{{ doc.driverPhone }}</div>
              </td>
              <td class="py-3 px-4 font-medium text-neutral-800">{{ doc.docType }}</td>
              <td class="py-3 px-4 font-mono">{{ doc.expiryDate }}</td>
              <td class="py-3 px-4">
                <span
                  class="font-mono font-bold"
                  :class="doc.daysLeft <= 7 ? 'text-rose-600' : 'text-amber-600'"
                >
                  {{ doc.daysLeft }} days
                </span>
              </td>
              <td class="py-3 px-4">
                <span
                  class="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                  :class="
                    doc.status === 'Action Required'
                      ? 'bg-rose-100 text-rose-800'
                      : doc.status === 'Notice Sent'
                        ? 'bg-amber-100 text-amber-800'
                        : 'bg-neutral-100 text-neutral-700'
                  "
                >
                  {{ doc.status }}
                </span>
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
                  @click="sendUrgentReminder(doc)"
                >
                  Send Renewal SMS
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="expiringDocs.length"
        :items-per-page="itemsPerPage"
      />
    </div>
  </div>
</template>
