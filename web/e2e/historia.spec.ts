import { expect, test, type Page } from '@playwright/test';
import { podrobGranice } from './podrobki';

const przycisk = (page: Page, nazwa: string) => page.locator('#sesja').getByRole('button', { name: nazwa, exact: true });

test('historii nie ma w UI, a zapis w telefonie zostaje i rośnie', async ({ page }) => {
	await page.addInitScript(() => {
		if (!sessionStorage.getItem('zasiane')) {
			localStorage.setItem('minutnik.historia', '[]');
			sessionStorage.setItem('zasiane', '1');
		}
	});
	await podrobGranice(page, 1);
	await page.goto('');
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await przycisk(page, 'Start').click();
	await przycisk(page, 'Przerwij').click();
	await przycisk(page, 'Wróć do listy').click();
	await expect(page.getByText('Historia')).toHaveCount(0);
	await expect(page.getByRole('button', { name: 'Eksportuj' })).toHaveCount(0);
	await page.reload();
	await expect(page.getByText('Historia')).toHaveCount(0);
	const zapis = JSON.parse((await page.evaluate(() => localStorage.getItem('minutnik.historia')))!);
	expect(zapis).toHaveLength(1);
});

test('uszkodzony zapis historii zostaje nietknięty po sesji', async ({ page }) => {
	await page.addInitScript(() => {
		if (!sessionStorage.getItem('zasiane')) {
			localStorage.setItem('minutnik.historia', '[{"zepsute"');
			sessionStorage.setItem('zasiane', '1');
		}
	});
	await podrobGranice(page, 1);
	await page.goto('');
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await przycisk(page, 'Start').click();
	await przycisk(page, 'Przerwij').click();
	await przycisk(page, 'Wróć do listy').click();
	expect(await page.evaluate(() => localStorage.getItem('minutnik.historia'))).toBe('[{"zepsute"');
});
