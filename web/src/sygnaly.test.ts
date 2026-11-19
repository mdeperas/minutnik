import { describe, expect, it } from 'vitest';
import { Odtwarzacz, type Krok } from './odtwarzacz';
import { sygnalPoZmianie } from './sygnaly';

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
