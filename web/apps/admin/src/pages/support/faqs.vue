<script setup lang="ts">
import { computed, ref } from 'vue'
import BaseSelect from '@/shared/forms/BaseSelect.vue'
import ModalDialog from '@/shared/dialogs/ModalDialog.vue'
import PageHeader from '@/shared/layout/PageHeader.vue'
import SearchField from '@/shared/forms/SearchField.vue'
import StatusBadge from '@/shared/feedback/StatusBadge.vue'
import ToastBanner from '@/shared/feedback/ToastBanner.vue'

interface FaqArticle {
  id: string
  category: 'Fare Bidding' | 'Driver Top-Ups' | 'Safety & SOS' | 'Documents & TODA'
  audience: 'Passenger' | 'Driver'
  question: string
  answer: string
  views: number
  isPublished: boolean
}

const faqs = ref<FaqArticle[]>([
  {
    id: 'FAQ-01',
    category: 'Fare Bidding',
    audience: 'Passenger',
    question: 'How does Pagadian fare bidding work before pickup?',
    answer:
      'Enter your pickup and Pagadian destination pin to view the suggested tariff floor. Nearby drivers send custom PHP bids within the 90-second session window (capped at 2.5x surge). Choose the bid you prefer to confirm pickup.',
    views: 4820,
    isPublished: true,
  },
  {
    id: 'FAQ-02',
    category: 'Driver Top-Ups',
    audience: 'Driver',
    question: 'Why must I maintain at least ₱50.00 in my prepaid driver wallet?',
    answer:
      'Passengers pay 100% of the trip fare directly in cash upon drop-off. A minimum ₱50.00 balance ensures the 15% commission deduction can clear automatically without locking you out of dispatch.',
    views: 3690,
    isPublished: true,
  },
  {
    id: 'FAQ-03',
    category: 'Driver Top-Ups',
    audience: 'Driver',
    question: 'How do I submit a GCash or Maya QRPh top-up receipt?',
    answer:
      'Open Wallet -> Top-Up Credits, transfer PHP to an active EasyRide Pagadian QRPh merchant code or BDO/BPI account, and upload your screenshot receipt plus reference number for operations approval.',
    views: 2910,
    isPublished: true,
  },
  {
    id: 'FAQ-04',
    category: 'Safety & SOS',
    audience: 'Passenger',
    question: 'What happens when the in-ride SOS button is pressed?',
    answer:
      'Live GPS coordinates inside Pagadian City are broadcast immediately to the EasyRide Emergency Desk alongside direct escalation lines to National 911 and Pagadian CDRRMO (062-925-0911).',
    views: 1540,
    isPublished: true,
  },
])

const audienceFilter = ref<'All' | FaqArticle['audience']>('All')
const searchQuery = ref('')
const toastMessage = ref<string | null>(null)

const showEditorModal = ref(false)
const editingId = ref<string | null>(null)
const draftCategory = ref<FaqArticle['category']>('Fare Bidding')
const draftAudience = ref<FaqArticle['audience']>('Passenger')
const draftQuestion = ref('')
const draftAnswer = ref('')
const editorError = ref<string | null>(null)

const filteredFaqs = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return faqs.value.filter((faq) => {
    const matchesAudience = audienceFilter.value === 'All' || faq.audience === audienceFilter.value
    const matchesQuery =
      !query ||
      faq.question.toLowerCase().includes(query) ||
      faq.answer.toLowerCase().includes(query) ||
      faq.category.toLowerCase().includes(query)
    return matchesAudience && matchesQuery
  })
})

const hasActiveFilters = computed(
  () => searchQuery.value.trim().length > 0 || audienceFilter.value !== 'All',
)

const resetFilters = () => {
  searchQuery.value = ''
  audienceFilter.value = 'All'
}

const openCreateFaq = () => {
  editingId.value = null
  draftCategory.value = 'Fare Bidding'
  draftAudience.value = 'Passenger'
  draftQuestion.value = ''
  draftAnswer.value = ''
  editorError.value = null
  showEditorModal.value = true
}

const openEditFaq = (article: FaqArticle) => {
  editingId.value = article.id
  draftCategory.value = article.category
  draftAudience.value = article.audience
  draftQuestion.value = article.question
  draftAnswer.value = article.answer
  editorError.value = null
  showEditorModal.value = true
}

const saveFaqArticle = () => {
  if (!draftQuestion.value.trim() || !draftAnswer.value.trim()) {
    editorError.value = 'Enter both a question heading and helpful answer text.'
    return
  }

  if (editingId.value) {
    const target = faqs.value.find((faq) => faq.id === editingId.value)
    if (target) {
      target.category = draftCategory.value
      target.audience = draftAudience.value
      target.question = draftQuestion.value.trim()
      target.answer = draftAnswer.value.trim()
      toastMessage.value = `Updated FAQ article ${target.id}.`
    }
  } else {
    const nextId = `FAQ-0${faqs.value.length + 1}`
    faqs.value.unshift({
      id: nextId,
      category: draftCategory.value,
      audience: draftAudience.value,
      question: draftQuestion.value.trim(),
      answer: draftAnswer.value.trim(),
      views: 0,
      isPublished: true,
    })
    toastMessage.value = `Published new Help Center article ${nextId}.`
  }

  showEditorModal.value = false
}

