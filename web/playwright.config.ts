import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
	testDir: 'e2e',
	globalTimeout: 5 * 60_000,
	use: { baseURL: 'http://localhost:4173/minutnik/' },
	projects: [{ name: 'iphone', use: { ...devices['iPhone 15'], browserName: 'webkit' } }],
	webServer: { command: 'npm run build && npx vite preview --port 4173 --strictPort', url: 'http://localhost:4173/minutnik/', reuseExistingServer: false }
});
