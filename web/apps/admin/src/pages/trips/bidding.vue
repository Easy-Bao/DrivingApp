<script setup lang="ts">
import { computed, ref } from 'vue'
import { useBiddingSessions, type BidSession, type BidSessionStatus } from '@/features/trips'
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
  useToast,
} from '@/shared'

const { sessions, openSessionCount, acceptanceRateLabel, bidSessionStatusTone, expireSession } =
  useBiddingSessions()

const searchQuery = ref('')
const statusFilter = ref<'all' | BidSessionStatus>('all')
const inspectedSession = ref<BidSession | null>(null)
const pendingExpireSession = ref<BidSession | null>(null)
const showExpireDialog = ref(false)
const expireReason = ref('')
const { message: toastMessage, tone: toastTone, showToast, dismissToast } = useToast('info')

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

const {
  currentPage,
  itemsPerPage,
  paginatedItems: paginatedSessions,
} = useDataTable(filteredSessions, {
  initialPageSize: 5,
  resetDeps: [searchQuery, statusFilter],
})

const hasActiveFilters = computed(() => searchQuery.value !== '' || statusFilter.value !== 'all')

function resetFilters() {
  searchQuery.value = ''
  statusFilter.value = 'all'
}

function promptExpireSession(session: BidSession) {
  pendingExpireSession.value = session
  expireReason.value = ''
  showExpireDialog.value = true
}

function confirmExpireSession() {
  const target = pendingExpireSession.value
  if (!target) return
  const result = expireSession(target.id, expireReason.value)
  if (!result.ok) {
    showToast(result.error)
    return
  }
  showToast(`Bid session ${target.id} (${target.bookingRef}) closed manually.`)
  pendingExpireSession.value = null
  showExpireDialog.value = false
}
</script>

<template>
  <div class="space-y-6">
    <PageHeader
      title="Live Bidding"
      description="Monitor active passenger fare offers and driver bid responses."
    />

    <ToastBanner :message="toastMessage" :tone="toastTone" @dismiss="dismissToast" />

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
            Match: {{ acceptanceRateLabel }}
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
              <td
                class="py-3 px-4 text-neutral-600 max-w-[260px]"
                :title="`${session.pickup} → ${session.dropoff}`"
              >
                <div class="truncate font-medium text-neutral-800">{{ session.pickup }}</div>
                <div class="truncate text-neutral-500">→ {{ session.dropoff }}</div>
              </td>
              <td class="py-3 px-4 tabular-nums">
                <div class="font-bold text-neutral-900">
                  {{ formatCentavos(session.passengerOfferCentavos + session.tipAmountCentavos) }}
                </div>
                <div class="text-[11px] text-neutral-500">
                  Base est. {{ formatCentavos(session.systemEstimateCentavos) }}
                  <span v-if="session.tipAmountCentavos > 0" class="text-emerald-700 font-semibold">
                    (+{{ formatCentavos(session.tipAmountCentavos) }} tip)
                  </span>
                </div>
              </td>
              <td class="py-3 px-4">
                <div class="font-medium text-neutral-800">{{ session.requestMode }}</div>
                <div class="text-[11px] text-neutral-500">
                  {{ session.offers.length }} driver responses · {{ session.expiresIn }}
                </div>
              </td>
              <td class="py-3 px-4">
                <StatusBadge
                  :label="session.status.toUpperCase()"
                  :tone="bidSessionStatusTone(session.status)"
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
              {{ formatCentavos(inspectedSession.systemEstimateCentavos) }}
            </div>
          </div>
          <div>
            <div class="text-neutral-500">Passenger Total Bid</div>
            <div class="font-bold font-mono text-emerald-700">
              {{
                formatCentavos(
                  inspectedSession.passengerOfferCentavos + inspectedSession.tipAmountCentavos,
                )
              }}
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
        <button
          type="button"
          class="px-4 py-2 bg-neutral-900 hover:bg-neutral-800 text-white text-xs font-semibold cursor-pointer"
          @click="inspectedSession = null"
        >
          Close
        </button>
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
