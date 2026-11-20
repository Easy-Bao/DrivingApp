import { describe, expect, it } from 'vitest'
import { useToast } from '@/shared'

describe('useToast', () => {
  it('sets, overrides tone, and dismisses toast messages', () => {
    const { message, tone, showToast, dismissToast } = useToast('success')

    expect(message.value).toBeNull()
    expect(tone.value).toBe('success')

    showToast('Saved record')
    expect(message.value).toBe('Saved record')
    expect(tone.value).toBe('success')

    showToast('Validation failed', 'error')
    expect(message.value).toBe('Validation failed')
    expect(tone.value).toBe('error')

    dismissToast()
    expect(message.value).toBeNull()
  })
})
