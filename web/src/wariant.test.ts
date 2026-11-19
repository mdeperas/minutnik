import { describe, expect, it } from 'vitest';
import wariant from '../zestawy-publiczne.json';
import { dekodujKatalog } from './katalog';
import { krokiZestawu } from './odtwarzacz';
import { rodzajFazy } from './wyglad';

const [oryginal] = Object.values(import.meta.glob('../../lokalne/zestawy.json', { eager: true, import: 'default' }));
const rodzaje = (surowe: unknown) => dekodujKatalog(surowe).map((z) => krokiZestawu(z).map((k) => rodzajFazy(k.nazwa)));

describe('wariant publiczny zestawów', () => {
	it('każdy zestaw ma oba rodzaje faz', () => {
		for (const zestaw of rodzaje(wariant)) expect(new Set(zestaw)).toEqual(new Set(['napinanie', 'rozluznienie']));
	});

	it.skipIf(oryginal === undefined)('każda faza ma ten sam rodzaj co w lokalnym oryginale', () => {
		expect(rodzaje(wariant)).toEqual(rodzaje(oryginal));
	});
});
