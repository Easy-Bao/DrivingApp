<script setup lang="ts">
import { computed, ref } from 'vue'
import { useLostAndFound, type LostFoundRecord, type LostFoundStatus } from '@/features/support'
import {
  BaseSelect,
  ConfirmDialog,
  EmptyTableRow,
  ModalDialog,
  PageHeader,
  SearchField,
  StatusBadge,
  ToastBanner,
  useToast,
} from '@/shared'

const { lostItems, driverRosterOptions, createLostItem, confirmReturn } = useLostAndFound()

const statusFilter = ref<'All' | LostFoundStatus>('All')
const searchQuery = ref('')
const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('success')

const returningItem = ref<LostFoundRecord | null>(null)
const returnDialogOpen = ref(false)
const returnNote = ref('')

const showLogModal = ref(false)
const newDescription = ref('')
const newReporter = ref('')
const newReporterPhone = ref('+63 917 ')
const newTripId = ref('TRP-7016-')
const newDriver = ref(driverRosterOptions[0] ?? 'Rodelio Cruz (ZDS-4821)')
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

const submitReturn = () => {
  const target = returningItem.value
  if (!target) return
  const result = confirmReturn(target.id, returnNote.value)
  if (!result.ok) {
    showToast(result.error, 'error')
    return
  }
  showToast(`${target.id} closed as Returned to Owner.`)
  returnDialogOpen.value = false
  returningItem.value = null
  returnNote.value = ''
}

const openLogModal = () => {
  newDescription.value = ''
  newReporter.value = ''
  newReporterPhone.value = '+63 917 '
  newTripId.value = 'TRP-7016-'
  newDriver.value = driverRosterOptions[0] ?? 'Rodelio Cruz (ZDS-4821)'
  logError.value = null
  showLogModal.value = true
}

const submitLostItem = () => {
  const reporter = newReporter.value.trim()
  const result = createLostItem({
    itemDescription: newDescription.value,
    reportedBy: newReporter.value,
    contactPhone: newReporterPhone.value,
    tripId: newTripId.value,
    driver: newDriver.value,
  })
  if (!result.ok) {
    logError.value = result.error
    return
  }
  showToast(`Logged lost item report for ${reporter}.`)
  showLogModal.value = false
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Lost Items"
      description="Coordinate property recovery between passengers and drivers."
    />

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

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
            class="px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer shrink-0"
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
                <div class="text-[11px] text-neutral-500 mt-0.5">{{ item.corridor }}</div>
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
                  class="px-3 py-1 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold transition-colors cursor-pointer"
                  @click="openReturnDialog(item)"
                >
                  Confirm Return
                </button>
                <span v-else class="text-neutral-500 text-xs">Closed</span>
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
      @confirm="submitReturn"
      @cancel="returnDialogOpen = false"
    />

    <ModalDialog v-model:open="showLogModal" title="Log Lost & Found Report" size="md">
      <div class="space-y-3 text-xs">
        <div>
          <label for="lost-item-description" class="block font-medium text-neutral-700 mb-1">
            Item Description
          </label>
          <input
            id="lost-item-description"
            v-model="newDescription"
            type="text"
            placeholder="e.g., Leather wallet with student ID"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>
        <div>
          <label for="lost-item-passenger" class="block font-medium text-neutral-700 mb-1">
            Passenger Name
          </label>
          <input
            id="lost-item-passenger"
            v-model="newReporter"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 bg-white text-neutral-900"
          />
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label for="lost-item-phone" class="block font-medium text-neutral-700 mb-1">
              Contact (+63)
            </label>
            <input
              id="lost-item-phone"
              v-model="newReporterPhone"
              type="text"
              class="w-full px-3 py-1.5 border border-neutral-300 font-mono bg-white text-neutral-900"
            />
          </div>
          <div>
            <label for="lost-item-trip" class="block font-medium text-neutral-700 mb-1">
              Trip Reference
            </label>
            <input
              id="lost-item-trip"
              v-model="newTripId"
              type="text"
              class="w-full px-3 py-1.5 border border-neutral-300 font-mono bg-white text-neutral-900"
            />
          </div>
        </div>
        <div>
          <div class="font-medium text-neutral-700 mb-1">Assigned Driver</div>
          <BaseSelect
            v-model="newDriver"
            :full-width="true"
            aria-label="Select driver"
            :options="[...driverRosterOptions]"
          />
        </div>
        <p v-if="logError" role="alert" class="text-xs font-medium text-rose-700">{{ logError }}</p>
      </div>

      <template #footer>
        <button
          type="button"
          class="px-3 py-1.5 border border-neutral-300 text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
          @click="showLogModal = false"
        >
          Cancel
        </button>
        <button
          type="button"
          class="px-3 py-1.5 bg-neutral-900 text-white text-xs font-medium hover:bg-neutral-800 cursor-pointer"
          @click="submitLostItem"
        >
          Submit Report
        </button>
      </template>
    </ModalDialog>
  </div>
</template>
