import { expect, test, type Page } from '@playwright/test';

const dokument = (page: Page) =>
	page.evaluate(() => ({ wysokosc: document.scrollingElement!.scrollHeight, okno: window.innerHeight }));

test('„O ćwiczeniu”: start bez przewijania, tekst przewija się tylko we własnym ekranie, Wróć wraca', async ({ page }) => {
	await page.setViewportSize({ width: 393, height: 852 });
	await page.goto('');
	const otworz = page.getByRole('button', { name: 'O ćwiczeniu ›' });
	await expect(otworz).toBeVisible();
	let wymiary = await dokument(page);
	expect(wymiary.wysokosc).toBeLessThanOrEqual(wymiary.okno);

	await otworz.click();
	const ekran = page.locator('#o-cwiczeniu');
	await expect(ekran.getByRole('heading', { level: 1, name: 'O ćwiczeniu' })).toBeVisible();
	expect(await ekran.getByRole('heading', { level: 2 }).count()).toBeGreaterThanOrEqual(5);
	await expect(ekran.locator('.zrodlo')).toContainText('Ponad lękiem');
	await expect(page.locator('#lista-ekran')).toBeHidden();
	await page.screenshot({ path: process.env.MINUTNIK_ZRZUT_CZYTANIA ?? 'test-results/minutnik-o-cwiczeniu.png' });

	wymiary = await dokument(page);
	expect(wymiary.wysokosc).toBeLessThanOrEqual(wymiary.okno);
	expect(await ekran.evaluate((e) => getComputedStyle(e).overflowY)).toBe('auto');
	await ekran.getByRole('button', { name: 'Wróć do listy' }).scrollIntoViewIfNeeded();
	await expect.poll(() => ekran.evaluate((e) => e.scrollTop)).toBeGreaterThan(0);
	await expect(ekran.getByRole('button', { name: 'Wróć do listy' })).toBeInViewport();
	await expect(ekran.getByRole('button', { name: 'Wróć', exact: true })).toBeInViewport();

	await ekran.getByRole('button', { name: 'Wróć do listy' }).click();
	await expect(page.locator('#lista-ekran')).toBeVisible();
	await expect(otworz).toBeFocused();

	await otworz.click();
	await expect(ekran).toBeVisible();
	expect(await ekran.evaluate((e) => e.scrollTop)).toBe(0);
	await ekran.getByRole('button', { name: 'Wróć', exact: true }).click();
	await expect(ekran).toBeHidden();
	wymiary = await dokument(page);
	expect(wymiary.wysokosc).toBeLessThanOrEqual(wymiary.okno);
});
