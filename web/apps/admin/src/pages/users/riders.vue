<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import ConfirmDialog from '@/shared/dialogs/ConfirmDialog.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import TablePagination from '@/shared/table/TablePagination.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
import { formatPhp } from '@/shared/utils/format'

type RiderStanding = 'Good Standing' | 'VIP Rider' | 'Flagged (Dispute)' | 'Suspended'

interface RiderRecord {
  id: string
  name: string
  phone: string
  barangay: string
  totalTrips: number
  lifetimeSpend: number
  rating: number
  standing: RiderStanding
  notes: string
}

const searchQuery = ref('')
const standingFilter = ref<'ALL' | RiderStanding>('ALL')
const currentPage = ref(1)
const itemsPerPage = 10
const toastMessage = ref<string | null>(null)
const toastTone = ref<'success' | 'warning' | 'info'>('success')

const riders = ref<RiderRecord[]>([
  {
    id: 'RDR-201',
    name: 'Althea Mae Villanueva',
    phone: '+63 935 812 4091',
    barangay: 'Brgy. San Pedro',
    totalTrips: 84,
    lifetimeSpend: 4680.0,
    rating: 4.98,
    standing: 'VIP Rider',
    notes: 'Frequent commuter on Agora Market - Capitol route.',
  },
  {
    id: 'RDR-202',
    name: 'Carlo Magno Ocampo',
    phone: '+63 917 650 3182',
    barangay: 'Brgy. Gatas',
    totalTrips: 32,
    lifetimeSpend: 1790.5,
    rating: 4.85,
    standing: 'Good Standing',
    notes: 'Verified passenger profile, zero no-show penalties.',
  },
  {
    id: 'RDR-203',
    name: 'Jessa Mae Lim',
    phone: '+63 926 301 7742',
    barangay: 'Brgy. Balangasan',
    totalTrips: 119,
    lifetimeSpend: 6840.0,
    rating: 5.0,
    standing: 'VIP Rider',
    notes: 'Consistent 5-star ratings and regular driver tipper.',
  },
  {
    id: 'RDR-204',
    name: 'Mark Anthony Reyes',
    phone: '+63 945 204 8810',
    barangay: 'Santiago District',
    totalTrips: 12,
    lifetimeSpend: 695.0,
    rating: 4.2,
    standing: 'Flagged (Dispute)',
    notes: 'Under review for one reported partial cash settlement dispute.',
  },
  {
    id: 'RDR-205',
    name: 'Kristine Joy Navarro',
    phone: '+63 998 411 6620',
    barangay: 'Brgy. Santa Lucia',
    totalTrips: 46,
    lifetimeSpend: 2540.0,
    rating: 4.91,
    standing: 'Good Standing',
    notes: 'Verified mobile number and emergency contact configured.',
  },
  {
    id: 'RDR-206',
    name: 'Jericho Dalisay',
    phone: '+63 915 702 3319',
    barangay: 'Brgy. Tuburan',
    totalTrips: 27,
    lifetimeSpend: 1485.0,
    rating: 4.78,
    standing: 'Good Standing',
    notes: 'Regular Integrated Bus Terminal feeder trips.',
  },
])

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

function resetFilters() {
  searchQuery.value = ''
  standingFilter.value = 'ALL'
}

watch([searchQuery, standingFilter], () => {
  currentPage.value = 1
})

const paginatedRiders = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredRiders.value.slice(start, start + itemsPerPage)
})

const standingTone = (standing: RiderStanding) => {
  if (standing === 'VIP Rider' || standing === 'Good Standing') return 'success'
  if (standing === 'Flagged (Dispute)') return 'warning'
  return 'danger'
}

const openStandingDialog = (rider: RiderRecord) => {
  statusReason.value = ''
  pendingStatusRider.value = rider
}

