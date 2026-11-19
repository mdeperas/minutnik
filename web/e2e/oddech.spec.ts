import { expect, test, type Page } from '@playwright/test';
import { nagranie, podrobGranice } from './podrobki';

const przycisk = (page: Page, nazwa: string) => page.locator('#sesja').getByRole('button', { name: nazwa, exact: true });

test('rozluźnienie: oddychające kółko 4-3-2-1, pierścień i duży zegar fazy i wibracje co 4 s', async ({ page }) => {
	await podrobGranice(page, 4);
	await page.goto('');
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await przycisk(page, 'Start').click();
	await expect(page.locator('#sesja .oddech')).toBeHidden();
	await przycisk(page, 'Pomiń').click();
	const oddech = page.locator('#sesja .oddech');
	await expect(oddech).toBeVisible();
	await expect(page.locator('#sesja .oddech-faza')).toHaveText('Rozluźnienie');
	await expect(page.locator('#sesja .oddech-zostalo')).toHaveText(/^0:\d\d$/);
	await expect(page.locator('#sesja .faza')).toBeHidden();
	await expect(page.locator('#sesja .cyfry')).toHaveText(/^[1-4]$/);
	await expect(page.locator('#sesja .oddech-etap')).toHaveText('Wdech');
	await expect(page.locator('#sesja .oddech-etap')).toHaveText('Trzymaj');
	await expect(page.locator('#sesja .oddech-etap')).toHaveText('Wydech');
	const ubylo = Number(await page.locator('#sesja .postep').evaluate((c) => (c as SVGElement).style.strokeDashoffset));
	expect(ubylo).toBeGreaterThan(0.1);
	expect(ubylo).toBeLessThan(0.35);
	const n = await nagranie(page);
	expect(n.wibracje[0]).toBe('zmiana');
	expect(n.wibracje.filter((w) => w === 'tik').length).toBeGreaterThanOrEqual(2);
});

test('stuknięcie w rycinę powiększa ją, drugie zwija', async ({ page }) => {
	await podrobGranice(page, 1);
	await page.goto('');
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await przycisk(page, 'Start').click();
	const rycina = page.locator('#sesja .rycina');
	await rycina.click();
	await expect(rycina).toHaveClass(/powiekszona/);
	await expect(page.locator('#sesja .zaslona')).toHaveClass(/widac/);
	await page.waitForTimeout(700);
	await page.locator('#sesja .zaslona').click({ force: true });
	await expect(rycina).not.toHaveClass(/powiekszona/);
});
