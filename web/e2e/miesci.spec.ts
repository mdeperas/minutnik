import { expect, test, type Page } from '@playwright/test';
import { podrobGranice } from './podrobki';

const ekrany = [
	{ width: 375, height: 667 },
	{ width: 393, height: 852 }
];

const bezPrzewijania = (page: Page) =>
	page.evaluate(() => ({ wysokosc: document.scrollingElement!.scrollHeight, okno: window.innerHeight }));

for (const rozmiar of ekrany) {
	test(`${rozmiar.width}×${rozmiar.height}: lista i sesja mieszczą się bez przewijania`, async ({ page }) => {
		await page.setViewportSize(rozmiar);
		await podrobGranice(page, 1);
		await page.goto('');
		let wymiary = await bezPrzewijania(page);
		expect(wymiary.wysokosc).toBeLessThanOrEqual(wymiary.okno);
		await page.getByRole('button', { name: /^12 grup/ }).click();
		const sesja = page.locator('#sesja');
		for (const akcja of ['Start', 'Pomiń', 'Pomiń']) {
			await sesja.getByRole('button', { name: akcja, exact: true }).click();
			wymiary = await bezPrzewijania(page);
			expect(wymiary.wysokosc).toBeLessThanOrEqual(wymiary.okno);
			const dol = await sesja.getByRole('button', { name: 'Pomiń', exact: true }).boundingBox();
			expect(dol!.y + dol!.height).toBeLessThanOrEqual(rozmiar.height);
			const pierscien = await sesja.locator('.pierscien').boundingBox();
			expect(pierscien!.height).toBeGreaterThan(100);
		}
	});
}

test('375×667: sesja z historią po powrocie na listę też się mieści', async ({ page }) => {
	await page.setViewportSize(ekrany[0]);
	await podrobGranice(page, 1);
	await page.goto('');
	for (let i = 0; i < 6; i++) {
		await page.getByRole('button', { name: /^12 grup/ }).click();
		await page.locator('#sesja').getByRole('button', { name: 'Start', exact: true }).click();
		await page.locator('#sesja').getByRole('button', { name: 'Przerwij', exact: true }).click();
		await page.locator('#sesja').getByRole('button', { name: 'Wróć do listy', exact: true }).click();
	}
	await expect(page.locator('#historia')).toBeVisible();
	const wymiary = await bezPrzewijania(page);
	expect(wymiary.wysokosc).toBeLessThanOrEqual(wymiary.okno);
});
