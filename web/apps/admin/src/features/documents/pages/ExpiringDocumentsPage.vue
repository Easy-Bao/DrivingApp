<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import TablePagination from '@/app/components/TablePagination.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

type ExpiryStatus = 'Action Required' | 'Notice Sent' | 'Grace Period'

interface ExpiringDocument {
  id: string
  driver: string
  driverPhone: string
  city: string
  docType: string
  expiryDate: string
  daysLeft: number
  status: ExpiryStatus
}

const expiringDocs = ref<ExpiringDocument[]>([
  {
    id: 'EXP-101',
    driver: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    city: 'Brgy. Tuburan',
    docType: 'MTOP Municipal Permit',
    expiryDate: '2026-11-15',
    daysLeft: 4,
    status: 'Action Required',
  },
  {
    id: 'EXP-102',
    driver: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    city: 'Brgy. Balangasan',
    docType: 'Compulsory TPL Insurance',
    expiryDate: '2026-11-20',
    daysLeft: 9,
    status: 'Action Required',
  },
  {
    id: 'EXP-103',
    driver: 'Javier Santos',
    driverPhone: '+63 917 987 6543',
    city: 'Brgy. San Pedro',
    docType: "LTO Professional Driver's License",
    expiryDate: '2026-11-28',
    daysLeft: 17,
    status: 'Notice Sent',
  },
  {
    id: 'EXP-104',
    driver: 'Eduardo Santos',
    driverPhone: '+63 919 332 4455',
    city: 'Brgy. Kawit',
    docType: 'LTO MVIC Certificate',
    expiryDate: '2026-12-05',
    daysLeft: 24,
    status: 'Grace Period',
  },
  {
    id: 'EXP-105',
    driver: 'Maria Lourdes Ramos',
    driverPhone: '+63 920 882 1144',
    city: 'Brgy. Santa Lucia',
    docType: 'TODA Franchise Renewal',
    expiryDate: '2026-12-10',
    daysLeft: 29,
    status: 'Grace Period',
  },
  {
    id: 'EXP-106',
    driver: 'Jose Mari Bautista',
    driverPhone: '+63 918 665 4411',
    city: 'Brgy. Gatas',
    docType: 'MTOP Tricycle Permit',
    expiryDate: '2026-12-15',
    daysLeft: 34,
    status: 'Notice Sent',
  },
  {
    id: 'EXP-107',
    driver: 'Felipe Cruz',
    driverPhone: '+63 916 445 8821',
    city: 'Brgy. Tiguma',
    docType: 'TODA Clearance',
    expiryDate: '2026-12-22',
    daysLeft: 41,
    status: 'Grace Period',
  },
  {
    id: 'EXP-108',
    driver: 'Antonio Villanueva',
    driverPhone: '+63 939 556 1209',
    city: 'Brgy. Dao',
    docType: 'LTO Inspection Report',
    expiryDate: '2027-01-05',
    daysLeft: 55,
    status: 'Notice Sent',
  },
  {
    id: 'EXP-109',
    driver: 'Cristopher Alcantara',
    driverPhone: '+63 921 778 2234',
    city: 'Brgy. Santiago',
    docType: 'TRU Inspection Certificate',
    expiryDate: '2027-01-14',
    daysLeft: 64,
    status: 'Grace Period',
  },
  {
    id: 'EXP-110',
    driver: 'Nestor Macaraeg',
    driverPhone: '+63 947 889 1120',
    city: 'Brgy. Danlugan',
    docType: 'Barangay Driver Permit',
    expiryDate: '2027-01-20',
    daysLeft: 70,
    status: 'Grace Period',
  },
  {
    id: 'EXP-111',
    driver: 'Ernesto Manalo',
    driverPhone: '+63 915 221 8890',
    city: 'Brgy. Bulatok',
    docType: 'LTO OR/CR Registration',
    expiryDate: '2027-01-30',
    daysLeft: 80,
    status: 'Grace Period',
  },
])

const searchQuery = ref('')
const statusFilter = ref<'ALL' | 'CRITICAL' | ExpiryStatus>('ALL')
const currentPage = ref(1)
const itemsPerPage = 10
const actionToast = ref<string | null>(null)

