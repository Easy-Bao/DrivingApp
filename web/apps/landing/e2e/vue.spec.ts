import { expect, test } from '@playwright/test'

test('visits the landing home root url and navigates to drive page', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('h1')).toHaveText(
    'Pagadian Taxicles, priced upfront before you step in.',
  )

  await page.getByRole('link', { name: 'Drive & Earn', exact: true }).click()
  await expect(page).toHaveURL(/\/drive$/)
  await expect(page.locator('h1')).toContainText('10%')
})
