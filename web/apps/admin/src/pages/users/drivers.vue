<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  BaseSelect,
  ConfirmDialog,
  EmptyTableRow,
  ModalDialog,
  PageHeader,
  SearchField,
  StatusBadge,
  TablePagination,
  ToastBanner,
  formatCentavos,
  useDataTable,
  type BadgeTone,
  type ToastTone,
} from '@/shared'
import { useDrivers, type DriverRecord, type DriverStatus } from '@/features/users'

const { drivers, getEffectiveDriverStatus, suspendDriver, reactivateDriver } = useDrivers()

const searchQuery = ref('')
const statusFilter = ref<'ALL' | DriverStatus>('ALL')
const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('info')
const inspectedDriver = ref<DriverRecord | null>(null)
const pendingStatusDriver = ref<DriverRecord | null>(null)
const statusReason = ref('')

const filteredDrivers = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return drivers.value.filter((driver) => {
    const liveStatus = getEffectiveDriverStatus(driver)
    if (statusFilter.value !== 'ALL' && liveStatus !== statusFilter.value) {
      return false
    }
    if (!q) return true
    return (
      driver.id.toLowerCase().includes(q) ||
      driver.name.toLowerCase().includes(q) ||
      driver.phone.toLowerCase().includes(q) ||
      driver.vehicle.toLowerCase().includes(q) ||
      driver.todaZone.toLowerCase().includes(q)
    )
  })
})

const hasActiveFilters = computed(() =>
  Boolean(searchQuery.value.trim() || statusFilter.value !== 'ALL'),
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredDrivers, {
  initialPageSize: 8,
  resetDeps: [searchQuery, statusFilter],
})

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'ALL'
}

function statusTone(status: DriverStatus): BadgeTone {
  if (status === 'Active') return 'success'
  if (status === 'Low Balance (Locked)') return 'warning'
  return 'danger'
}

function openStatusDialog(driver: DriverRecord) {
  statusReason.value = ''
  pendingStatusDriver.value = driver
}