const filteredDocs = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return expiringDocs.value.filter((doc) => {
    if (statusFilter.value === 'CRITICAL' && doc.daysLeft > 15) return false
    if (
      statusFilter.value !== 'ALL' &&
      statusFilter.value !== 'CRITICAL' &&
      doc.status !== statusFilter.value
    ) {
      return false
    }
    if (!q) return true
    return (
      doc.id.toLowerCase().includes(q) ||
      doc.driver.toLowerCase().includes(q) ||
      doc.docType.toLowerCase().includes(q) ||
      doc.city.toLowerCase().includes(q)
    )
  })
})

watch([searchQuery, statusFilter], () => {
  currentPage.value = 1
})

const paginatedExpiringDocs = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredDocs.value.slice(start, start + itemsPerPage)
})

const criticalCount = computed(() => expiringDocs.value.filter((d) => d.daysLeft <= 15).length)

function sendUrgentReminder(doc: ExpiringDocument) {
  doc.status = 'Notice Sent'
  actionToast.value = `Renewal SMS sent to ${doc.driver}.`
}

function broadcastCriticalReminders() {
  const criticalDocs = expiringDocs.value.filter(
    (doc) => doc.daysLeft <= 15 && doc.status !== 'Notice Sent',
  )
  for (const doc of criticalDocs) {
    doc.status = 'Notice Sent'
  }
  actionToast.value =
    criticalDocs.length > 0
      ? `Renewal SMS sent to ${criticalDocs.length} drivers.`
      : 'All critical drivers already notified.'
}

const statusTone = (status: ExpiryStatus) => {
  if (status === 'Action Required') return 'danger'
  if (status === 'Notice Sent') return 'warning'
  return 'neutral'
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold tabular-nums text-neutral-900 tracking-tight">
          Expiring Docs
        </h1>
        <p class="text-sm text-neutral-500 mt-1">Renewal tracking and SMS reminders.</p>
      </div>
    </div>

    <ToastBanner :message="actionToast" tone="success" @dismiss="actionToast = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col lg:flex-row lg:items-center justify-between gap-3"
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
              placeholder="Search driver, doc..."
              class="w-full pl-8 pr-3 py-1.5 bg-white border border-neutral-200 text-xs text-neutral-900 focus:outline-none focus:border-neutral-900"
            />
          </div>
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter expiring documents"
            :options="[
              { label: 'All', value: 'ALL' },
              { label: 'Critical', value: 'CRITICAL' },
              { label: 'Action Required', value: 'Action Required' },
              { label: 'Notice Sent', value: 'Notice Sent' },
              { label: 'Grace Period', value: 'Grace Period' },
            ]"
          />
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <span
            class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold tabular-nums text-neutral-800"
          >
            Critical: {{ criticalCount }}
          </span>
          <button
            type="button"
            class="px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
            @click="broadcastCriticalReminders"
          >
            Notify Critical
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[820px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Document</th>
              <th class="py-3 px-4">Expires</th>
              <th class="py-3 px-4">Remaining</th>
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
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-800">{{ doc.docType }}</div>
                <div class="text-[11px] text-neutral-400">{{ doc.city }}</div>
              </td>
              <td class="py-3 px-4 font-mono">{{ doc.expiryDate }}</td>
              <td class="py-3 px-4">
                <span
                  class="font-mono font-bold"
                  :class="doc.daysLeft <= 15 ? 'text-rose-700' : 'text-neutral-700'"
                >
                  {{ doc.daysLeft }}d
                </span>
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="doc.status" :tone="statusTone(doc.status)" />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <button
                  type="button"
                  class="px-2.5 py-1 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
                  @click="sendUrgentReminder(doc)"
                >
                  Send SMS
                </button>
              </td>
            </tr>
            <tr v-if="paginatedExpiringDocs.length === 0">
              <td colspan="7" class="py-8 text-center text-xs text-neutral-500">
                No expiring documents match the current filter.
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
  </div>
</template>
