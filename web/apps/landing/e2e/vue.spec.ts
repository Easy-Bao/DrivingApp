import { expect, test } from '@playwright/test'

test('visits the landing home root url and navigates to drive page', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('h1')).toHaveText('Pagadian Rides.')

  await page.getByRole('link', { name: 'Drive', exact: true }).click()
  await expect(page).toHaveURL(/\/drive$/)
  await expect(page.locator('h1')).toHaveText('Drive EasyRide')
})
