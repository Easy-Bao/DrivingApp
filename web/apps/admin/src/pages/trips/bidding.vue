<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import ConfirmDialog from '@/shared/dialogs/ConfirmDialog.vue'
import EmptyTableRow from '@/shared/table/EmptyTableRow.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge, { type BadgeTone } from '@/shared/feedback/StatusBadge.vue'
import TablePagination from '@/shared/table/TablePagination.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'
import { formatPhp } from '@/shared/utils/format'

type BidSessionStatus = 'open' | 'accepted' | 'cancelled' | 'expired' | 'declined'

interface BidOffer {
  id: string
  driverName: string
  plate: string
  bodyUnit: string
  driverRating: number
  etaMinutes: number
  status: 'pending' | 'accepted' | 'declined' | 'expired'
}

interface BidSession {
  id: string
  bookingRef: string
  passenger: string
  passengerPhone: string
  pickup: string
  dropoff: string
  systemEstimate: number
  passengerOffer: number
  tipAmount: number
  requestMode: 'Broadcast' | 'Targeted Driver'
  status: BidSessionStatus
  expiresIn: string
  createdAt: string
  note: string
  offers: BidOffer[]
}

const sessions = ref<BidSession[]>([
  {
    id: 'BID-3041',
    bookingRef: '70160941200841',
    passenger: 'Clarisse Abella',
    passengerPhone: '+63 917 440 2184',
    pickup: 'Agora Public Market Gate 2, Brgy. Santiago',
    dropoff: 'Zamboanga del Sur Medical Center, Brgy. Dao',
    systemEstimate: 45,
    passengerOffer: 60,
    tipAmount: 20,
    requestMode: 'Broadcast',
    status: 'open',
    expiresIn: '01:18 left',
    createdAt: '2 mins ago',
    note: 'Carrying groceries, near loading bay beside pharmacy.',
    offers: [
      {
        id: 'OFR-901',
        driverName: 'Danilo Mendoza',
        plate: '3891-ZK',
        bodyUnit: 'Bao-Bao #042',
        driverRating: 4.92,
        etaMinutes: 3,
        status: 'pending',
      },
      {
        id: 'OFR-902',
        driverName: 'Edgar Tolentino',
        plate: '5190-QP',
        bodyUnit: 'Bao-Bao #109',
        driverRating: 4.78,
        etaMinutes: 5,
        status: 'pending',
      },
    ],
  },
  {
    id: 'BID-3040',
    bookingRef: '70160941200839',
    passenger: 'Marco Villanueva',
    passengerPhone: '+63 928 715 3390',
    pickup: 'Pagadian City Integrated Bus Terminal, Bulatok',
    dropoff: 'Gaisano Capital Pagadian, Brgy. San Pedro',
    systemEstimate: 50,
    passengerOffer: 65,
    tipAmount: 10,
    requestMode: 'Broadcast',
    status: 'accepted',
    expiresIn: 'Matched',
    createdAt: '9 mins ago',
    note: 'Solo ride with small backpack.',
    offers: [
      {
        id: 'OFR-898',
        driverName: 'Brandon Lee',
        plate: '1284-ND',
        bodyUnit: 'Bao-Bao #084',
        driverRating: 4.95,
        etaMinutes: 2,
        status: 'accepted',
      },
    ],
  },
  {
    id: 'BID-3039',
    bookingRef: '70160941200832',
    passenger: 'Grace Cabading',
    passengerPhone: '+63 915 209 7741',
    pickup: 'Plaza Luzon Oval, Brgy. Gatas',
    dropoff: 'Brgy. Tuburan Barangay Hall',
    systemEstimate: 30,
    passengerOffer: 30,
    tipAmount: 0,
    requestMode: 'Targeted Driver',
    status: 'declined',
    expiresIn: 'Closed',
    createdAt: '18 mins ago',
    note: '',
    offers: [
      {
        id: 'OFR-895',
        driverName: 'Rodelio Cruz',
        plate: '9102-AB',
        bodyUnit: 'Bao-Bao #019',
        driverRating: 4.61,
        etaMinutes: 4,
        status: 'declined',
      },
    ],
  },
  {
    id: 'BID-3038',
    bookingRef: '70160941200825',
    passenger: 'Junel Pineda',
    passengerPhone: '+63 998 331 0912',
    pickup: 'Western Mindanao State U External, Tiguma',
    dropoff: 'Pagadian Commercial Wharf, Kawit',
    systemEstimate: 55,
    passengerOffer: 55,
    tipAmount: 0,
    requestMode: 'Broadcast',
    status: 'expired',
    expiresIn: 'Timed out',
    createdAt: '31 mins ago',
    note: 'Waiting by main highway shed.',
    offers: [],
  },
  {
    id: 'BID-3037',
    bookingRef: '70160941200818',
    passenger: 'Liza Bantilan',
    passengerPhone: '+63 917 889 4412',
    pickup: 'Robinsons Supermarket Entrance, San Francisco',
    dropoff: 'Brgy. Balangasan Rotonda',
    systemEstimate: 35,
    passengerOffer: 45,
    tipAmount: 10,
    requestMode: 'Broadcast',
    status: 'cancelled',
    expiresIn: 'Rider cancelled',
    createdAt: '44 mins ago',
    note: 'Cancelled after getting local pickup.',
    offers: [],
  },
])

