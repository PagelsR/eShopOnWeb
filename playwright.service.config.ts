import { defineConfig } from '@playwright/test';
import config from './playwright.config';

// Azure Playwright Testing service configuration
// Used when running tests via Microsoft Playwright Testing service
export default defineConfig(config, {
  use: {
    connectOptions: {
      wsEndpoint: process.env.PLAYWRIGHT_SERVICE_URL ?? '',
    },
  },
  workers: process.env.CI ? 20 : undefined,
});
