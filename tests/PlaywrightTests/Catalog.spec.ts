import { test, expect } from '@playwright/test';

test.describe('Shop Homepage', () => {
  test('should load the catalog page', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/Catalog/);
  });

  test('should display product filter dropdowns', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('#Index-Select-BrandFilter')).toBeVisible();
    await expect(page.locator('#Index-Select-TypeFilter')).toBeVisible();
    await expect(page.locator('#Index-Button-ApplyFilter')).toBeVisible();
  });

  test('should filter products by brand', async ({ page }) => {
    await page.goto('/');
    const brandFilter = page.locator('#Index-Select-BrandFilter');
    await brandFilter.selectOption({ index: 1 });
    await page.locator('#Index-Button-ApplyFilter').click();
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/brandId=/);
  });

  test('should show navigation pagination', async ({ page }) => {
    await page.goto('/');
    const prevTop = page.locator('#PaginationTop-Link-Previous');
    const nextTop = page.locator('#PaginationTop-Link-Next');
    await expect(prevTop).toBeVisible();
    await expect(nextTop).toBeVisible();
  });
});