const togglePublished = (article: FaqArticle) => {
  article.isPublished = !article.isPublished
  toastMessage.value = `${article.id} is now ${article.isPublished ? 'Published in apps' : 'Draft (Hidden)'}.`
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
      title="Help Center"
      description="Manage help articles synced to the Passenger and Driver mobile apps."
    />

    <div
      class="bg-white border border-neutral-200 p-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
    >
      <SearchField
        v-model="searchQuery"
        placeholder="Search FAQ question, answer, or topic..."
        aria-label="Search FAQ articles"
        class="md:w-80"
      />

      <div class="flex flex-wrap items-center gap-2">
        <BaseSelect
          v-model="audienceFilter"
          aria-label="Filter by app audience"
          :options="[
            { label: 'All App Audiences', value: 'All' },
            { label: 'Passenger App', value: 'Passenger' },
            { label: 'Driver App', value: 'Driver' },
          ]"
        />
        <button
          type="button"
          class="px-3.5 py-1.5 bg-neutral-900 hover:bg-neutral-800 text-white rounded-none text-xs font-semibold cursor-pointer shrink-0"
          @click="openCreateFaq"
        >
          + New FAQ
        </button>
      </div>
    </div>

    <div class="space-y-3">
      <div
        v-for="faq in filteredFaqs"
        :key="faq.id"
        class="bg-white border border-neutral-200 p-5 space-y-3"
      >
        <div class="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
          <div class="space-y-1">
            <div class="flex flex-wrap items-center gap-2">
              <span class="font-mono text-xs font-bold text-neutral-500">{{ faq.id }}</span>
              <StatusBadge :label="faq.category" tone="info" />
              <StatusBadge :label="`${faq.audience} App`" tone="neutral" />
              <StatusBadge
                :label="faq.isPublished ? 'Published' : 'Draft'"
                :tone="faq.isPublished ? 'success' : 'warning'"
              />
            </div>
            <h3 class="text-sm font-bold text-neutral-900 pt-1">{{ faq.question }}</h3>
          </div>

          <div class="flex items-center gap-2 shrink-0">
            <button
              type="button"
              class="px-3 py-1 border border-neutral-300 bg-white text-neutral-800 rounded-none text-xs font-medium hover:bg-neutral-50"
              @click="openEditFaq(faq)"
            >
              Edit
            </button>
            <button
              type="button"
              class="px-3 py-1 border border-neutral-300 bg-white text-neutral-700 rounded-none text-xs font-medium hover:bg-neutral-50"
              @click="togglePublished(faq)"
            >
              {{ faq.isPublished ? 'Unpublish' : 'Publish' }}
            </button>
          </div>
        </div>

        <p class="text-xs text-neutral-600 leading-relaxed">{{ faq.answer }}</p>
        <div class="text-[11px] font-mono text-neutral-400">
          Mobile Help Views: {{ faq.views.toLocaleString() }}
        </div>
      </div>

      <div
        v-if="filteredFaqs.length === 0"
        class="bg-white border border-neutral-200 p-8 text-center space-y-2"
      >
        <p class="text-xs font-semibold text-neutral-700">No matching FAQ articles</p>
        <p class="text-[11px] text-neutral-500">
          Try adjusting your search query or audience filter.
        </p>
        <button
          v-if="hasActiveFilters"
          type="button"
          class="mt-1 px-3 py-1.5 border border-neutral-300 bg-white text-xs font-medium text-neutral-700 hover:bg-neutral-50 cursor-pointer"
          @click="resetFilters"
        >
          Reset filters
        </button>
      </div>
    </div>

    <ModalDialog
      v-model:open="showEditorModal"
      :title="editingId ? `Edit FAQ Article · ${editingId}` : 'Create Help Center Article'"
      size="lg"
    >
      <div class="space-y-3 text-xs">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Topic Category</label>
            <BaseSelect
              v-model="draftCategory"
              :full-width="true"
              aria-label="FAQ category"
              :options="['Fare Bidding', 'Driver Top-Ups', 'Safety & SOS', 'Documents & TODA']"
            />
          </div>
          <div>
            <label class="block font-medium text-neutral-700 mb-1">Target App</label>
            <BaseSelect
              v-model="draftAudience"
              :full-width="true"
              aria-label="FAQ target app"
              :options="['Passenger', 'Driver']"
            />
          </div>
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Question Heading</label>
          <input
            v-model="draftQuestion"
            type="text"
            class="w-full px-3 py-1.5 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <div>
          <label class="block font-medium text-neutral-700 mb-1">Answer Copy</label>
          <textarea
            v-model="draftAnswer"
            rows="4"
            class="w-full px-3 py-2 border border-neutral-300 rounded-none bg-white text-neutral-900"
          />
        </div>

        <p v-if="editorError" class="text-xs font-medium text-rose-700">{{ editorError }}</p>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 border border-neutral-300 rounded-none text-xs font-medium text-neutral-700 hover:bg-neutral-50"
            @click="showEditorModal = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-3 py-1.5 bg-neutral-900 text-white rounded-none text-xs font-medium hover:bg-neutral-800"
            @click="saveFaqArticle"
          >
            {{ editingId ? 'Save Changes' : 'Publish Article' }}
          </button>
        </div>
      </template>
    </ModalDialog>
  </div>
</template>
