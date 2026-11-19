import { expect, test, type Page } from '@playwright/test';
import { nagranie, podrobGranice, ustawWidocznosc } from './podrobki';

const sesja = (page: Page) => page.locator('#sesja');
const przycisk = (page: Page, nazwa: string) => sesja(page).getByRole('button', { name: nazwa, exact: true });

async function otworz(page: Page, tempo: number, wakeLockDostepny = true) {
	await podrobGranice(page, tempo, wakeLockDostepny);
	await page.goto('');
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await expect(przycisk(page, 'Start')).toBeVisible();
}

test('ukrycie strony na 3 fazy: po powrocie właściwa faza, jeden sygnał i ponowny wake lock', async ({ page }) => {
	await otworz(page, 50);
	await page.evaluate(() => {
		document.querySelector<HTMLButtonElement>('#sesja [data-akcja="start"]')!.click();
		document.querySelector<HTMLButtonElement>('#sesja [data-akcja="pomin"]')!.click();
		(window as unknown as { __widocznosc: { widoczna: boolean } }).__widocznosc.widoczna = false;
		document.dispatchEvent(new Event('visibilitychange'));
	});
	await page.waitForTimeout(1800);
	const wTle = await nagranie(page);
	expect(wTle.sygnaly).toEqual(['rozluznienie', 'napinanie']);
	expect(wTle.odblokowania).toBe(1);
	expect(wTle.trzymania).toBe(1);
	await expect(sesja(page).locator('.pozycja')).toHaveText('Grupa 1 z 12');
	await ustawWidocznosc(page, true);
	await expect(sesja(page).locator('.faza')).toHaveText('Rozluźnienie');
	await expect(sesja(page).locator('.pozycja')).toHaveText('Grupa 2 z 12');
	const poPowrocie = await nagranie(page);
	expect(poPowrocie.sygnaly).toEqual(['rozluznienie', 'napinanie', 'rozluznienie']);
	expect(poPowrocie.trzymania).toBe(2);
	await expect(sesja(page).locator('.uwaga-ekran')).toBeHidden();
});

test('ekran trzymany od Startu do Przerwij, Pomiń gra sygnał, koniec gra sygnał końca', async ({ page }) => {
	await otworz(page, 1);
	await przycisk(page, 'Start').click();
	await przycisk(page, 'Pauza').click();
	await przycisk(page, 'Pomiń').click();
	expect(await nagranie(page)).toMatchObject({ sygnaly: ['rozluznienie', 'napinanie'], trzymania: 1, puszczenia: 0 });
	await przycisk(page, 'Przerwij').click();
	expect(await nagranie(page)).toMatchObject({ sygnaly: ['rozluznienie', 'napinanie'], puszczenia: 1 });
});

test('naturalny koniec sesji: sygnał końca i ekran puszczony', async ({ page }) => {
	await otworz(page, 3000);
	await przycisk(page, 'Start').click();
	await expect(sesja(page).locator('.cyfry')).toHaveText('Koniec');
	const n = await nagranie(page);
	expect(n.sygnaly.at(-1)).toBe('koniec');
	expect(n.puszczenia).toBe(1);
});

test('bez Wake Lock łagodny komunikat, sesja trwa dalej', async ({ page }) => {
	await otworz(page, 1, false);
	await przycisk(page, 'Start').click();
	await expect(sesja(page).getByRole('status')).toHaveText('Ekran może zgasnąć w trakcie sesji.');
	await expect(przycisk(page, 'Pauza')).toBeVisible();
});
