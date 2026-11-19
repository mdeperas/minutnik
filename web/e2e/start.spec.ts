import { expect, test } from '@playwright/test';

test('strona pokazuje Minutnik, dwa duże zestawy i wersję z datą wydania', async ({ page }) => {
	await page.goto('');
	await expect(page.getByRole('heading', { name: 'Minutnik' })).toBeVisible();
	const zestawy = page.getByRole('list', { name: 'Zestawy' }).getByRole('button');
	await expect(zestawy).toHaveCount(2);
	await expect(zestawy.nth(0)).toHaveAccessibleName(/^12 grup, \d+ min$/);
	await expect(zestawy.nth(1)).toHaveAccessibleName(/^8 grup, \d+ min$/);
	for (const zestaw of await zestawy.all()) {
		const ramka = (await zestaw.boundingBox())!;
		expect(ramka.height).toBeGreaterThanOrEqual(44);
		expect(ramka.width).toBeGreaterThanOrEqual(44);
	}
	await expect(page.locator('.wersja')).toHaveText(/^Wersja \S+ · (\d\d\.\d\d\.\d{4} \d\d:\d\d|dev)$/);
});
