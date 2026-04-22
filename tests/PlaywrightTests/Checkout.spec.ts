import { test, expect } from '@playwright/test';

test.describe('Checkout Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Login and add item to basket
    await page.goto('/Identity/Account/Login');
    await page.locator('#Login-Input-Email').fill('demouser@microsoft.com');
    await page.locator('#Login-Input-Password').fill('Pass@word1');
    await page.locator('#Login-Button-Submit').click();
    await page.waitForLoadState('networkidle');
    await page.goto('/');
    await page.locator('[id^="Product-Button-AddToBasket-"]').first().click();
  });

  test('should navigate to checkout', async ({ page }) => {
    await page.locator('#BasketIndex-Link-Checkout').click();
    await expect(page).toHaveURL(/Checkout/);
    await expect(page.locator('#Checkout-Link-Back')).toBeVisible();
    await expect(page.locator('#Checkout-Button-PayNow')).toBeVisible();
  });

  test('should complete checkout and show success', async ({ page }) => {
    await page.locator('#BasketIndex-Link-Checkout').click();
    await page.locator('#Checkout-Button-PayNow').click();
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/Success/);
    await expect(page.locator('#Success-Link-ContinueShopping')).toBeVisible();
  });
});
