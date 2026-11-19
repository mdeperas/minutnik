import { describe, expect, it } from 'vitest';
import { oddech, pierscienOddechu, skalaPluc } from './oddech';

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

	it('postęp etapu rośnie w ciągu 4 s', () => {
		expect(oddech(2_000).postepEtapu).toBeCloseTo(0.5);
	});

	it('płuca rosną przy wdechu, maleją przy wydechu, z Reduce Motion stoją', () => {
		expect([2_000, 6_000, 10_000, 14_000].map((ms) => oddech(ms).pelnosc)).toEqual([0.5, 1, 0.5, 0]);
		expect(skalaPluc(0, false)).toBe(0.4);
		expect(skalaPluc(1, false)).toBe(1);
		expect(skalaPluc(0, true)).toBe(1);
	});

	it('pierścień rozluźnienia: cyfry 4-3-2-1 etapu, obwód ubywa przez 4 s, płuca rosną przy wdechu', () => {
		expect(pierscienOddechu(1_000, false)).toEqual({ cyfry: '3', napis: 'Wdech', pluca: 0.4 + 0.6 * 0.25 });
		expect(pierscienOddechu(6_000, false)).toMatchObject({ cyfry: '2', napis: 'Trzymaj', pluca: 1 });
		expect(pierscienOddechu(13_000, true)).toMatchObject({ napis: 'Trzymaj', pluca: 1 });
	});
});
