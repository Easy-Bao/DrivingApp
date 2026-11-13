<script setup lang="ts">
import { computed, ref } from 'vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import EmptyTableRow from '@/shared/components/EmptyTableRow.vue'
import ModalDialog from '@/shared/components/ModalDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import SearchField from '@/shared/components/SearchField.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

interface LostFoundRecord {
  id: string
  itemDescription: string
  reportedBy: string
  contactPhone: string
  driver: string
  driverPhone: string
  tripId: string
  corridor: string
  status: 'Searching Driver' | 'Driver Confirmed Found' | 'Returned to Owner'
  handoffNote?: string
}

const lostItems = ref<LostFoundRecord[]>([
  {
    id: 'LF-7016-801',
    itemDescription: 'Blue insulated tumblers and school ID sling pouch',
    reportedBy: 'Althea Mae Villanueva',
    contactPhone: '+63 917 842 9103',
    driver: 'Rodelio Cruz (ZDS-4821)',
    driverPhone: '+63 917 482 1903',
    tripId: 'TRP-7016-8921',
    corridor: 'Pagadian Public Market (Agora) -> Brgy. San Jose',
    status: 'Driver Confirmed Found',
  },
  {
    id: 'LF-7016-802',
    itemDescription: 'Black foldable umbrella and BDO passbook folder',
    reportedBy: 'Rafael Dominguiano',
    contactPhone: '+63 928 519 4402',
    driver: 'Danilo Mendoza (ZDS-3019)',
    driverPhone: '+63 918 654 2219',
    tripId: 'TRP-7016-8910',
    corridor: 'Gaisano Capital Pagadian -> Brgy. Tiguma',
    status: 'Searching Driver',
  },
  {
    id: 'LF-7016-800',
    itemDescription: 'Android smartphone left in rear passenger seat',
    reportedBy: 'Kevin Lloyd Tan',
    contactPhone: '+63 927 310 6621',
    driver: 'Reynaldo Bautista (ZDS-1944)',
    driverPhone: '+63 917 773 8810',
    tripId: 'TRP-7016-8840',
    corridor: 'Integrated Bus Terminal -> Dao Capitol',
    status: 'Returned to Owner',
    handoffNote: 'Claimed at Pagadian TODA dispatch desk near Santiago Terminal with valid ID.',
  },
])

const statusFilter = ref<'All' | LostFoundRecord['status']>('All')
const searchQuery = ref('')
const toastMessage = ref<string | null>(null)

const returningItem = ref<LostFoundRecord | null>(null)
const returnDialogOpen = ref(false)
const returnNote = ref('')

const showLogModal = ref(false)
const newDescription = ref('')
const newReporter = ref('')
const newReporterPhone = ref('+63 9')
const newTripId = ref('TRP-7016-')
const newDriver = ref('Rodelio Cruz (ZDS-4821)')
const logError = ref<string | null>(null)

