import { readFile } from 'node:fs/promises';
import { expect, test, type Page } from '@playwright/test';
import { podrobGranice, podrobUdostepnianie, udostepnione } from './podrobki';

const przycisk = (page: Page, nazwa: string) => page.locator('#sesja').getByRole('button', { name: nazwa, exact: true });
const wpisy = (page: Page) => page.getByRole('list', { name: 'Historia' }).getByRole('listitem');

async function sesja(page: Page, przerwij: boolean) {
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await przycisk(page, 'Start').click();
	if (przerwij) {
		await przycisk(page, 'Pomiń').click();
		await przycisk(page, 'Pomiń').click();
		await przycisk(page, 'Przerwij').click();
	} else {
		while (await przycisk(page, 'Pomiń').isVisible()) await przycisk(page, 'Pomiń').click();
	}
	await przycisk(page, 'Wróć do listy').click();
}

test('dwie sesje → dwa wpisy po przeładowaniu, eksport z oboma, bez sieci na zewnątrz', async ({ page, baseURL }) => {
	const obce: string[] = [];
	page.on('request', (r) => {
		if (new URL(r.url()).origin !== new URL(baseURL!).origin) obce.push(r.url());
	});
	await podrobGranice(page, 1);
	await podrobUdostepnianie(page, true);
	await page.goto('');
	await expect(page.locator('#historia')).toBeHidden();
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await page.getByRole('button', { name: 'Wróć', exact: true }).click();
	await expect(page.locator('#historia')).toBeHidden();
	await sesja(page, false);
	await sesja(page, true);
	await page.reload();
	await expect(wpisy(page)).toHaveCount(2);
	await expect(wpisy(page).nth(0)).toContainText('Przerwana po 2 z 24 faz');
	await expect(wpisy(page).nth(1)).toContainText('Ukończona');
	await page.getByRole('button', { name: 'Eksportuj' }).click();
	await expect.poll(() => udostepnione(page)).toHaveLength(1);
	const [{ nazwa, tekst }] = await udostepnione(page);
	expect(nazwa).toBe('minutnik-historia.json');
	const plik = JSON.parse(tekst);
	expect(plik.map((w: { completed: boolean; phasesDone: number }) => [w.completed, w.phasesDone])).toEqual([[true, 24], [false, 2]]);
	expect(plik[0].startedAt).toMatch(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/);
	expect(obce).toEqual([]);
});

test('Przerwij z pytania zapisuje wpis, bez Web Share eksport pobiera plik', async ({ page }) => {
	await podrobGranice(page, 1);
	await podrobUdostepnianie(page, false);
	await page.goto('');
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await przycisk(page, 'Start').click();
	await page.getByRole('button', { name: 'Wróć', exact: true }).click();
	await page.getByRole('dialog', { name: 'Przerwać sesję?' }).getByRole('button', { name: 'Przerwij' }).click();
	await expect(wpisy(page)).toHaveText([/Przerwana po 0 z 24 faz/]);
	const [pobranie] = await Promise.all([page.waitForEvent('download'), page.getByRole('button', { name: 'Eksportuj' }).click()]);
	expect(pobranie.suggestedFilename()).toBe('minutnik-historia.json');
	expect(JSON.parse(await readFile((await pobranie.path())!, 'utf8'))).toHaveLength(1);
	expect(await udostepnione(page)).toEqual([]);
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
	await sesja(page, true);
	await expect(wpisy(page)).toHaveCount(1);
	expect(await page.evaluate(() => localStorage.getItem('minutnik.historia'))).toBe('[{"zepsute"');
});
