import { expect, test, type Page } from '@playwright/test';
import { podrobGranice } from './podrobki';

const ekrany = [
	{ width: 375, height: 667 },
	{ width: 393, height: 852 }
];

const bezPrzewijania = (page: Page) =>
	page.evaluate(() => ({ wysokosc: document.scrollingElement!.scrollHeight, okno: window.innerHeight }));

for (const rozmiar of ekrany) {
	test(`${rozmiar.width}×${rozmiar.height}: ekran startowy i sesja mieszczą się bez przewijania`, async ({ page }) => {
		await page.setViewportSize(rozmiar);
		await podrobGranice(page, 1);
		await page.goto('');
		let wymiary = await bezPrzewijania(page);
		expect(wymiary.wysokosc).toBeLessThanOrEqual(wymiary.okno);
		await page.getByRole('button', { name: /^12 grup/ }).click();
		const sesja = page.locator('#sesja');
		await expect(sesja.locator('.opis dt').first()).toHaveText('Jak');
		for (const [krok, akcja] of ['Start', 'Pomiń', 'Pomiń'].entries()) {
			await sesja.getByRole('button', { name: akcja, exact: true }).click();
			wymiary = await bezPrzewijania(page);
			expect(wymiary.wysokosc).toBeLessThanOrEqual(wymiary.okno);
			const dol = await sesja.getByRole('button', { name: 'Pomiń', exact: true }).boundingBox();
			expect(dol!.y + dol!.height).toBeLessThanOrEqual(rozmiar.height);
			const pierscien = await sesja.locator('.pierscien').boundingBox();
			expect(pierscien!.height).toBeGreaterThan(100);
			const zrzuty = process.env.MINUTNIK_ZRZUTY;
			if (zrzuty && rozmiar.width === 393 && krok < 2) {
				const nazwa = (await sesja.getAttribute('data-oddech')) === 'true' ? 'rozluznienie' : 'napinanie';
				await page.waitForTimeout(700);
				await page.screenshot({ path: `${zrzuty}/minutnik-porownanie-${nazwa}-pwa.png` });
			}
		}
	});
}

test('393×852: zrzut ekranu startowego', async ({ page }) => {
	await page.setViewportSize(ekrany[1]);
	await page.goto('');
	await expect(page.getByRole('list', { name: 'Zestawy' }).getByRole('button')).toHaveCount(2);
	await page.screenshot({ path: process.env.MINUTNIK_ZRZUT ?? 'test-results/minutnik-start.png' });
});