const searchQuery = ref('')
const statusFilter = ref<'all' | BidSessionStatus>('all')
const currentPage = ref(1)
const itemsPerPage = 5
const inspectedSession = ref<BidSession | null>(null)
const pendingExpireSession = ref<BidSession | null>(null)
const showExpireDialog = ref(false)
const expireReason = ref('')
const toastMessage = ref<string | null>(null)
let toastTimer: number | undefined

const filteredSessions = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return sessions.value.filter((session) => {
    const matchesStatus = statusFilter.value === 'all' || session.status === statusFilter.value
    const matchesQuery =
      !query ||
      session.id.toLowerCase().includes(query) ||
      session.bookingRef.toLowerCase().includes(query) ||
      session.passenger.toLowerCase().includes(query) ||
      session.pickup.toLowerCase().includes(query) ||
      session.dropoff.toLowerCase().includes(query)
    return matchesStatus && matchesQuery
  })
})

const paginatedSessions = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredSessions.value.slice(start, start + itemsPerPage)
})

const openSessionCount = computed(
  () => sessions.value.filter((session) => session.status === 'open').length,
)

const acceptanceRate = computed(() => {
  const accepted = sessions.value.filter((session) => session.status === 'accepted').length
  if (sessions.value.length === 0) return '0%'
  return `${Math.round((accepted / sessions.value.length) * 100)}%`
})

watch([searchQuery, statusFilter], () => {
  currentPage.value = 1
})

onBeforeUnmount(() => {
  if (toastTimer) window.clearTimeout(toastTimer)
})

function showToast(msg: string) {
  toastMessage.value = msg
  if (toastTimer) window.clearTimeout(toastTimer)
  toastTimer = window.setTimeout(() => {
    toastMessage.value = null
  }, 4000)
}

function statusTone(status: BidSessionStatus): BadgeTone {
  switch (status) {
    case 'open':
      return 'warning'
    case 'accepted':
      return 'success'
    case 'declined':
    case 'cancelled':
      return 'danger'
    default:
      return 'neutral'
  }
}

const hasActiveFilters = computed(() => searchQuery.value !== '' || statusFilter.value !== 'all')

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'all'
  currentPage.value = 1
}

function promptExpireSession(session: BidSession) {
  pendingExpireSession.value = session
  expireReason.value = ''
  showExpireDialog.value = true
}

