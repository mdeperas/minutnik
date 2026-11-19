import { describe, expect, it } from 'vitest';
import { cyfry, kolory, wygladFazy, wyroznia } from './wyglad';

describe('wygladFazy', () => {
	it('napinanie: pełny obwód na starcie, ubywa i maleje', () => {
		const start = wygladFazy('Napinanie', 10000, 10000, false);
		expect([start.rodzaj, start.zostaloObwodu, start.skala, start.cyfry]).toEqual(['napinanie', 1, 1, '10']);
		const pozno = wygladFazy('Napinanie', 2500, 10000, false);
		expect(pozno.zostaloObwodu).toBeCloseTo(0.25);
		expect(pozno.skala).toBeCloseTo(0.85);
		expect(pozno.cyfry).toBe('3');
	});

	it('rozluźnienie rośnie, ograniczony ruch trzyma skalę 1', () => {
		expect(wygladFazy('Rozluźnienie', 12500, 50000, false).skala).toBeCloseTo(0.95);
		const stoi = wygladFazy('Rozluźnienie', 25000, 50000, true);
		expect([stoi.rodzaj, stoi.skala, stoi.zostaloObwodu]).toEqual(['rozluznienie', 1, 0.5]);
		const po = wygladFazy('Rozluźnienie', -1000, 50000, false);
		expect([po.zostaloObwodu, po.cyfry]).toEqual([0, '0']);
	});

	it('kolory jak w pierwowzorze', () => {
		expect([wygladFazy('Napinanie', 1, 1, false).kolorObwodu, wygladFazy('Napinanie', 1, 1, false).kolorNapisu]).toEqual([kolory.napinanieObwod, kolory.napinanieNapis]);
		expect(wygladFazy('Wydech', 1, 1, false).kolorObwodu).toBe('#8fbfa3');
		expect(kolory.tlo).toBe('#17181c');
	});

	it('cyfry: sekundy w górę, od minuty m:ss', () => {
		expect([cyfry(75000), cyfry(59001), cyfry(0)]).toEqual(['1:15', '1:00', '0']);
	});

	it('wyróżnia tylko instrukcje bieżącej fazy', () => {
		expect(['Napnij', 'Uwaga', 'Jak'].map((e) => wyroznia('napinanie', e))).toEqual([true, false, false]);
		expect(['Puść', 'Poczuj', 'Jak'].map((e) => wyroznia('rozluznienie', e))).toEqual([true, true, false]);
	});
});