const filteredItems = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return lostItems.value.filter((item) => {
    const matchesStatus = statusFilter.value === 'All' || item.status === statusFilter.value
    const matchesSearch =
      !query ||
      item.id.toLowerCase().includes(query) ||
      item.itemDescription.toLowerCase().includes(query) ||
      item.reportedBy.toLowerCase().includes(query) ||
      item.driver.toLowerCase().includes(query) ||
      item.tripId.toLowerCase().includes(query)
    return matchesStatus && matchesSearch
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || statusFilter.value !== 'All',
)

const resetFilters = () => {
  searchQuery.value = ''
  statusFilter.value = 'All'
}

const openReturnDialog = (item: LostFoundRecord) => {
  returningItem.value = item
  returnNote.value = ''
  returnDialogOpen.value = true
}

const confirmReturn = () => {
  if (!returningItem.value || !returnNote.value.trim()) return
  returningItem.value.status = 'Returned to Owner'
  returningItem.value.handoffNote = returnNote.value.trim()
  toastMessage.value = `${returningItem.value.id} closed as Returned to Owner.`
  returnDialogOpen.value = false
  returningItem.value = null
  returnNote.value = ''
}

const openLogModal = () => {
  newDescription.value = ''
  newReporter.value = ''
  newReporterPhone.value = '+63 917 '
  newTripId.value = 'TRP-7016-'
  logError.value = null
  showLogModal.value = true
}

const createLostItem = () => {
  if (!newDescription.value.trim() || !newReporter.value.trim() || !newReporterPhone.value.trim()) {
    logError.value = 'Provide item description, claimant name, and +63 phone number.'
    return
  }
  lostItems.value.unshift({
    id: `LF-7016-${803 + lostItems.value.length}`,
    itemDescription: newDescription.value.trim(),
    reportedBy: newReporter.value.trim(),
    contactPhone: newReporterPhone.value.trim(),
    driver: newDriver.value,
    driverPhone: '+63 917 482 1903',
    tripId: newTripId.value.trim(),
    corridor: 'Pagadian City Service Zone',
    status: 'Searching Driver',
  })
  toastMessage.value = `Logged lost item report for ${newReporter.value.trim()}.`
  showLogModal.value = false
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner
      v-if="toastMessage"
      :message="toastMessage"
      tone="success"
      @dismiss="toastMessage = null"
    />

    <PageHeader
      title="Lost & Found Recovery Desk"
      description="Coordinate property recovery between Pagadian City passengers and taxicle operators."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <SearchField
          v-model="searchQuery"
          placeholder="Search item description, passenger, driver, or trip ID..."
          aria-label="Search lost and found reports"
          class="md:w-80"
        />

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter by recovery status"
            :options="[
              { label: 'All Recovery States', value: 'All' },
              { label: 'Searching Driver', value: 'Searching Driver' },
              { label: 'Driver Confirmed Found', value: 'Driver Confirmed Found' },
              { label: 'Returned to Owner', value: 'Returned to Owner' },
            ]"
          />
          <button
            type="button"
            class="px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold cursor-pointer shrink-0"
            @click="openLogModal"
          >
            + Log Report
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[840px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Case ID</th>
              <th class="py-3 px-4">Item Description &amp; Route</th>
              <th class="py-3 px-4">Claimant</th>
              <th class="py-3 px-4">Assigned Driver</th>
              <th class="py-3 px-4">Trip ID</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="item in filteredItems"
              :key="item.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ item.id }}</td>
              <td class="py-3 px-4 max-w-xs">
                <div class="font-medium text-neutral-900">{{ item.itemDescription }}</div>
                <div class="text-[11px] text-neutral-400 mt-0.5">{{ item.corridor }}</div>
                <div v-if="item.handoffNote" class="text-[11px] text-neutral-600 mt-1">
                  Handoff: {{ item.handoffNote }}
                </div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ item.reportedBy }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ item.contactPhone }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-900">{{ item.driver }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ item.driverPhone }}</div>
              </td>
              <td class="py-3 px-4 font-mono text-neutral-700 font-medium">{{ item.tripId }}</td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="item.status"
                  :tone="
                    item.status === 'Returned to Owner'
                      ? 'success'
                      : item.status === 'Driver Confirmed Found'
                        ? 'info'
                        : 'warning'
                  "
                />
              </td>
              <td class="py-3 px-4 text-right">
                <button
                  v-if="item.status !== 'Returned to Owner'"
                  type="button"
                  class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold transition-colors"
                  @click="openReturnDialog(item)"
                >
                  Confirm Return
                </button>
                <span v-else class="text-neutral-400 text-xs">Closed</span>
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredItems.length === 0"
              :colspan="7"
              title="No matching recovery cases"
              description="No lost and found reports match the current filters."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>
    </div>

    <ConfirmDialog
      v-model:open="returnDialogOpen"
      v-model:reason="returnNote"
      :title="`Confirm Item Return · ${returningItem?.id ?? ''}`"
      :description="`Record owner ID verification and handoff proof for '${returningItem?.itemDescription ?? ''}'.`"
      confirm-label="Mark Returned to Owner"
      tone="emerald"
      :require-reason="true"
      reason-label="Handoff Location & Claimant Verification Note"
      reason-placeholder="e.g., Claimed by owner at Agora TODA terminal booth; ID sighted..."
      @confirm="confirmReturn"
      @cancel="returnDialogOpen = false"
    />

    <ModalDialog v-model:open="showLogModal" title="Log Lost & Found Report" size="md">
      <div class="space-y-3 text-xs">
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Item Description</label>
          <input
            v-model="newDescription"
            type="text"
            placeholder="e.g., Leather wallet with student ID"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Passenger Name</label>
          <input
            v-model="newReporter"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Contact (+63)</label>
            <input
              v-model="newReporterPhone"
              type="text"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Trip Reference</label>
            <input
              v-model="newTripId"
              type="text"
              class="w-full px-3 py-1.5 border border-neutral-300 rounded-none font-mono bg-white text-neutral-900"
            />
          </div>
        </div>
        <div>
          <label class="block font-medium text-neutral-700 mb-1">Assigned Taxicle Driver</label>
          <BaseSelect
            v-model="newDriver"
            :full-width="true"
            aria-label="Select driver"
            :options="[
              'Rodelio Cruz (ZDS-4821)',
              'Danilo Mendoza (ZDS-3019)',
              'Reynaldo Bautista (ZDS-1944)',
            ]"
          />
        </div>
        <p v-if="logError" class="text-xs font-medium text-rose-700">{{ logError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
            @click="showLogModal = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
            @click="createLostItem"
          >
            Submit Report
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