function confirmExpireSession() {
  if (!pendingExpireSession.value) return
  pendingExpireSession.value.status = 'expired'
  pendingExpireSession.value.expiresIn = 'Closed by Ops'
  showToast(
    `Bid session ${pendingExpireSession.value.id} (${pendingExpireSession.value.bookingRef}) closed manually.`,
  )
  pendingExpireSession.value = null
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Live Bidding"
      description="Monitor active passenger fare offers and driver bid responses."
    />

    <ToastBanner :message="toastMessage" tone="info" @dismiss="toastMessage = null" />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3"
      >
        <div class="w-full sm:w-80">
          <SearchField
            v-model="searchQuery"
            placeholder="Search ref 7016..., passenger, barangay..."
            aria-label="Search bidding sessions"
          />
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <span
            class="px-2.5 py-1 bg-neutral-50 border border-neutral-300 text-[11px] font-semibold text-neutral-800 tabular-nums"
          >
            Open: {{ openSessionCount }}
          </span>
          <span
            class="px-2.5 py-1 bg-neutral-50 border border-neutral-300 text-[11px] font-semibold text-neutral-800 tabular-nums"
          >
            Match: {{ acceptanceRate }}
          </span>
          <BaseSelect
            v-model="statusFilter"
            aria-label="Filter by session status"
            :options="[
              { label: 'All Session States', value: 'all' },
              { label: 'Open', value: 'open' },
              { label: 'Accepted', value: 'accepted' },
              { label: 'Declined', value: 'declined' },
              { label: 'Expired', value: 'expired' },
              { label: 'Cancelled', value: 'cancelled' },
            ]"
          />
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[840px] text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Session / Ref</th>
              <th class="py-3 px-4">Passenger</th>
              <th class="py-3 px-4">Route</th>
              <th class="py-3 px-4">Estimate vs Offer</th>
              <th class="py-3 px-4">Dispatch Mode</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="session in paginatedSessions"
              :key="session.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ session.id }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ session.bookingRef }}</div>
              </td>
              <td class="py-3 px-4">
                <div class="font-semibold text-neutral-900">{{ session.passenger }}</div>
                <div class="text-[11px] text-neutral-500 font-mono">
                  {{ session.passengerPhone }}
                </div>
              </td>
              <td class="py-3 px-4 text-neutral-600 max-w-[260px]">
                <div class="truncate font-medium text-neutral-800">{{ session.pickup }}</div>
                <div class="truncate text-neutral-500">-> {{ session.dropoff }}</div>
              </td>
              <td class="py-3 px-4 tabular-nums">
                <div class="font-bold text-neutral-900">
                  {{ formatPhp(session.passengerOffer + session.tipAmount) }}
                </div>
                <div class="text-[11px] text-neutral-500">
                  Base est. {{ formatPhp(session.systemEstimate) }}
                  <span v-if="session.tipAmount > 0" class="text-emerald-700 font-semibold">
                    (+{{ formatPhp(session.tipAmount) }} tip)
                  </span>
                </div>
              </td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-800">{{ session.requestMode }}</div>
                <div class="text-[11px] text-neutral-400">
                  {{ session.offers.length }} driver responses · {{ session.expiresIn }}
                </div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="session.status.toUpperCase()"
                  :tone="statusTone(session.status)"
                />
              </td>
              <td class="py-3 px-4 text-right whitespace-nowrap">
                <div class="inline-flex items-center gap-2">
                  <button
                    type="button"
                    class="text-xs font-semibold text-neutral-900 hover:underline cursor-pointer"
                    @click="inspectedSession = session"
                  >
                    Inspect Offers
                  </button>
                  <button
                    v-if="session.status === 'open'"
                    type="button"
                    class="px-2.5 py-1 bg-white hover:bg-neutral-50 border border-neutral-300 text-neutral-800 font-semibold text-[11px] transition-colors cursor-pointer"
                    @click="promptExpireSession(session)"
                  >
                    Close Bid
                  </button>
                </div>
              </td>
            </tr>
            <EmptyTableRow
              v-if="paginatedSessions.length === 0"
              :colspan="7"
              title="No bidding sessions match the selected filters"
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
          </tbody>
        </table>
      </div>

      <TablePagination
        v-model:current-page="currentPage"
        :total-items="filteredSessions.length"
        :items-per-page="itemsPerPage"
      />
    </div>

    <ModalDialog
      :open="Boolean(inspectedSession)"
      :title="inspectedSession ? `Bid Session ${inspectedSession.id}` : ''"
      :subtitle="
        inspectedSession
          ? `Ref: ${inspectedSession.bookingRef} · ${inspectedSession.createdAt}`
          : undefined
      "
      size="lg"
      close-label="Close offer inspector"
      @update:open="(open) => !open && (inspectedSession = null)"
    >
      <div v-if="inspectedSession" class="space-y-4 text-xs">
        <div
          class="grid grid-cols-1 sm:grid-cols-2 gap-3 bg-neutral-50 p-3 border border-neutral-200"
        >
          <div>
            <div class="text-neutral-500">System Fare Estimate</div>
            <div class="font-bold font-mono text-neutral-900">
              {{ formatPhp(inspectedSession.systemEstimate) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Passenger Total Bid</div>
            <div class="font-bold font-mono text-emerald-700">
              {{ formatPhp(inspectedSession.passengerOffer + inspectedSession.tipAmount) }}
            </div>
          </div>
          <div v-if="inspectedSession.note" class="sm:col-span-2">
            <div class="text-neutral-500">Pickup Note</div>
            <div class="text-neutral-800">{{ inspectedSession.note }}</div>
          </div>
        </div>

        <div class="space-y-2">
          <h3 class="text-xs font-bold uppercase tracking-wider text-neutral-500">
            Driver Responses ({{ inspectedSession.offers.length }})
          </h3>
          <div
            v-if="inspectedSession.offers.length === 0"
            class="p-4 text-center text-xs text-neutral-500 border border-dashed border-neutral-200"
          >
            No driver offers were recorded before timeout or cancellation.
          </div>
          <div
            v-for="offer in inspectedSession.offers"
            :key="offer.id"
            class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 p-3 border border-neutral-200 text-xs"
          >
            <div>
              <div class="font-bold text-neutral-900">
                {{ offer.driverName }} · ★ {{ offer.driverRating.toFixed(2) }}
              </div>
              <div class="text-[11px] font-mono text-neutral-500">
                {{ offer.plate }} · {{ offer.bodyUnit }} · ETA {{ offer.etaMinutes }} mins
              </div>
            </div>
            <StatusBadge
              :label="offer.status.toUpperCase()"
              :tone="
                offer.status === 'accepted'
                  ? 'success'
                  : offer.status === 'declined'
                    ? 'danger'
                    : 'info'
              "
            />
          </div>
        </div>
      </div>

      <template #footer>
        <div class="flex justify-end">
          <button
            type="button"
            class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
            @click="inspectedSession = null"
          >
            Close
          </button>
        </div>
      </template>
    </ModalDialog>

    <ConfirmDialog
      v-model:open="showExpireDialog"
      v-model:reason="expireReason"
      title="Close Open Bid Session?"
      description="Closing this bid session expires pending driver offers and prevents late passenger matching."
      confirm-label="Expire Session"
      tone="rose"
      :require-reason="true"
      reason-label="Operator Reason"
      @confirm="confirmExpireSession"
    />
  </div>
</template>
