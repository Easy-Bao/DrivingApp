import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import { resetSupportForTesting } from '@/features/support'
import RatingsReviewsPage from '@/pages/support/ratings-reviews.vue'
import LostFoundPage from '@/pages/support/lost-found.vue'
import FaqsPage from '@/pages/support/faqs.vue'

describe('support community pages', () => {
  beforeEach(() => {
    resetSettingsForTesting()
    resetSupportForTesting()
  })

  it('approves flagged review with mandatory moderation reason and logs audit action', async () => {
    const wrapper = mount(RatingsReviewsPage)
    const { logs } = useAuditLogs()

    const approveBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('Approve Public'))
    expect(approveBtn).toBeDefined()
    await approveBtn!.trigger('click')

    const findConfirmBtn = () =>
      wrapper.findAll('button').find((button) => button.text().includes('Approve & Publish'))
    expect(findConfirmBtn()!.attributes('disabled')).toBeDefined()

    await wrapper
      .find('textarea')
      .setValue('Confirmed driver coaching completion at Pagadian dispatch desk.')
    expect(findConfirmBtn()!.attributes('disabled')).toBeUndefined()
    await findConfirmBtn()!.trigger('click')

    expect(wrapper.text()).toContain('REV-7016-900 updated to Published.')
    expect(logs.value[0]!.action).toBe('REVIEW_MODERATED')
  })

  it('logs lost item with matching driver phone and confirms owner return', async () => {
    const wrapper = mount(LostFoundPage)
    const { logs } = useAuditLogs()

    const confirmReturnBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('Confirm Return'))
    expect(confirmReturnBtn).toBeDefined()
    await confirmReturnBtn!.trigger('click')

    const findMarkReturned = () =>
      wrapper.findAll('button').find((button) => button.text().includes('Mark Returned to Owner'))
    expect(findMarkReturned()!.attributes('disabled')).toBeDefined()

    await wrapper
      .find('textarea')
      .setValue('Verified student ID and returned pouch at Agora booth.')
    await findMarkReturned()!.trigger('click')

    expect(wrapper.text()).toContain('LF-7016-801 closed as Returned to Owner.')
    expect(logs.value[0]!.action).toBe('LOST_ITEM_RETURNED')
  })

  it('creates and toggles FAQ article visibility with audit tracking', async () => {
    const wrapper = mount(FaqsPage)
    const { logs } = useAuditLogs()

    const createBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('+ New FAQ'))
    expect(createBtn).toBeDefined()
    await createBtn!.trigger('click')

    const questionInput = wrapper.find('input[aria-label="FAQ question heading"]')
    const answerBox = wrapper.find('textarea')
    await questionInput.setValue('Where do drivers pick up terminal passengers?')
    await answerBox.setValue('Use designated Bay 2 loading lane at Integrated Bus Terminal.')

    const publishBtn = wrapper
      .findAll('button')
      .find((button) => button.text().includes('Publish Article'))
    await publishBtn!.trigger('click')

    expect(wrapper.text()).toContain('Published new Help Center article FAQ-05.')
    expect(logs.value[0]!.action).toBe('FAQ_CREATED')
  })
})
