import type { Zestaw } from './katalog';

export interface Krok {
	grupa: number;
	faza: number;
	nazwa: string;
	czasMs: number;
}

export type Stan =
	| { rodzaj: 'gotowy' }
	| { rodzaj: 'trwa'; krok: number; poczatek: number }
	| { rodzaj: 'pauza'; krok: number; minelo: number }
	| { rodzaj: 'zakonczony' }
	| { rodzaj: 'przerwany' };

export type Zdarzenie =
	| { rodzaj: 'faza'; krok: number; o: number }
	| { rodzaj: 'koniec'; o: number }
	| { rodzaj: 'przerwana'; o: number };

export interface KoniecFazy {
	krok: number;
	o: number;
}

export function krokiZestawu(zestaw: Zestaw): Krok[] {
	return zestaw.grupy.flatMap((g, grupa) => g.fazy.map((f, faza) => ({ grupa, faza, nazwa: f.nazwa, czasMs: f.czasS * 1000 })));
}

export function minioneFazy(zdarzenia: Zdarzenie[]): number {
	return zdarzenia.filter((z) => z.rodzaj === 'faza').length;
}

export function sygnalPoZdarzeniach(zdarzenia: Zdarzenie[]): boolean {
	return zdarzenia.some((z) => z.rodzaj !== 'przerwana');
}

export class Odtwarzacz {
	private _stan: Stan = { rodzaj: 'gotowy' };

	constructor(readonly kroki: readonly Krok[]) {}

	get stan(): Stan {
		return this._stan;
	}

	start(teraz: number): Zdarzenie[] {
		if (this._stan.rodzaj !== 'gotowy') return [];
		return this.wejdz(0, teraz, teraz);
	}

	pauza(teraz: number): Zdarzenie[] {
		const zdarzenia = this.tik(teraz);
		const s = this._stan;
		if (s.rodzaj === 'trwa') this._stan = { rodzaj: 'pauza', krok: s.krok, minelo: Math.max(0, teraz - s.poczatek) };
		return zdarzenia;
	}

	wznow(teraz: number): Zdarzenie[] {
		const s = this._stan;
		if (s.rodzaj === 'pauza') this._stan = { rodzaj: 'trwa', krok: s.krok, poczatek: teraz - s.minelo };
		return [];
	}

	pomin(teraz: number): Zdarzenie[] {
		const zdarzenia = this.tik(teraz);
		const s = this._stan;
		if (s.rodzaj !== 'trwa' && s.rodzaj !== 'pauza') return zdarzenia;
		return [...zdarzenia, ...this.wejdz(s.krok + 1, teraz, teraz)];
	}

	przerwij(teraz: number): Zdarzenie[] {
		const zdarzenia = this.tik(teraz);
		const s = this._stan;
		if (s.rodzaj !== 'trwa' && s.rodzaj !== 'pauza') return zdarzenia;
		this._stan = { rodzaj: 'przerwany' };
		return [...zdarzenia, { rodzaj: 'przerwana', o: teraz }];
	}

	tik(teraz: number): Zdarzenie[] {
		const s = this._stan;
		if (s.rodzaj !== 'trwa') return [];
		const koniec = s.poczatek + this.kroki[s.krok].czasMs;
		if (teraz < koniec) return [];
		return this.wejdz(s.krok + 1, koniec, teraz);
	}

	zostaloWFazie(teraz: number): number {
		const s = this._stan;
		if (s.rodzaj === 'trwa') return Math.max(0, this.kroki[s.krok].czasMs - (teraz - s.poczatek));
		if (s.rodzaj === 'pauza') return Math.max(0, this.kroki[s.krok].czasMs - s.minelo);
		return 0;
	}

	zostaloWSesji(teraz: number): number {
		const s = this._stan;
		if (s.rodzaj === 'gotowy') return this.czasOd(0);
		if (s.rodzaj === 'trwa' || s.rodzaj === 'pauza') return this.zostaloWFazie(teraz) + this.czasOd(s.krok + 1);
		return 0;
	}

	nadchodzaceKonce(): KoniecFazy[] {
		const s = this._stan;
		if (s.rodzaj !== 'trwa') return [];
		let o = s.poczatek;
		return this.kroki.slice(s.krok).map((k, i) => {
			o += k.czasMs;
			return { krok: s.krok + i, o };
		});
	}

	private czasOd(pierwszy: number): number {
		return this.kroki.slice(pierwszy).reduce((suma, k) => suma + k.czasMs, 0);
	}

	private wejdz(pierwszy: number, planowanyPoczatek: number, teraz: number): Zdarzenie[] {
		const zdarzenia: Zdarzenie[] = [];
		let poczatek = planowanyPoczatek;
		for (let krok = pierwszy; krok < this.kroki.length; krok++) {
			zdarzenia.push({ rodzaj: 'faza', krok, o: poczatek });
			const koniec = poczatek + this.kroki[krok].czasMs;
			if (teraz < koniec) {
				this._stan = { rodzaj: 'trwa', krok, poczatek };
				return zdarzenia;
			}
			poczatek = koniec;
		}
		this._stan = { rodzaj: 'zakonczony' };
		return [...zdarzenia, { rodzaj: 'koniec', o: poczatek }];
	}
}
