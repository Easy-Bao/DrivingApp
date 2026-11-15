<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  useFaqArticles,
  type FaqArticle,
  type FaqAudience,
  type FaqCategory,
} from '@/features/support'
import {
  BaseSelect,
  ModalDialog,
  PageHeader,
  SearchField,
  StatusBadge,
  ToastBanner,
} from '@/shared'

const { faqs, saveFaq, togglePublished } = useFaqArticles()

const audienceFilter = ref<'All' | FaqAudience>('All')
const searchQuery = ref('')
const toastMessage = ref<string | null>(null)

const showEditorModal = ref(false)
const editingId = ref<string | null>(null)
const draftCategory = ref<FaqCategory>('Fare Bidding')
const draftAudience = ref<FaqAudience>('Passenger')
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
  const previousCount = faqs.value.length
  const result = saveFaq({
    id: editingId.value ?? undefined,
    category: draftCategory.value,
    audience: draftAudience.value,
    question: draftQuestion.value,
    answer: draftAnswer.value,
  })
  if (!result.ok) {
    editorError.value = result.error
    return
  }

  if (editingId.value) {
    toastMessage.value = `Updated FAQ article ${editingId.value}.`
  } else if (faqs.value.length > previousCount) {
    toastMessage.value = `Published new Help Center article ${faqs.value[0]?.id ?? ''}.`
  }

  showEditorModal.value = false
}

const handleTogglePublished = (article: FaqArticle) => {
  const result = togglePublished(article.id)
  if (!result.ok) {
    toastMessage.value = result.error
    return
  }
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
              @click="handleTogglePublished(faq)"
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
            aria-label="FAQ question heading"
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
