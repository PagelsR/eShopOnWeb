import { test, expect } from '@playwright/test';

const DEMO_USER = 'demouser@microsoft.com';
const DEMO_PASSWORD = 'Pass@word1';

test.describe('eShopOnWeb - Checkout Flow', () => {
  test('browse catalog, add item to basket, increase quantity to 3, login, and checkout', async ({ page }) => {

    // ── 1. Navigate to catalog ───────────────────────────────────────────────
    await page.goto('/');
    await expect(page).toHaveTitle(/Catalog/);

    // ── 2. Browse – filter products by brand ─────────────────────────────────
    await page.getByRole('combobox', { name: 'brand' }).selectOption('.NET');
    await page.getByRole('button', { name: 'Submit' }).click();

    // Verify filtered results are visible
    const addButtons = page.getByRole('button', { name: '[ ADD TO BASKET ]' });
    await expect(addButtons.first()).toBeVisible();

    // ── 3. Add the first product to the basket ────────────────────────────────
    await addButtons.first().click();

    // Posting to /Basket/Index redirects back to the basket page
    await expect(page).toHaveURL(/\/Basket/);
    await expect(page).toHaveTitle(/Basket/);

    // ── 4. Increase quantity to 3 ─────────────────────────────────────────────
    const quantityInput = page.locator('input[type="number"].esh-basket-input').first();
    await expect(quantityInput).toBeVisible();
    await quantityInput.fill('3');

    // ── 5. Save quantity – click Update ───────────────────────────────────────
    await page.locator('#BasketIndex-Button-Update').click();

    // Confirm the quantity was persisted
    await expect(page.locator('input[type="number"].esh-basket-input').first()).toHaveValue('3');

    // ── 6. Proceed to checkout (unauthenticated → redirected to login) ────────
    await page.locator('#BasketIndex-Link-Checkout').click();
    await expect(page).toHaveURL(/Login/);
    await expect(page).toHaveTitle(/Log in/);

    // ── 7. Login with demo credentials ───────────────────────────────────────
    await page.locator('#Input_Email').fill(DEMO_USER);
    await page.locator('#Input_Password').fill(DEMO_PASSWORD);
    await page.getByRole('button', { name: 'Log in' }).click();

    // ── 8. Verify checkout review page ───────────────────────────────────────
    await expect(page).toHaveURL(/Basket\/Checkout/);
    await expect(page).toHaveTitle(/Checkout/);
    await expect(page.getByRole('heading', { name: 'Review' })).toBeVisible();

    // Verify at least one item row is present in the order summary
    await expect(page.locator('.esh-basket-items').first()).toBeVisible();

    // ── 9. Pay Now ────────────────────────────────────────────────────────────
    await page.locator('#Checkout-Button-PayNow').click();

    // ── 10. Verify order success ──────────────────────────────────────────────
    await expect(page).toHaveURL(/Basket\/Success/);
    await expect(page.getByRole('heading', { name: 'Thanks for your Order!' })).toBeVisible();

    // Basket counter should be back to 0
    await expect(page.locator('.esh-basketstatus-badge')).toHaveText('0');
  });
});
