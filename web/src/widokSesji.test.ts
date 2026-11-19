import { describe, expect, it } from 'vitest';
import { widokSesji } from './widokSesji';

const widoczne = (w: ReturnType<typeof widokSesji>) => Object.entries(w.przyciski).filter(([, v]) => v).map(([k]) => k);

describe('widokSesji', () => {
	it('przyciski, krok i napis w każdym stanie', () => {
		expect([widoczne(widokSesji({ rodzaj: 'gotowy' })), widokSesji({ rodzaj: 'gotowy' }).krok]).toEqual([['start', 'wroc'], 0]);
		const trwa = widokSesji({ rodzaj: 'trwa', krok: 3, poczatek: 0 });
		expect([widoczne(trwa), trwa.krok]).toEqual([['pauza', 'pomin', 'przerwij'], 3]);
		expect(widoczne(widokSesji({ rodzaj: 'pauza', krok: 1, minelo: 0 }))).toEqual(['wznow', 'pomin', 'przerwij']);
		const koniec = widokSesji({ rodzaj: 'zakonczony' });
		expect([widoczne(koniec), koniec.krok, koniec.napisKonca]).toEqual([['koniec'], undefined, 'Koniec']);
		expect(widokSesji({ rodzaj: 'przerwany' }).napisKonca).toBe('Przerwano');
	});
});
