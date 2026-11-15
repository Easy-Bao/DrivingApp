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
import { useRiders, type RiderRecord, type RiderStanding } from '@/features/users'

const { riders, suspendRider, reinstateRider } = useRiders()

const searchQuery = ref('')
const standingFilter = ref<'ALL' | RiderStanding>('ALL')
const toastMessage = ref<string | null>(null)
const toastTone = ref<ToastTone>('info')
const inspectedRider = ref<RiderRecord | null>(null)
const pendingStatusRider = ref<RiderRecord | null>(null)
const statusReason = ref('')

const filteredRiders = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return riders.value.filter((rider) => {
    if (standingFilter.value !== 'ALL' && rider.standing !== standingFilter.value) {
      return false
    }
    if (!query) return true
    return (
      rider.id.toLowerCase().includes(query) ||
      rider.name.toLowerCase().includes(query) ||
      rider.phone.toLowerCase().includes(query) ||
      rider.barangay.toLowerCase().includes(query)
    )
  })
})

const hasActiveFilters = computed(() =>
  Boolean(searchQuery.value.trim() || standingFilter.value !== 'ALL'),
)

const { currentPage, itemsPerPage, paginatedItems } = useDataTable(filteredRiders, {
  initialPageSize: 8,
  resetDeps: [searchQuery, standingFilter],
})

function resetFilters() {
  searchQuery.value = ''
  standingFilter.value = 'ALL'
}

function standingTone(standing: RiderStanding): BadgeTone {
  if (standing === 'VIP Rider' || standing === 'Good Standing') return 'success'
  if (standing === 'Flagged (Dispute)') return 'warning'
  return 'danger'
}

function openStandingDialog(rider: RiderRecord) {
  statusReason.value = ''
  pendingStatusRider.value = rider
}