function confirmStatusUpdate() {
  const target = pendingStatusDriver.value
  if (!target) return

  const result =
    target.status === 'Suspended'
      ? reactivateDriver(target.id)
      : suspendDriver(target.id, statusReason.value)

  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }

  toastTone.value = target.status === 'Suspended' ? 'warning' : 'success'
  toastMessage.value = result.message
  pendingStatusDriver.value = null
  statusReason.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Drivers"
      description="Manage active drivers, assigned vehicles, and account statuses."
    />

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="toastMessage = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col md:flex-row md:items-center md:justify-between gap-3"
      >
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
          <div class="w-full sm:w-64">
            <SearchField
              v-model="searchQuery"
              placeholder="Search driver, plate, TODA..."
              aria-label="Search drivers"
            />
          </div>
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter drivers by status"
            :options="[
              { label: 'All Statuses', value: 'ALL' },
              { label: 'Active', value: 'Active' },
              { label: 'Low Balance (Locked)', value: 'Low Balance (Locked)' },
              { label: 'Suspended', value: 'Suspended' },
            ]"
          />
        </div>

        <span
          class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold text-neutral-800 tabular-nums self-start md:self-auto"
        >
          Drivers: {{ filteredDrivers.length }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[880px] text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">ID</th>
              <th class="py-3 px-4">Driver</th>
              <th class="py-3 px-4">Vehicle &amp; Plate</th>
              <th class="py-3 px-4">TODA Corridor</th>
              <th class="py-3 px-4">Trips</th>
              <th class="py-3 px-4">Rating</th>
              <th class="py-3 px-4">Wallet</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr v-for="driver in paginatedItems" :key="driver.id" class="hover:bg-neutral-50/50">
              <td class="py-3 px-4 font-mono font-bold text-neutral-900">{{ driver.id }}</td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ driver.name }}</div>
                <div class="text-[11px] font-mono text-neutral-400">{{ driver.phone }}</div>
              </td>
              <td class="py-3 px-4 font-medium text-neutral-800">{{ driver.vehicle }}</td>
              <td class="py-3 px-4 text-neutral-600">{{ driver.todaZone }}</td>
              <td class="py-3 px-4 font-mono tabular-nums">{{ driver.trips }}</td>
              <td class="py-3 px-4 font-bold text-neutral-900 tabular-nums">
                ★ {{ driver.rating.toFixed(2) }}
              </td>
              <td class="py-3 px-4 font-mono font-semibold text-neutral-900 tabular-nums">
                {{ formatCentavos(driver.walletBalanceCentavos) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="getEffectiveDriverStatus(driver)"
                  :tone="statusTone(getEffectiveDriverStatus(driver))"
                />
              </td>
              <td class="py-3 px-4 text-right space-x-2 whitespace-nowrap">
                <button
                  type="button"
                  class="text-xs text-neutral-700 hover:text-neutral-900 font-semibold cursor-pointer"
                  @click="inspectedDriver = driver"
                >
                  Inspect
                </button>
                <button
                  type="button"
                  class="text-xs font-medium cursor-pointer"
                  :class="
                    driver.status === 'Suspended'
                      ? 'text-emerald-700 hover:text-emerald-900'
                      : 'text-rose-700 hover:text-rose-900'
                  "
                  @click="openStatusDialog(driver)"
                >
                  {{ driver.status === 'Suspended' ? 'Reactivate' : 'Suspend' }}
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="9"
              title="No matching drivers"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredDrivers.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="Boolean(inspectedDriver)"
      :title="inspectedDriver ? `Driver Profile · ${inspectedDriver.id}` : ''"
      :subtitle="inspectedDriver ? `${inspectedDriver.name} · ${inspectedDriver.city}` : undefined"
      size="md"
      close-label="Close"
      @update:open="!$event && (inspectedDriver = null)"
    >
      <div v-if="inspectedDriver" class="grid grid-cols-2 gap-3 text-xs">
        <div>
          <div class="text-[11px] text-neutral-500">Phone</div>
          <div class="font-mono font-semibold text-neutral-900">{{ inspectedDriver.phone }}</div>
        </div>
        <div>
          <div class="text-[11px] text-neutral-500">Wallet Balance</div>
          <div class="font-mono font-bold text-neutral-900">
            {{ formatCentavos(inspectedDriver.walletBalanceCentavos) }}
          </div>
        </div>
        <div class="col-span-2">
          <div class="text-[11px] text-neutral-500">Assigned Vehicle</div>
          <div class="font-semibold text-neutral-900">{{ inspectedDriver.vehicle }}</div>
        </div>
        <div class="col-span-2">
          <div class="text-[11px] text-neutral-500">TODA Corridor</div>
          <div class="text-neutral-800">{{ inspectedDriver.todaZone }}</div>
        </div>
        <div
          v-if="inspectedDriver.suspensionReason"
          class="col-span-2 p-2.5 bg-rose-50 border border-rose-200 text-rose-800"
        >
          <span class="font-semibold">Suspension Note:</span> {{ inspectedDriver.suspensionReason }}
        </div>
      </div>

      <template #footer>
        <div class="flex justify-end">
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold cursor-pointer"
            @click="inspectedDriver = null"
          >
            Done
          </button>
        </div>
      </template>
    </ModalDialog>

    <ConfirmDialog
      v-model:reason="statusReason"
      :open="Boolean(pendingStatusDriver)"
      :title="pendingStatusDriver?.status === 'Suspended' ? 'Reactivate Driver' : 'Suspend Driver'"
      :description="
        pendingStatusDriver
          ? pendingStatusDriver.status === 'Suspended'
            ? `Restore dispatch eligibility for ${pendingStatusDriver.name} (${pendingStatusDriver.id}).`
            : `Suspend ${pendingStatusDriver.name} (${pendingStatusDriver.id}) from receiving new dispatches.`
          : ''
      "
      :tone="pendingStatusDriver?.status === 'Suspended' ? 'emerald' : 'rose'"
      :confirm-label="
        pendingStatusDriver?.status === 'Suspended' ? 'Reactivate Driver' : 'Suspend Driver'
      "
      :require-reason="pendingStatusDriver?.status !== 'Suspended'"
      reason-label="Suspension Reason"
      reason-placeholder="Enter compliance or conduct justification..."
      @update:open="!$event && (pendingStatusDriver = null)"
      @confirm="confirmStatusUpdate"
    />
  </div>
</template>
