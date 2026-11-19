import { expect, test } from '@playwright/test';
import { nagranie, podrobGranice } from './podrobki';

test('wybrana muzyka zostaje po ponownym starcie, gra w sesji, cichnie przy pauzie i wyciszeniu', async ({ page }) => {
	await podrobGranice(page, 1);
	await page.goto('');
	const wybor = page.getByRole('group', { name: 'Muzyka' });
	await expect(wybor.getByRole('button', { name: 'Bez' })).toHaveAttribute('aria-pressed', 'true');
	await wybor.getByRole('button', { name: 'Las' }).click();
	await page.reload();
	await expect(wybor.getByRole('button', { name: 'Las' })).toHaveAttribute('aria-pressed', 'true');
	await expect(wybor.getByRole('button', { name: 'Bez' })).toHaveAttribute('aria-pressed', 'false');

	await page.getByRole('button', { name: /^12 grup/ }).click();
	const sesja = page.locator('#sesja');
	await sesja.getByRole('button', { name: 'Start', exact: true }).click();
	expect((await nagranie(page)).muzyka).toEqual(['graj muzyka/las.m4a', 'glosnosc 0.3']);
	await sesja.getByRole('button', { name: 'Pauza', exact: true }).click();
	await sesja.getByRole('button', { name: 'Wznów', exact: true }).click();
	await sesja.getByRole('button', { name: 'Wycisz muzykę' }).click();
	await expect(sesja.getByRole('button', { name: 'Włącz muzykę' })).toHaveAttribute('aria-pressed', 'true');
	await sesja.getByRole('button', { name: 'Przerwij', exact: true }).click();
	await sesja.getByRole('button', { name: 'Wróć do listy', exact: true }).click();
	expect((await nagranie(page)).muzyka).toEqual(['graj muzyka/las.m4a', 'glosnosc 0.3', 'glosnosc 0', 'glosnosc 0.3', 'glosnosc 0', 'zatrzymaj']);
});

test('bez muzyki sesja nie gra muzyki i nie ma przycisku wyciszenia', async ({ page }) => {
	await podrobGranice(page, 1);
	await page.goto('');
	await page.getByRole('button', { name: /^12 grup/ }).click();
	const sesja = page.locator('#sesja');
	await sesja.getByRole('button', { name: 'Start', exact: true }).click();
	await expect(sesja.getByRole('button', { name: 'Wycisz muzykę' })).toBeHidden();
	expect((await nagranie(page)).muzyka).toEqual([]);
});

test('plik muzyki jest w buildzie, ale nie w precache', async ({ request }) => {
	const odpowiedz = await request.get('muzyka/synthwave.m4a');
	expect(odpowiedz.ok()).toBe(true);
	expect((await (await request.get('sw.js')).text())).not.toContain('synthwave.m4a');
});
