import type { Page } from '@playwright/test';

export interface Nagranie {
	sygnaly: string[];
	odblokowania: number;
	trzymania: number;
	puszczenia: number;
	wibracje: string[];
}

export async function podrobGranice(page: Page, tempo: number, wakeLockDostepny = true) {
	await page.addInitScript(
		({ tempo, wakeLockDostepny }) => {
			const nagranie = { sygnaly: [] as string[], odblokowania: 0, trzymania: 0, puszczenia: 0, wibracje: [] as string[] };
			const stan = { widoczna: true };
			Object.assign(window, { __nagranie: nagranie, __widocznosc: stan });
			window.__minutnikPodrobki = {
				tempo,
				widoczna: () => stan.widoczna,
				dzwiek: {
					odblokuj: () => void nagranie.odblokowania++,
					zagraj: (sygnal) => void nagranie.sygnaly.push(sygnal)
				},
				wibracje: { wibruj: (rodzaj) => void nagranie.wibracje.push(rodzaj) },
				ekran: {
					trzymaj: async () => (nagranie.trzymania++, wakeLockDostepny),
					pusc: () => void nagranie.puszczenia++
				}
			};
		},
		{ tempo, wakeLockDostepny }
	);
}

export const nagranie = (page: Page) => page.evaluate(() => (window as unknown as { __nagranie: Nagranie }).__nagranie);

export const ustawWidocznosc = (page: Page, widoczna: boolean) =>
	page.evaluate((widoczna) => {
		(window as unknown as { __widocznosc: { widoczna: boolean } }).__widocznosc.widoczna = widoczna;
		document.dispatchEvent(new Event('visibilitychange'));
	}, widoczna);

export async function podrobUdostepnianie(page: Page, dostepne: boolean) {
	await page.addInitScript((dostepne) => {
		const udostepnione: { nazwa: string; tekst: string }[] = [];
		Object.assign(window, { __udostepnione: udostepnione });
		Object.defineProperty(navigator, 'canShare', { configurable: true, value: dostepne ? () => true : undefined });
		Object.defineProperty(navigator, 'share', {
			configurable: true,
			value: async ({ files }: { files: File[] }) => {
				for (const plik of files) udostepnione.push({ nazwa: plik.name, tekst: await plik.text() });
			}
		});
	}, dostepne);
}

export const udostepnione = (page: Page) =>
	page.evaluate(() => (window as unknown as { __udostepnione: { nazwa: string; tekst: string }[] }).__udostepnione);
