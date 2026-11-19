import { describe, expect, it } from 'vitest';
import surowe from 'virtual:zestawy';
import { BladKatalogu, dekodujKatalog } from './katalog';

describe('dekodujKatalog', () => {
	it('czyta wbudowany PRM: wstęp, 12 grup z fazami 10 i 50 s, relaks i powrót', () => {
		const zestawy = dekodujKatalog(surowe);
		expect(zestawy.map((z) => [z.nazwa, z.grupy.length])).toEqual([['12 grup', 15]]);
		const [napinanie, rozluznienie] = zestawy[0].grupy[1].fazy;
		expect([napinanie.nazwa, napinanie.czasS, rozluznienie.nazwa, rozluznienie.czasS]).toEqual(['Napinanie', 10, 'Rozluźnienie', 50]);
		expect(napinanie.instrukcje?.jak).toBeTruthy();
		expect(rozluznienie.instrukcje?.pusc).toBeTruthy();
	});

	it('przyjmuje fazy bez instrukcji', () => {
		const zestawy = dekodujKatalog({ wersja: 1, zestawy: [{ nazwa: 'Oddech', grupy: [{ nazwa: 'O', fazy: [{ nazwa: 'Wdech', czasS: 4 }] }] }] });
		expect(zestawy[0].grupy[0].fazy[0]).toStrictEqual({ nazwa: 'Wdech', czasS: 4 });
	});

	it('odrzuca nieznaną wersję', () => {
		expect(() => dekodujKatalog({ wersja: 2, zestawy: [] })).toThrow('Nieznana wersja formatu zestawów');
	});

	it.each([
		['brak zestawów', { wersja: 1 }],
		['faza bez czasu', { wersja: 1, zestawy: [{ nazwa: 'Z', grupy: [{ nazwa: 'G', fazy: [{ nazwa: 'F' }] }] }] }],
		['instrukcja nie tekstem', { wersja: 1, zestawy: [{ nazwa: 'Z', grupy: [{ nazwa: 'G', fazy: [{ nazwa: 'F', czasS: 1, instrukcje: { jak: 3 } }] }] }] }],
		['nie obiekt', null]
	])('odrzuca błędny plik: %s', (_opis, plik) => {
		expect(() => dekodujKatalog(plik)).toThrow(BladKatalogu);
	});
});
