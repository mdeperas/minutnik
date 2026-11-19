import { expect, test, type Page } from '@playwright/test';
import { podrobGranice } from './podrobki';

const faza = (page: Page) => page.locator('#sesja .faza');
const grupa = (page: Page) => page.locator('#sesja .grupa');
const przycisk = (page: Page, nazwa: string) => page.locator('#sesja').getByRole('button', { name: nazwa, exact: true });

async function otworz(page: Page, tempo: number) {
	await podrobGranice(page, tempo);
	await page.goto('');
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await expect(przycisk(page, 'Start')).toBeVisible();
}

test('sesja: Start, Pauza, Pomiń, Wznów, sama kolejna faza i koniec', async ({ page }) => {
	await otworz(page, 1);
	const pierwszaGrupa = await grupa(page).textContent();
	await expect(faza(page)).toHaveText('Napinanie');
	await przycisk(page, 'Start').click();
	await przycisk(page, 'Pauza').click();
	const zamrozone = await page.locator('#sesja .cyfry').textContent();
	await page.waitForTimeout(1200);
	await expect(page.locator('#sesja .cyfry')).toHaveText(zamrozone!);
	await expect(przycisk(page, 'Wznów')).toBeVisible();
	await przycisk(page, 'Pomiń').click();
	await expect(faza(page)).toHaveText('Rozluźnienie');
	await expect(page.locator('#sesja')).toHaveAttribute('data-faza', 'rozluznienie');
	await expect(przycisk(page, 'Pauza')).toBeVisible();
	await przycisk(page, 'Pauza').click();
	await przycisk(page, 'Wznów').click();
	await przycisk(page, 'Pomiń').click();
	await expect(faza(page)).toHaveText('Napinanie');
	await expect(grupa(page)).not.toHaveText(pierwszaGrupa!);
	await expect(page.locator('#sesja .pozycja')).toHaveText('Grupa 2 z 12');
	while (await przycisk(page, 'Pomiń').isVisible()) await przycisk(page, 'Pomiń').click();
	await expect(page.locator('#sesja .cyfry')).toHaveText('Koniec');
	await przycisk(page, 'Wróć do listy').click();
	await expect(page.getByRole('list', { name: 'Zestawy' })).toBeVisible();
});

test('sesja z przyspieszonym zegarem sama przechodzi do rozluźnienia', async ({ page }) => {
	await otworz(page, 40);
	await przycisk(page, 'Start').click();
	await expect(faza(page)).toHaveText('Rozluźnienie');
	await expect(page.locator('#sesja .pozycja')).toHaveText('Grupa 1 z 12');
});

test('przyspieszony zegar sam dochodzi do końca sesji', async ({ page }) => {
	await otworz(page, 3000);
	await przycisk(page, 'Start').click();
	await expect(page.locator('#sesja .cyfry')).toHaveText('Koniec');
});

test('Wróć przed startem wraca do listy bez pytania', async ({ page }) => {
	await otworz(page, 1);
	await page.getByRole('button', { name: 'Wróć', exact: true }).click();
	await expect(page.getByRole('list', { name: 'Zestawy' })).toBeVisible();
	await expect(page.getByRole('dialog')).toBeHidden();
});

test('Wróć pyta „Przerwać sesję?”: Ćwiczę dalej zostaje, Przerwij wraca do listy', async ({ page }) => {
	await otworz(page, 1);
	await przycisk(page, 'Start').click();
	await page.getByRole('button', { name: 'Wróć', exact: true }).click();
	const pytanie = page.getByRole('dialog', { name: 'Przerwać sesję?' });
	await expect(pytanie).toBeVisible();
	await pytanie.getByRole('button', { name: 'Ćwiczę dalej' }).click();
	await expect(pytanie).toBeHidden();
	await expect(przycisk(page, 'Pauza')).toBeVisible();
	await page.getByRole('button', { name: 'Wróć', exact: true }).click();
	await pytanie.getByRole('button', { name: 'Przerwij' }).click();
	await expect(page.getByRole('list', { name: 'Zestawy' })).toBeVisible();
	await expect(page.locator('#sesja')).toBeHidden();
});

test('Przerwij w sesji kończy ją bez pytania', async ({ page }) => {
	await otworz(page, 1);
	await przycisk(page, 'Start').click();
	await przycisk(page, 'Przerwij').click();
	await expect(page.locator('#sesja .cyfry')).toHaveText('Przerwano');
	await expect(przycisk(page, 'Wróć do listy')).toBeVisible();
});

test('zrzut sesji w napinaniu', async ({ page }) => {
	await otworz(page, 1);
	await przycisk(page, 'Start').click();
	await page.waitForTimeout(6000);
	await przycisk(page, 'Pauza').click();
	await page.screenshot({ path: '/tmp/minutnik-wyglad/pwa-sesja.png', fullPage: true });
});

test('z prefers-reduced-motion pierścień nie zmienia skali', async ({ page }) => {
	await page.emulateMedia({ reducedMotion: 'reduce' });
	await otworz(page, 20);
	await przycisk(page, 'Start').click();
	await page.waitForTimeout(150);
	await expect(page.locator('#sesja .pierscien svg')).toHaveCSS('transform', 'none');
	await expect(page.locator('#sesja .pierscien svg')).toHaveAttribute('style', /--skala: 1;/);
});

test('rycina grupy zmienia stan razem z fazą', async ({ page }) => {
	await otworz(page, 1);
	const rycina = page.locator('#sesja .rycina');
	await expect(rycina).toHaveAttribute('data-plik', /-napiecie\.svg$/);
	await expect(rycina.locator('.wyroznienie').first()).toBeVisible();
	const pierwsza = (await rycina.getAttribute('data-plik'))!;
	await przycisk(page, 'Start').click();
	await przycisk(page, 'Pomiń').click();
	await expect(faza(page)).toHaveText('Rozluźnienie');
	await expect(rycina).toHaveAttribute('data-plik', pierwsza.replace('-napiecie', '-rozluznienie'));
	await przycisk(page, 'Pomiń').click();
	await expect(rycina).toHaveAttribute('data-plik', /-napiecie\.svg$/);
	await expect(rycina).not.toHaveAttribute('data-plik', pierwsza);
});

test('ostatnie 3 sekundy fazy tykają: trzy tiki przed rozluźnieniem', async ({ page }) => {
	await otworz(page, 4);
	await przycisk(page, 'Start').click();
	await expect(faza(page)).toHaveText('Rozluźnienie');
	const { sygnaly } = await page.evaluate(() => (window as unknown as { __nagranie: { sygnaly: string[] } }).__nagranie);
	expect(sygnaly.slice(0, 5)).toEqual(['napinanie', 'odliczanie', 'odliczanie', 'odliczanie', 'rozluznienie']);
});
