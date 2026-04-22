import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('should show login page', async ({ page }) => {
    await page.goto('/Identity/Account/Login');
    await expect(page.locator('#Login-Input-Email')).toBeVisible();
    await expect(page.locator('#Login-Input-Password')).toBeVisible();
    await expect(page.locator('#Login-Button-Submit')).toBeVisible();
    await expect(page.locator('#Login-Link-ForgotPassword')).toBeVisible();
    await expect(page.locator('#Login-Link-Register')).toBeVisible();
  });

  test('should show login link when unauthenticated', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('#LoginPartial-Link-Login')).toBeVisible();
  });

  test('should login as demo user', async ({ page }) => {
    await page.goto('/Identity/Account/Login');
    await page.locator('#Login-Input-Email').fill('demouser@microsoft.com');
    await page.locator('#Login-Input-Password').fill('Pass@word1');
    await page.locator('#Login-Button-Submit').click();
    await page.waitForLoadState('networkidle');
    await expect(page.locator('#LoginPartial-Link-Logout')).toBeVisible();
  });

  test('should login as admin user', async ({ page }) => {
    await page.goto('/Identity/Account/Login');
    await page.locator('#Login-Input-Email').fill('admin@microsoft.com');
    await page.locator('#Login-Input-Password').fill('Pass@word1');
    await page.locator('#Login-Button-Submit').click();
    await page.waitForLoadState('networkidle');
    await expect(page.locator('#LoginPartial-Link-Admin')).toBeVisible();
  });

  test('should logout', async ({ page }) => {
    await page.goto('/Identity/Account/Login');
    await page.locator('#Login-Input-Email').fill('demouser@microsoft.com');
    await page.locator('#Login-Input-Password').fill('Pass@word1');
    await page.locator('#Login-Button-Submit').click();
    await page.waitForLoadState('networkidle');
    await page.locator('#LoginPartial-Link-Logout').click();
    await page.waitForLoadState('networkidle');
    await expect(page.locator('#LoginPartial-Link-Login')).toBeVisible();
  });
});
