import { test, expect } from '@playwright/test';

test.describe('Basket', () => {
  test('should add item to basket', async ({ page }) => {
    await page.goto('/');
    const addButton = page.locator('[id^="Product-Button-AddToBasket-"]').first();
    await addButton.click();
    await expect(page).toHaveURL(/Basket/);
  });

  test('should show basket controls', async ({ page }) => {
    await page.goto('/');
    await page.locator('[id^="Product-Button-AddToBasket-"]').first().click();
    await expect(page.locator('#basket-total')).toBeVisible();
    await expect(page.locator('#BasketIndex-Link-ContinueShopping')).toBeVisible();
    await expect(page.locator('#BasketIndex-Button-Update')).toBeVisible();
    await expect(page.locator('#BasketIndex-Link-Checkout')).toBeVisible();
  });

  test('continue shopping returns to catalog', async ({ page }) => {
    await page.goto('/');
    await page.locator('[id^="Product-Button-AddToBasket-"]').first().click();
    await page.locator('#BasketIndex-Link-ContinueShopping').click();
    await expect(page).toHaveURL('/');
  });
});
