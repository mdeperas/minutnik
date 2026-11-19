import type { Stan } from './odtwarzacz';

export const sciezki = ['bez', 'synthwave', 'kosmos'] as const;
export type Sciezka = (typeof sciezki)[number];

export const nazwySciezek: Record<Sciezka, string> = { bez: 'Bez', synthwave: 'Synthwave', kosmos: 'Kosmos' };

export const glosnoscMuzyki = 0.3;
export const wyciszanieSekundy = 1.5;
export const katalogMuzyki = 'muzyka/';

export function odczytajSciezke(tekst: string | null): Sciezka {
	return sciezki.find((s) => s === tekst) ?? 'bez';
}

export function plikSciezki(sciezka: Sciezka): string | undefined {
	return sciezka === 'bez' ? undefined : `${katalogMuzyki}${sciezka}.m4a`;
}

export function glosnoscW(sciezka: Sciezka, wyciszona: boolean, stan: Stan): number {
	return sciezka !== 'bez' && !wyciszona && stan.rodzaj === 'trwa' ? glosnoscMuzyki : 0;
}
