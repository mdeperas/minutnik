import { describe, expect, it } from 'vitest';
import { plikRyciny, type MapaRycin } from './rycina';

const mapa: MapaRycin = { Dłonie: { napiecie: 'dlonie-n.svg', rozluznienie: 'dlonie-r.svg' } };

describe('plikRyciny', () => {
	it('przy napinaniu daje stan napięcia grupy', () => {
		expect(plikRyciny(mapa, 'Dłonie', 'napinanie')).toBe('dlonie-n.svg');
	});
	it('przy rozluźnieniu daje stan rozluźnienia grupy', () => {
		expect(plikRyciny(mapa, 'Dłonie', 'rozluznienie')).toBe('dlonie-r.svg');
	});
	it('grupa bez ryciny nie ma pliku', () => {
		expect(plikRyciny(mapa, 'Stopy', 'napinanie')).toBeUndefined();
	});
});
