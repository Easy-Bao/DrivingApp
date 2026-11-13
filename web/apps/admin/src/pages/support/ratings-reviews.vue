<script setup lang="ts">
import { computed, ref } from 'vue'
import BaseSelect from '@/shared/components/BaseSelect.vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import StatusBadge from '@/shared/components/StatusBadge.vue'
import ToastBanner from '@/shared/components/ToastBanner.vue'

interface ReviewEntry {
  id: string
  tripId: string
  direction: 'Driver Review' | 'Passenger Review'
  author: string
  subjectParty: string
  rating: number
  comment: string
  tags: string[]
  moderationState: 'Published' | 'Flagged for Review' | 'Hidden by Moderator'
  moderationReason?: string
}

const reviews = ref<ReviewEntry[]>([
  {
    id: 'REV-7016-901',
    tripId: 'TRP-7016-8921',
    direction: 'Driver Review',
    author: 'Althea Mae Villanueva',
    subjectParty: 'Rodelio Cruz (TODA-0412)',
    rating: 5,
    comment: 'Very polite, safe speed uphill to San Jose, exact change ready.',
    tags: ['Safe Driving', 'Polite', 'Clean Taxicle'],
    moderationState: 'Published',
  },
  {
    id: 'REV-7016-900',
    tripId: 'TRP-7016-8918',
    direction: 'Driver Review',
    author: 'Clarisse Joy Tagupa',
    subjectParty: 'Ernesto Villafuerte (TODA-0318)',
    rating: 2,
    comment: 'Rude argument when dropping off along Rizal Ave; needs coaching.',
    tags: ['Communication Issue'],
    moderationState: 'Flagged for Review',
  },
  {
    id: 'REV-7016-899',
    tripId: 'TRP-7016-8910',
    direction: 'Passenger Review',
    author: 'Danilo Mendoza',
    subjectParty: 'Maricar Santos (Passenger)',
    rating: 5,
    comment: 'Passenger waited right outside Integrated Terminal North Gate on time.',
    tags: ['Punctual', 'Clear Pickup Pin'],
    moderationState: 'Published',
  },
  {
    id: 'REV-7016-898',
    tripId: 'TRP-7016-8892',
    direction: 'Passenger Review',
    author: 'Reynaldo Bautista',
    subjectParty: 'Kevin Lloyd Tan (Passenger)',
    rating: 4,
    comment: 'Smooth trip to Dao Medical Center.',
    tags: ['Respectful'],
    moderationState: 'Published',
  },
])

const directionFilter = ref<'All' | ReviewEntry['direction']>('All')
const stateFilter = ref<'All' | ReviewEntry['moderationState']>('All')
const toastMessage = ref<string | null>(null)

const targetReview = ref<ReviewEntry | null>(null)
const pendingAction = ref<'hide' | 'approve'>('approve')
const dialogOpen = ref(false)
const moderationReason = ref('')

const filteredReviews = computed(() =>
  reviews.value.filter((r) => {
    const matchesDir = directionFilter.value === 'All' || r.direction === directionFilter.value
    const matchesState = stateFilter.value === 'All' || r.moderationState === stateFilter.value
    return matchesDir && matchesState
  }),
)

const openModerationConfirm = (entry: ReviewEntry, action: 'hide' | 'approve') => {
  targetReview.value = entry
  pendingAction.value = action
  moderationReason.value = ''
  dialogOpen.value = true
}

const confirmModeration = () => {
  if (!targetReview.value || !moderationReason.value.trim()) return
  targetReview.value.moderationState =
    pendingAction.value === 'hide' ? 'Hidden by Moderator' : 'Published'
  targetReview.value.moderationReason = moderationReason.value.trim()
  toastMessage.value = `${targetReview.value.id} updated to ${targetReview.value.moderationState}.`
  dialogOpen.value = false
  targetReview.value = null
  moderationReason.value = ''
}
</script>