const confirmStandingUpdate = () => {
  const target = pendingStatusRider.value
  if (!target) return

  if (target.standing === 'Suspended') {
    target.standing = 'Good Standing'
    target.notes = 'Account reinstated after trust and safety verification.'
    toastTone.value = 'success'
    toastMessage.value = `${target.name} restored to Good Standing.`
  } else {
    if (!statusReason.value.trim()) return
    target.standing = 'Suspended'
    target.notes = `Suspended: ${statusReason.value.trim()}`
    toastTone.value = 'warning'
    toastMessage.value = `${target.name} suspended from booking new rides.`
  }

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
            <tr v-for="rider in paginatedRiders" :key="rider.id" class="hover:bg-neutral-50/50">
              <td class="py-3 px-4 font-mono font-bold">{{ rider.id }}</td>
              <td class="py-3 px-4 font-semibold text-neutral-900">{{ rider.name }}</td>
              <td class="py-3 px-4 font-mono">{{ rider.phone }}</td>
              <td class="py-3 px-4">{{ rider.barangay }}</td>
              <td class="py-3 px-4 font-mono tabular-nums">{{ rider.totalTrips }}</td>
              <td class="py-3 px-4 font-mono font-semibold text-neutral-900">
                {{ formatPhp(rider.lifetimeSpend) }}
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
              v-if="paginatedRiders.length === 0"
              :colspan="9"
              title="No riders match your filters"
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
      :title="inspectedRider?.name ?? ''"
      :subtitle="inspectedRider?.id"
      size="md"
      close-label="Close modal"
      @close="inspectedRider = null"
    >
      <div v-if="inspectedRider" class="space-y-2.5 text-xs">
        <div class="flex justify-between gap-2">
          <span class="text-neutral-500">Phone</span>
          <span class="font-mono font-semibold text-neutral-900">{{ inspectedRider.phone }}</span>
        </div>
        <div class="flex justify-between gap-2">
          <span class="text-neutral-500">Area</span>
          <span class="font-medium text-neutral-900">{{ inspectedRider.barangay }}</span>
        </div>
        <div class="flex justify-between gap-2">
          <span class="text-neutral-500">Trips</span>
          <span class="font-mono font-semibold text-neutral-900">{{
            inspectedRider.totalTrips
          }}</span>
        </div>
        <div class="flex justify-between gap-2">
          <span class="text-neutral-500">Spend</span>
          <span class="font-mono font-semibold text-neutral-900">
            {{ formatPhp(inspectedRider.lifetimeSpend) }}
          </span>
        </div>
        <div class="pt-2 border-t border-neutral-100 text-neutral-600 leading-relaxed">
          <span class="font-semibold text-neutral-800 block mb-1">Trust &amp; Safety Notes</span>
          {{ inspectedRider.notes }}
        </div>
      </div>

      <template #footer>
        <RouterLink
          to="/payments/settlements"
          class="px-3.5 py-2 bg-white border border-neutral-200 hover:bg-neutral-100 text-neutral-800 text-xs font-semibold"
          @click="inspectedRider = null"
        >
          Settlements
        </RouterLink>
        <button
          type="button"
          class="px-4 py-2 bg-neutral-900 text-white text-xs font-semibold hover:bg-neutral-800 cursor-pointer"
          @click="inspectedRider = null"
        >
          Close
        </button>
      </template>
    </ModalDialog>

    <ConfirmDialog
      :open="Boolean(pendingStatusRider)"
      v-model:reason="statusReason"
      :title="
        pendingStatusRider?.standing === 'Suspended' ? 'Reinstate Passenger' : 'Suspend Passenger'
      "
      :description="
        pendingStatusRider?.standing === 'Suspended'
          ? `Restore ${pendingStatusRider?.name} to book rides again.`
          : `Prevent ${pendingStatusRider?.name} from requesting trips during investigation.`
      "
      :confirm-label="
        pendingStatusRider?.standing === 'Suspended' ? 'Reinstate Passenger' : 'Suspend Passenger'
      "
      tone="neutral"
      :require-reason="pendingStatusRider?.standing !== 'Suspended'"
      reason-label="Reason"
      reason-placeholder="Enter dispute or safety reason..."
      @cancel="pendingStatusRider = null"
      @confirm="confirmStandingUpdate"
    />
  </div>
</template>
