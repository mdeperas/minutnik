import { describe, expect, it } from 'vitest';
import { glosnoscMuzyki, glosnoscW, odczytajSciezke, plikSciezki } from './muzyka';

const trwa = { rodzaj: 'trwa', krok: 0, poczatek: 0 } as const;

describe('muzyka', () => {
	it('zapamiętany wybór wraca, a nieznany albo brak to bez muzyki', () => {
		expect(odczytajSciezke('kosmos')).toBe('kosmos');
		expect(odczytajSciezke('synthwave')).toBe('synthwave');
		expect(odczytajSciezke(null)).toBe('bez');
		expect(odczytajSciezke('disco')).toBe('bez');
	});

	it('plik tylko dla wybranej ścieżki', () => {
		expect(plikSciezki('kosmos')).toBe('muzyka/kosmos.m4a');
		expect(plikSciezki('bez')).toBeUndefined();
	});

	it('gra tylko w trwającej sesji, niewyciszona i ciszej niż sygnały', () => {
		expect(glosnoscW('synthwave', false, trwa)).toBe(glosnoscMuzyki);
		expect(glosnoscMuzyki).toBeLessThan(0.5);
		expect(glosnoscW('synthwave', true, trwa)).toBe(0);
		expect(glosnoscW('bez', false, trwa)).toBe(0);
		for (const stan of [{ rodzaj: 'gotowy' }, { rodzaj: 'pauza', krok: 0, minelo: 0 }, { rodzaj: 'zakonczony' }, { rodzaj: 'przerwany' }] as const)
			expect(glosnoscW('kosmos', false, stan)).toBe(0);
	});
});
