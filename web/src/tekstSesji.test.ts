import { describe, expect, it } from 'vitest';
import { liczbaGrup, linieInstrukcji, minutyZestawu, minutySekundy, pozycjaGrupy } from './tekstSesji';

describe('tekst sesji', () => {
	it('instrukcje w kolejności, „Jak” także przy „Napnij”, puste pominięte', () => {
		expect(linieInstrukcji({ jak: 'j', napnij: 'n', uwaga: 'u', pusc: '', poczuj: 'p' }).map((l) => l.etykieta)).toEqual(['Jak', 'Napnij', 'Uwaga', 'Poczuj']);
		expect(linieInstrukcji({ jak: 'j', pusc: 'p' })).toEqual([{ etykieta: 'Jak', tekst: 'j' }, { etykieta: 'Puść', tekst: 'p' }]);
		expect(linieInstrukcji(undefined)).toEqual([]);
	});

	it('odmiana grup, pozycja, czas zestawu i zegar', () => {
		expect([1, 2, 5, 12, 22, 112].map(liczbaGrup)).toEqual(['1 grupa', '2 grupy', '5 grup', '12 grup', '22 grupy', '112 grup']);
		expect(pozycjaGrupy(0, 12)).toBe('Grupa 1 z 12');
		expect(minutyZestawu({ nazwa: 'x', grupy: [{ nazwa: 'a', fazy: [{ nazwa: 'Napinanie', czasS: 121 }] }] })).toBe('3 min');
		expect([minutySekundy(0), minutySekundy(714_001), minutySekundy(-5)]).toEqual(['0:00', '11:55', '0:00']);
	});
});
