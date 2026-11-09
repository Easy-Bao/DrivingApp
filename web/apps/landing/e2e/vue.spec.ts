import { expect, test } from '@playwright/test'

test('visits the landing home root url', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('h1')).toHaveText(
    'Transparent Ride Dispatch & Fair Driver Bidding',
  )
})
