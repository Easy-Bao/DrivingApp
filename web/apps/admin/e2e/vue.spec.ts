import { expect, test } from '@playwright/test'

test('visits the administration dashboard root url', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('h1')).toHaveText('Administration Operations Center')
})
