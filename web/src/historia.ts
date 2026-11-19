import type { Zdarzenie } from './odtwarzacz';

export interface Wpis {
	setName: string;
	startedAt: string;
	endedAt: string;
	completed: boolean;
	phasesDone: number;
	phasesTotal: number;
}

export interface Magazyn {
	wczytaj(): string | null;
	zapisz(tekst: string): void;
}

export const plikEksportu = 'minutnik-historia.json';

export function dataIso(data: Date): string {
	return data.toISOString().replace(/\.\d{3}Z$/, 'Z');
}

export function kodujHistorie(wpisy: readonly Wpis[]): string {
	const wKolejnosciKluczy = wpisy.map((w) => ({
		completed: w.completed,
		endedAt: w.endedAt,
		phasesDone: w.phasesDone,
		phasesTotal: w.phasesTotal,
		setName: w.setName,
		startedAt: w.startedAt
	}));
	return JSON.stringify(wKolejnosciKluczy, null, 2);
}

const jestData = (x: unknown) => typeof x === 'string' && !Number.isNaN(Date.parse(x));
const jestLiczba = (x: unknown) => Number.isInteger(x) && (x as number) >= 0;

export function dekodujHistorie(tekst: string): Wpis[] {
	const surowe: unknown = JSON.parse(tekst);
	if (!Array.isArray(surowe)) throw new Error('historia: oczekiwano tablicy');
	return surowe.map((w, i) => {
		if (
			typeof w !== 'object' || w === null ||
			typeof w.setName !== 'string' || !jestData(w.startedAt) || !jestData(w.endedAt) ||
			typeof w.completed !== 'boolean' || !jestLiczba(w.phasesDone) || !jestLiczba(w.phasesTotal)
		)
			throw new Error(`historia: zły wpis ${i}`);
		const { setName, startedAt, endedAt, completed, phasesDone, phasesTotal } = w as Wpis;
		return { setName, startedAt, endedAt, completed, phasesDone, phasesTotal };
	});
}

export function wynikSesji(zdarzenia: Zdarzenie[], krokPrzed: number, wszystkie: number): { ukonczona: boolean; fazy: number } | undefined {
	if (zdarzenia.some((z) => z.rodzaj === 'koniec')) return { ukonczona: true, fazy: wszystkie };
	if (!zdarzenia.some((z) => z.rodzaj === 'przerwana')) return undefined;
	const ostatniaFaza = zdarzenia.filter((z) => z.rodzaj === 'faza').at(-1);
	return { ukonczona: false, fazy: ostatniaFaza?.rodzaj === 'faza' ? ostatniaFaza.krok : krokPrzed };
}

export function opisWpisu(wpis: Wpis): string {
	const minuty = Math.round((Date.parse(wpis.endedAt) - Date.parse(wpis.startedAt)) / 60_000);
	const wynik = wpis.completed ? 'Ukończona' : `Przerwana po ${wpis.phasesDone} z ${wpis.phasesTotal} faz`;
	return `${wynik} · ${minuty} min`;
}

export class Historia {
	private _wpisy: Wpis[];
	private zachowujNieczytelny = false;

	constructor(private magazyn: Magazyn) {
		try {
			const tekst = magazyn.wczytaj();
			this._wpisy = tekst === null ? [] : dekodujHistorie(tekst);
		} catch {
			this._wpisy = [];
			this.zachowujNieczytelny = true;
		}
	}

	get wpisy(): readonly Wpis[] {
		return this._wpisy;
	}

	get odNajnowszych(): Wpis[] {
		return [...this._wpisy].reverse();
	}

	dodaj(wpis: Wpis): void {
		this._wpisy.push(wpis);
		if (this.zachowujNieczytelny) return;
		try {
			this.magazyn.zapisz(kodujHistorie(this._wpisy));
		} catch {
			return;
		}
	}
}
