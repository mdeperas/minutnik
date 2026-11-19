import { describe, expect, it } from 'vitest';
import { Odtwarzacz, type Krok } from './odtwarzacz';
import { odliczaniePomiedzy, sygnalPoZmianie } from './sygnaly';

const kroki: Krok[] = [0, 1, 2].flatMap((grupa) => [
	{ grupa, faza: 0, nazwa: 'Napinanie', czasMs: 10_000 },
	{ grupa, faza: 1, nazwa: 'Rozluźnienie', czasMs: 50_000 }
]);

describe('sygnalPoZmianie', () => {
	it('start daje sygnał napinania, brak zmiany nic', () => {
		const o = new Odtwarzacz(kroki);
		expect(sygnalPoZmianie(o.start(0), kroki)).toBe('napinanie');
		expect(sygnalPoZmianie(o.tik(5_000), kroki)).toBeUndefined();
	});

	it('nadrobienie trzech faz daje jeden sygnał fazy, w której sesja jest teraz', () => {
		const o = new Odtwarzacz(kroki);
		o.start(0);
		const zdarzenia = o.tik(125_000);
		expect(zdarzenia.length).toBe(4);
		expect(sygnalPoZmianie(zdarzenia, kroki)).toBe('napinanie');
	});

	it('skok przez koniec sesji daje sygnał końca, Przerwij nic', () => {
		const o = new Odtwarzacz(kroki);
		o.start(0);
		expect(sygnalPoZmianie(o.tik(10 * 60_000), kroki)).toBe('koniec');
		const p = new Odtwarzacz(kroki);
		p.start(0);
		expect(sygnalPoZmianie(p.przerwij(1_000), kroki)).toBeUndefined();
	});
});

describe('odliczaniePomiedzy', () => {
	const w = (krok: number, zostalo: number) => ({ krok, zostalo });

	it('tyka na 3, 2 i 1 s przed końcem fazy, wcześniej nie', () => {
		expect(odliczaniePomiedzy(w(0, 3_100), w(0, 3_000))).toBe(true);
		expect(odliczaniePomiedzy(w(0, 2_050), w(0, 1_990))).toBe(true);
		expect(odliczaniePomiedzy(w(0, 1_010), w(0, 990))).toBe(true);
		expect(odliczaniePomiedzy(w(0, 4_100), w(0, 3_500))).toBe(false);
		expect(odliczaniePomiedzy(w(0, 2_900), w(0, 2_100))).toBe(false);
	});

	it('nie tyka na zmianie fazy, w pauzie ani na zerze', () => {
		expect(odliczaniePomiedzy(w(0, 500), w(1, 9_000))).toBe(false);
		expect(odliczaniePomiedzy(w(0, 2_500), w(0, 2_500))).toBe(false);
		expect(odliczaniePomiedzy(w(0, 500), w(0, 0))).toBe(false);
		expect(odliczaniePomiedzy(undefined, w(0, 2_000))).toBe(false);
	});
});
