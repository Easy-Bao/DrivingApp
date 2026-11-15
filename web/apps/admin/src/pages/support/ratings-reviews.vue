<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  useReviewModeration,
  type ReviewDirection,
  type ReviewEntry,
  type ReviewModerationState,
} from '@/features/support'
import {
  BaseSelect,
  ConfirmDialog,
  EmptyTableRow,
  PageHeader,
  SearchField,
  StatusBadge,
  ToastBanner,
} from '@/shared'

const { reviews, moderateReview } = useReviewModeration()

const searchQuery = ref('')
const directionFilter = ref<'All' | ReviewDirection>('All')
const stateFilter = ref<'All' | ReviewModerationState>('All')
const toastMessage = ref<string | null>(null)

const targetReview = ref<ReviewEntry | null>(null)
const pendingAction = ref<'hide' | 'approve'>('approve')
const dialogOpen = ref(false)
const moderationReason = ref('')

const filteredReviews = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return reviews.value.filter((review) => {
    const matchesDir = directionFilter.value === 'All' || review.direction === directionFilter.value
    const matchesState = stateFilter.value === 'All' || review.moderationState === stateFilter.value
    const matchesSearch =
      !query ||
      review.id.toLowerCase().includes(query) ||
      review.tripId.toLowerCase().includes(query) ||
      review.author.toLowerCase().includes(query) ||
      review.subjectParty.toLowerCase().includes(query) ||
      review.comment.toLowerCase().includes(query)
    return matchesDir && matchesState && matchesSearch
  })
})

const hasActiveFilters = computed(
  () =>
    searchQuery.value.trim().length > 0 ||
    directionFilter.value !== 'All' ||
    stateFilter.value !== 'All',
)

const resetFilters = () => {
  searchQuery.value = ''
  directionFilter.value = 'All'
  stateFilter.value = 'All'
}

const openModerationConfirm = (entry: ReviewEntry, action: 'hide' | 'approve') => {
  targetReview.value = entry
  pendingAction.value = action
  moderationReason.value = ''
  dialogOpen.value = true
}

const confirmModeration = () => {
  const target = targetReview.value
  if (!target) return
  const result = moderateReview(target.id, pendingAction.value, moderationReason.value)
  if (!result.ok) {
    toastMessage.value = result.error
    return
  }
  toastMessage.value = `${target.id} updated to ${target.moderationState}.`
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

    <PageHeader
      title="Reviews"
      description="Moderate passenger and driver feedback and rating eligibility."
    />

    <div class="bg-white border border-neutral-200 overflow-hidden">
      <div
        class="p-4 border-b border-neutral-100 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
      >
        <div class="flex flex-wrap items-center gap-3">
          <SearchField
            v-model="searchQuery"
            placeholder="Search review ID, trip ID, driver, or passenger..."
            aria-label="Search reviews"
            class="md:w-72"
          />
          <span class="text-xs font-medium text-neutral-500 tabular-nums">
            {{ filteredReviews.length }} Reviews
          </span>
        </div>

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
              v-for="review in filteredReviews"
              :key="review.id"
              class="hover:bg-neutral-50/70 transition-colors"
            >
              <td class="py-3.5 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ review.id }}</div>
                <div class="text-[11px] font-mono text-neutral-500">{{ review.tripId }}</div>
                <div class="text-[10px] text-neutral-400">{{ review.direction }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-semibold text-neutral-900">{{ review.subjectParty }}</div>
                <div class="text-[11px] text-neutral-500">By {{ review.author }}</div>
              </td>
              <td class="py-3.5 px-4">
                <div class="font-mono font-bold text-neutral-900">{{ review.rating }}.0 ★</div>
                <div class="flex flex-wrap gap-1 mt-1">
                  <span
                    v-for="tag in review.tags"
                    :key="tag"
                    class="px-1.5 py-0.5 bg-neutral-100 text-neutral-700 text-[10px]"
                  >
                    {{ tag }}
                  </span>
                </div>
              </td>
              <td class="py-3.5 px-4 max-w-sm text-neutral-700">
                <div>{{ review.comment }}</div>
                <div
                  v-if="review.moderationReason"
                  class="text-[11px] text-neutral-500 mt-1 italic"
                >
                  Moderator: {{ review.moderationReason }}
                </div>
              </td>
              <td class="py-3.5 px-4">
                <StatusBadge
                  :label="review.moderationState"
                  :tone="
                    review.moderationState === 'Published'
                      ? 'success'
                      : review.moderationState === 'Flagged for Review'
                        ? 'warning'
                        : 'danger'
                  "
                />
              </td>
              <td class="py-3.5 px-4 text-right whitespace-nowrap">
                <div class="inline-flex items-center gap-2">
                  <button
                    v-if="review.moderationState !== 'Published'"
                    type="button"
                    class="px-2.5 py-1 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
                    @click="openModerationConfirm(review, 'approve')"
                  >
                    Approve Public
                  </button>
                  <button
                    v-if="review.moderationState !== 'Hidden by Moderator'"
                    type="button"
                    class="px-2.5 py-1 border border-neutral-300 bg-white text-neutral-700 rounded-none text-xs font-medium hover:bg-neutral-50"
                    @click="openModerationConfirm(review, 'hide')"
                  >
                    Hide Remark
                  </button>
                </div>
              </td>
            </tr>
            <EmptyTableRow
              v-if="filteredReviews.length === 0"
              :colspan="6"
              title="No matching review entries"
              description="No rating or review entries match the active filters."
              :show-reset="hasActiveFilters"
              @reset="resetFilters"
            />
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
