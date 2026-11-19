import { describe, expect, it } from 'vitest';
import { oddech, skalaPluc, zmianaEtapuPomiedzy } from './oddech';

describe('oddech pudełkowy', () => {
	it('od początku fazy: wdech 4-3-2-1, potem trzymaj, wydech, trzymaj', () => {
		expect([0, 999, 1_000, 3_999].map((ms) => [oddech(ms).napis, oddech(ms).sekunda])).toEqual([
			['Wdech', 4],
			['Wdech', 4],
			['Wdech', 3],
			['Wdech', 1]
		]);
		expect([4_000, 8_000, 12_000, 16_000].map((ms) => oddech(ms).etap)).toEqual(['pelne', 'wydech', 'puste', 'wdech']);
	});

	it('ostatni niepełny cykl 50 s urywa się w połowie wdechu', () => {
		expect(oddech(49_999)).toMatchObject({ etap: 'wdech', sekunda: 3, numer: 12 });
	});

	it('postęp cyklu obiega kwadrat raz na 16 s', () => {
		expect(oddech(0).postepCyklu).toBe(0);
		expect(oddech(6_000).postepCyklu).toBeCloseTo(0.375);
		expect(oddech(2_000).postepEtapu).toBeCloseTo(0.5);
	});

	it('zmiana etapu co 4 s w tym samym kroku, nie na końcu fazy', () => {
		expect(zmianaEtapuPomiedzy({ krok: 1, zostalo: 46_100 }, { krok: 1, zostalo: 45_900 }, 50_000, 'rozluznienie')).toBe(true);
		expect(zmianaEtapuPomiedzy({ krok: 1, zostalo: 46_900 }, { krok: 1, zostalo: 46_100 }, 50_000, 'rozluznienie')).toBe(false);
		expect(zmianaEtapuPomiedzy({ krok: 0, zostalo: 100 }, { krok: 1, zostalo: 49_900 }, 50_000, 'rozluznienie')).toBe(false);
		expect(zmianaEtapuPomiedzy({ krok: 1, zostalo: 100 }, { krok: 1, zostalo: 0 }, 50_000, 'rozluznienie')).toBe(false);
	});

	it('w napinaniu oddech nie wibruje', () => {
		expect(zmianaEtapuPomiedzy({ krok: 0, zostalo: 8_100 }, { krok: 0, zostalo: 7_900 }, 10_000, 'napinanie')).toBe(false);
	});

	it('płuca rosną przy wdechu, maleją przy wydechu, z Reduce Motion stoją', () => {
		expect([2_000, 6_000, 10_000, 14_000].map((ms) => oddech(ms).pelnosc)).toEqual([0.5, 1, 0.5, 0]);
		expect(skalaPluc(0, false)).toBe(0.4);
		expect(skalaPluc(1, false)).toBe(1);
		expect(skalaPluc(0, true)).toBe(1);
	});
});
