import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { resetSettingsForTesting, useAuditLogs } from '@/features/settings'
import ServiceZonesPage from '@/pages/config/service-zones.vue'

describe('settings/service-zones page', () => {
  beforeEach(() => {
    resetSettingsForTesting()
  })

  it('filters zones by search query and resets cleanly on empty results', async () => {
    const wrapper = mount(ServiceZonesPage)

    expect(wrapper.text()).toContain('ZN-PAG-01')
    expect(wrapper.text()).toContain('ZN-PAG-04')

    await wrapper.find('input[aria-label="Search geofence zones"]').setValue('Bulatok')
    expect(wrapper.text()).toContain('ZN-PAG-02')
    expect(wrapper.text()).not.toContain('ZN-PAG-04')

    await wrapper.find('input[aria-label="Search geofence zones"]').setValue('Nonexistent Corridor')
    expect(wrapper.text()).toContain('No matching service zones')

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Reset'))!
      .trigger('click')
    expect(wrapper.text()).toContain('ZN-PAG-01')
  })

  it('creates a validated service zone and logs an audit event', async () => {
    const wrapper = mount(ServiceZonesPage)
    const { logs } = useAuditLogs()

    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('+ Create Zone'))!
      .trigger('click')

    expect(wrapper.find('[role="dialog"]').exists()).toBe(true)
    await wrapper.find('#zone-name').setValue('Balangasan Terminal Loop')
    await wrapper.find('#zone-barangays').setValue('Balangasan, Santa Maria')
    await wrapper.find('#zone-surge').setValue('3.5')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Service Zone'))!
      .trigger('click')

    expect(wrapper.find('[role="dialog"]').text()).toContain('must remain between 1.0x and 2.5x')

    await wrapper.find('#zone-surge').setValue('1.7')
    await wrapper
      .findAll('button')
      .find((b) => b.text().includes('Save Service Zone'))!
      .trigger('click')

    expect(wrapper.text()).toContain('Balangasan Terminal Loop')
    expect(logs.value[0]?.action).toBe('SERVICE_ZONE_CREATED')
  })
})