function confirmStandingUpdate() {
  const target = pendingStatusRider.value
  if (!target) return

  const result =
    target.standing === 'Suspended'
      ? reinstateRider(target.id)
      : suspendRider(target.id, statusReason.value)

  if (!result.ok) {
    toastTone.value = 'error'
    toastMessage.value = result.error
    return
  }

  toastTone.value = target.standing === 'Suspended' ? 'warning' : 'success'
  toastMessage.value = result.message
  pendingStatusRider.value = null
  statusReason.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Riders"
      description="Manage passenger accounts, trip activity, and standings."
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
              placeholder="Search name, phone, area..."
              aria-label="Search riders"
            />
          </div>
          <BaseSelect
            v-model="standingFilter"
            aria-label="Filter riders by standing"
            :options="[
              { label: 'All', value: 'ALL' },
              { label: 'VIP Rider', value: 'VIP Rider' },
              { label: 'Good Standing', value: 'Good Standing' },
              { label: 'Flagged (Dispute)', value: 'Flagged (Dispute)' },
              { label: 'Suspended', value: 'Suspended' },
            ]"
          />
        </div>
        <span
          class="px-2.5 py-1.5 bg-neutral-50 border border-neutral-300 text-xs font-semibold text-neutral-800 tabular-nums self-start md:self-auto"
        >
          Riders: {{ filteredRiders.length }}
        </span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[820px] text-left text-xs">
          <thead class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100">
            <tr>
              <th class="py-3 px-4">ID</th>
              <th class="py-3 px-4">Name</th>
              <th class="py-3 px-4">Phone</th>
              <th class="py-3 px-4">Area</th>
              <th class="py-3 px-4">Trips</th>
              <th class="py-3 px-4">Spend</th>
              <th class="py-3 px-4">Rating</th>
              <th class="py-3 px-4">Standing</th>
              <th class="py-3 px-4 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100 text-neutral-700">
            <tr v-for="rider in paginatedItems" :key="rider.id" class="hover:bg-neutral-50/50">
              <td class="py-3 px-4 font-mono font-bold">{{ rider.id }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-900">{{ rider.name }}</td>
              <td class="py-3 px-4 font-mono">{{ rider.phone }}</td>
              <td class="py-3 px-4">{{ rider.barangay }}</td>
              <td class="py-3 px-4 font-mono tabular-nums">{{ rider.totalTrips }}</td>
              <td class="py-3 px-4 font-mono font-semibold text-neutral-900">
                {{ formatCentavos(rider.lifetimeSpendCentavos) }}
              </td>
              <td class="py-3 px-4 font-bold text-neutral-900 tabular-nums">
                ★ {{ rider.rating.toFixed(2) }}
              </td>
              <td class="py-3 px-4">
                <StatusBadge :label="rider.standing" :tone="standingTone(rider.standing)" />
              </td>
              <td class="py-3 px-4 text-right space-x-2 whitespace-nowrap">
                <button
                  type="button"
                  class="text-xs text-neutral-700 hover:text-neutral-900 font-semibold cursor-pointer"
                  @click="inspectedRider = rider"
                >
                  Inspect
                </button>
                <button
                  type="button"
                  class="text-xs text-neutral-700 hover:text-neutral-900 font-medium cursor-pointer"
                  @click="openStandingDialog(rider)"
                >
                  {{ rider.standing === 'Suspended' ? 'Reinstate' : 'Suspend' }}
                </button>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedItems.length === 0"
              :colspan="9"
              title="No matching riders"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredRiders.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="Boolean(inspectedRider)"
      :title="inspectedRider ? `Passenger Details · ${inspectedRider.id}` : ''"
      :subtitle="inspectedRider ? `${inspectedRider.name} · ${inspectedRider.barangay}` : undefined"
      size="md"
      close-label="Close"
      @update:open="!$event && (inspectedRider = null)"
    >
      <div v-if="inspectedRider" class="space-y-4 text-xs">
        <div class="grid grid-cols-2 gap-3">
          <div>
            <div class="text-[11px] text-neutral-500">Phone</div>
            <div class="font-mono font-semibold text-neutral-900">{{ inspectedRider.phone }}</div>
          </div>
          <div>
            <div class="text-[11px] text-neutral-500">Lifetime Spend</div>
            <div class="font-mono font-bold text-neutral-900">
              {{ formatCentavos(inspectedRider.lifetimeSpendCentavos) }}
            </div>
          </div>
        </div>
        <div class="p-3 bg-neutral-50 border border-neutral-200 space-y-1">
          <div class="text-[11px] font-semibold uppercase text-neutral-500">
            Trust &amp; Safety Notes
          </div>
          <p class="text-neutral-700 leading-relaxed">{{ inspectedRider.notes }}</p>
        </div>
      </div>

      <template #footer>
        <div class="flex justify-end">
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold cursor-pointer"
            @click="inspectedRider = null"
          >
            Done
          </button>
        </div>
      </template>
    </ModalDialog>

    <ConfirmDialog
      v-model:reason="statusReason"
      :open="Boolean(pendingStatusRider)"
      :title="
        pendingStatusRider?.standing === 'Suspended' ? 'Reinstate Passenger' : 'Suspend Passenger'
      "
      :description="
        pendingStatusRider
          ? pendingStatusRider.standing === 'Suspended'
            ? `Restore booking privileges for ${pendingStatusRider.name}.`
            : `Suspend ${pendingStatusRider.name} (${pendingStatusRider.id}) from booking new rides.`
          : ''
      "
      :tone="pendingStatusRider?.standing === 'Suspended' ? 'emerald' : 'rose'"
      :confirm-label="
        pendingStatusRider?.standing === 'Suspended' ? 'Reinstate Passenger' : 'Suspend Passenger'
      "
      :require-reason="pendingStatusRider?.standing !== 'Suspended'"
      reason-label="Trust &amp; Safety Justification"
      reason-placeholder="Enter dispute reference or suspension justification..."
      @update:open="!$event && (pendingStatusRider = null)"
      @confirm="confirmStandingUpdate"
    />
  </div>
</template>
