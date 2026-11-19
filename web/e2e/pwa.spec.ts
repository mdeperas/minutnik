import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { createServer, type Server } from 'node:http';
import { extname, join, normalize } from 'node:path';
import { expect, test, type Page } from '@playwright/test';
import { podrobGranice } from './podrobki';

const przycisk = (page: Page, nazwa: string) => page.locator('#sesja').getByRole('button', { name: nazwa, exact: true });
const typy: Record<string, string> = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.png': 'image/png', '.webmanifest': 'application/manifest+json' };

const czekajNaKontroler = (page: Page) => page.waitForFunction(() => navigator.serviceWorker.controller !== null);

function serwer(katalog: { biezacy: string }) {
	return createServer(async (zadanie, odpowiedz) => {
		const sciezka = decodeURIComponent(new URL(zadanie.url!, 'http://x').pathname).replace(/^\/minutnik\//, '');
		const plik = normalize(join(katalog.biezacy, sciezka === '' ? 'index.html' : sciezka));
		try {
			const tresc = await readFile(plik);
			odpowiedz.writeHead(200, { 'content-type': typy[extname(plik)] ?? 'application/octet-stream', 'cache-control': 'no-cache' });
			odpowiedz.end(tresc);
		} catch {
			odpowiedz.writeHead(404).end();
		}
	});
}

test('po pierwszym wejściu strona działa offline, w Safari podpowiada instalację', async ({ page, context }) => {
	await page.goto('');
	await expect(page.getByText('Udostępnij → Dodaj do ekranu początkowego', { exact: false })).toBeVisible();
	await czekajNaKontroler(page);
	await context.setOffline(true);
	await page.reload();
	await expect(page.getByRole('button', { name: /^12 grup/ })).toBeVisible();
	await page.getByRole('button', { name: /^12 grup/ }).click();
	await expect(przycisk(page, 'Start')).toBeVisible();
});

test.describe('aktualizacja', () => {
	const katalog = { biezacy: 'dist' };
	const nowa = join('test-results', 'pwa-nowa-wersja');
	let http: Server;

	test.beforeAll(() => {
		execFileSync('npx', ['vite', 'build', '--outDir', nowa, '--emptyOutDir', '--logLevel', 'error'], { env: { ...process.env, MINUTNIK_WERSJA: 'nowa' } });
		http = serwer(katalog).listen(4174);
	});
	test.afterAll(() => void http.close());

	test('nowa wersja nie przerywa sesji i wchodzi sama po jej końcu', async ({ page }) => {
		await podrobGranice(page, 1);
		await page.goto('http://localhost:4174/minutnik/');
		await czekajNaKontroler(page);
		await expect(page.getByText(/^Wersja /)).not.toHaveText('Wersja nowa');
		await page.getByRole('button', { name: /^12 grup/ }).click();
		await przycisk(page, 'Start').click();
		await page.evaluate(() => Object.assign(window, { __przedAktualizacja: true }));

		katalog.biezacy = nowa;
		await page.evaluate(async () => (await navigator.serviceWorker.getRegistration())!.update());
		await page.waitForFunction(async () => (await caches.keys()).every((k) => k.startsWith('minutnik-nowa-')));
		expect(await page.evaluate(() => (window as unknown as { __przedAktualizacja?: boolean }).__przedAktualizacja)).toBe(true);
		await expect(przycisk(page, 'Pauza')).toBeVisible();

		await przycisk(page, 'Przerwij').click();
		await przycisk(page, 'Wróć do listy').click();
		await expect(page.getByText('Wersja nowa')).toBeVisible();
		expect(await page.evaluate(() => (window as unknown as { __przedAktualizacja?: boolean }).__przedAktualizacja)).toBeUndefined();
	});
});
