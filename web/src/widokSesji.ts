import type { Stan } from './odtwarzacz';

export interface WidokSesji {
	przyciski: { start: boolean; pauza: boolean; wznow: boolean; pomin: boolean; przerwij: boolean; koniec: boolean; wroc: boolean };
	krok: number | undefined;
	napisKonca: string | undefined;
}

export function widokSesji(stan: Stan): WidokSesji {
	const wTrakcie = stan.rodzaj === 'trwa' || stan.rodzaj === 'pauza';
	const gotowy = stan.rodzaj === 'gotowy';
	const napisKonca = stan.rodzaj === 'zakonczony' ? 'Koniec' : stan.rodzaj === 'przerwany' ? 'Przerwano' : undefined;
	return {
		przyciski: {
			start: gotowy,
			pauza: stan.rodzaj === 'trwa',
			wznow: stan.rodzaj === 'pauza',
			pomin: wTrakcie,
			przerwij: wTrakcie,
			koniec: napisKonca !== undefined,
			wroc: gotowy
		},
		krok: wTrakcie ? stan.krok : gotowy ? 0 : undefined,
		napisKonca
	};
}
