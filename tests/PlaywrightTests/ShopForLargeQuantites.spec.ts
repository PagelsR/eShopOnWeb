import { test, expect } from '@playwright/test';

test.describe('Shop For Large Quantities', () => {
  test('should add multiple items and update quantities', async ({ page }) => {
    // Login first
    await page.goto('/Identity/Account/Login');
    await page.locator('#Login-Input-Email').fill('demouser@microsoft.com');
    await page.locator('#Login-Input-Password').fill('Pass@word1');
    await page.locator('#Login-Button-Submit').click();
    await page.waitForLoadState('networkidle');

    // Verify login via logout link (fixed ID: was #Header-Link-Login)
    await expect(page.locator('#LoginPartial-Link-Logout')).toBeVisible();

    // Add items to basket
    await page.goto('/');
    await page.locator('[id^="Product-Button-AddToBasket-"]').first().click();
    await page.waitForLoadState('networkidle');

    // Update quantity
    const quantityInput = page.locator('[id^="BasketIndex-Input-Quantity-"]').first();
    await quantityInput.fill('5');
    await page.locator('#BasketIndex-Button-Update').click();
    await page.waitForLoadState('networkidle');

    await expect(page.locator('#basket-total')).toBeVisible();

    // Logout (fixed ID: was #Header-Link-Logout)
    await page.locator('#LoginPartial-Link-Logout').click();
    await page.waitForLoadState('networkidle');
    await expect(page.locator('#LoginPartial-Link-Login')).toBeVisible();
  });
});
