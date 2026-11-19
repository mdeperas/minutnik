import { describe, expect, it } from 'vitest';
import surowe from '../o-cwiczeniu-publiczne.json';
import { BladTekstu, dekodujTekst } from './oCwiczeniu';

describe('dekodujTekst', () => {
	it('czyta publiczny tekst: tytuł, sekcje z treścią i źródło z książki', () => {
		const tekst = dekodujTekst(surowe);
		expect(tekst.tytul).toBe('O ćwiczeniu');
		expect(tekst.sekcje.length).toBeGreaterThanOrEqual(5);
		expect(tekst.sekcje.every((s) => s.akapity.length + s.punkty.length > 0)).toBe(true);
		expect(tekst.zrodlo).toContain('Ponad lękiem');
	});

	it('brak akapitów albo punktów to pusta lista', () => {
		const tekst = dekodujTekst({ tytul: 'T', zrodlo: 'Z', sekcje: [{ naglowek: 'N', punkty: ['p'] }] });
		expect(tekst.sekcje[0]).toStrictEqual({ naglowek: 'N', akapity: [], punkty: ['p'] });
	});

	it.each([
		['brak sekcji', { tytul: 'T', zrodlo: 'Z', sekcje: [] }],
		['sekcja bez treści', { tytul: 'T', zrodlo: 'Z', sekcje: [{ naglowek: 'N' }] }],
		['pusty nagłówek', { tytul: 'T', zrodlo: 'Z', sekcje: [{ naglowek: ' ', akapity: ['a'] }] }],
		['brak źródła', { tytul: 'T', sekcje: [{ naglowek: 'N', akapity: ['a'] }] }]
	])('odrzuca: %s', (_, surowy) => {
		expect(() => dekodujTekst(surowy)).toThrow(BladTekstu);
	});
});