<template>
  <div class="space-y-6">
    <ToastBanner
      v-if="toastMessage"
      :message="toastMessage"
      tone="info"
      @dismiss="toastMessage = null"
    />

    <div
      class="bg-white border border-neutral-200 p-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
    >
      <div>
        <h2 class="text-sm font-semibold text-neutral-900">
          Two-Sided Ratings &amp; Review Moderation
        </h2>
        <p class="text-xs text-neutral-500 mt-0.5">
          Audit passenger reviews for drivers (governing the 4.5★ high-rating incentive) and driver
          feedback for passengers.
        </p>
      </div>
    </div>

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
      >
        <span class="text-xs font-medium text-neutral-500 tabular-nums">
          {{ filteredReviews.length }} Reviews
        </span>

        <div class="flex flex-wrap items-center gap-2">
          <BaseSelect
            v-model="directionFilter"
            aria-label="Filter by review direction"
            :options="[
              { label: 'All Feedback', value: 'All' },
              { label: 'Driver Reviews', value: 'Driver Review' },
              { label: 'Passenger Reviews', value: 'Passenger Review' },
            ]"
          />
          <BaseSelect
            v-model="stateFilter"
            aria-label="Filter by moderation state"
            :options="[
              { label: 'All States', value: 'All' },
              { label: 'Published', value: 'Published' },
              { label: 'Flagged for Review', value: 'Flagged for Review' },
              { label: 'Hidden by Moderator', value: 'Hidden by Moderator' },
            ]"
          />
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-[840px] w-full text-left text-xs">
          <thead
            class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
          >
            <tr>
              <th class="py-3 px-4">Review &amp; Trip</th>
              <th class="py-3 px-4">Subject Party</th>
              <th class="py-3 px-4">Rating &amp; Tags</th>
              <th class="py-3 px-4">Submitted Remarks</th>
              <th class="py-3 px-4">Status</th>
              <th class="py-3 px-4 text-right">Moderation</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-neutral-100">
            <tr
              v-for="r in filteredReviews"
              :key="r.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3.5 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ r.id }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ r.tripId }}</div>
                <div class="text-[10px] text-neutral-400">{{ r.direction }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-semibold text-neutral-900">{{ r.subjectParty }}</div>
                <div class="text-[11px] text-neutral-500">By {{ r.author }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ r.rating }}.0 ★</div>
                <div class="flex flex-wrap gap-1 mt-1">
                  <span
                    v-for="tag in r.tags"
                    :key="tag"
                    class="px-1.5 py-0.5 bg-neutral-100 text-neutral-700 text-[10px]"
                  >
                    {{ tag }}
                  </span>
                </div>
              </td>
              <td class="py-3.5 px-4 max-w-sm text-neutral-700">
                <div>{{ r.comment }}</div>
                <div v-if="r.moderationReason" class="text-[11px] text-neutral-500 mt-1 italic">
                  Moderator: {{ r.moderationReason }}
                </div>
              </td>
              <td class="py-3.5 px-4">
                <StatusBadge
                  :label="r.moderationState"
                  :tone="
                    r.moderationState === 'Published'
                      ? 'success'
                      : r.moderationState === 'Flagged for Review'
                        ? 'warning'
                        : 'danger'
                  "
                />
              </td>
              <td class="py-3.5 px-4 text-right whitespace-nowrap">
                <div class="inline-flex items-center gap-2">
                  <button
                    v-if="r.moderationState !== 'Published'"
                    type="button"
                    class="px-2.5 py-1 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
                    @click="openModerationConfirm(r, 'approve')"
                  >
                    Approve Public
                  </button>
                  <button
                    v-if="r.moderationState !== 'Hidden by Moderator'"
                    type="button"
                    class="px-2.5 py-1 border border-neutral-300 bg-white text-neutral-700 rounded-none text-xs font-medium hover:bg-neutral-50"
                    @click="openModerationConfirm(r, 'hide')"
                  >
                    Hide Remark
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <ConfirmDialog
      v-model:open="dialogOpen"
      v-model:reason="moderationReason"
      :title="
        pendingAction === 'hide'
          ? `Hide Review Remark · ${targetReview?.id ?? ''}`
          : `Approve Review · ${targetReview?.id ?? ''}`
      "
      :description="
        pendingAction === 'hide'
          ? 'Hide abusive or unverified public commentary while preserving numeric star history.'
          : 'Restore review visibility on the profile summary.'
      "
      :confirm-label="pendingAction === 'hide' ? 'Hide Comment' : 'Approve & Publish'"
      :tone="pendingAction === 'hide' ? 'rose' : 'emerald'"
      :require-reason="true"
      reason-label="Mandatory Moderation Rationale"
      reason-placeholder="e.g., Confirmed coaching note logged in safety desk..."
      @confirm="confirmModeration"
      @cancel="dialogOpen = false"
    />
  </div>
</template>
