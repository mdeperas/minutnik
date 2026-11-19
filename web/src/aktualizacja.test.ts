import { describe, expect, it } from 'vitest';
import { Aktualizacja } from './aktualizacja';

function aktualizacja() {
	const przeladowania: number[] = [];
	return { przeladowania, aktualizacja: new Aktualizacja(() => przeladowania.push(1)) };
}

describe('Aktualizacja', () => {
	it('poza sesją przeładowuje od razu', () => {
		const { aktualizacja: a, przeladowania } = aktualizacja();
		a.nowaWersja();
		expect(przeladowania).toHaveLength(1);
	});

	it('w sesji czeka do jej końca i przeładowuje raz', () => {
		const { aktualizacja: a, przeladowania } = aktualizacja();
		a.poczatekSesji();
		a.nowaWersja();
		a.nowaWersja();
		expect(przeladowania).toHaveLength(0);
		a.koniecSesji();
		a.poczatekSesji();
		a.koniecSesji();
		expect(przeladowania).toHaveLength(1);
	});

	it('koniec sesji bez nowej wersji nie przeładowuje', () => {
		const { aktualizacja: a, przeladowania } = aktualizacja();
		a.poczatekSesji();
		a.koniecSesji();
		expect(przeladowania).toHaveLength(0);
	});
});
