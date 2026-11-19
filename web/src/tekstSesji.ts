import type { Instrukcje, Zestaw } from './katalog';

export interface LiniaInstrukcji {
	etykieta: string;
	tekst: string;
}

export function linieInstrukcji(instrukcje: Instrukcje | undefined): LiniaInstrukcji[] {
	if (!instrukcje) return [];
	const kandydaci: [string, string | undefined][] = [
		['Jak', instrukcje.jak],
		['Napnij', instrukcje.napnij],
		['Uwaga', instrukcje.uwaga],
		['Puść', instrukcje.pusc],
		['Poczuj', instrukcje.poczuj]
	];
	return kandydaci.flatMap(([etykieta, tekst]) => (tekst ? [{ etykieta, tekst }] : []));
}

export function pozycjaGrupy(indeks: number, ile: number): string {
	return `Grupa ${indeks + 1} z ${ile}`;
}

export function liczbaGrup(ile: number): string {
	const dziesiatki = ile % 100;
	const slowo = ile === 1 ? 'grupa' : ile % 10 >= 2 && ile % 10 <= 4 && !(dziesiatki >= 12 && dziesiatki <= 14) ? 'grupy' : 'grup';
	return `${ile} ${slowo}`;
}

export function minutyZestawu(zestaw: Zestaw): string {
	const sekundy = zestaw.grupy.flatMap((g) => g.fazy).reduce((suma, f) => suma + f.czasS, 0);
	return `${Math.ceil(sekundy / 60)} min`;
}

export function minutySekundy(ms: number): string {
	const sekundy = Math.ceil(Math.max(0, ms) / 1000);
	return `${Math.floor(sekundy / 60)}:${String(sekundy % 60).padStart(2, '0')}`;
}
