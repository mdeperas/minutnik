import { describe, expect, it } from 'vitest';
import { widokSesji } from './widokSesji';

const widoczne = (w: ReturnType<typeof widokSesji>) => Object.entries(w.przyciski).filter(([, v]) => v).map(([k]) => k);

describe('widokSesji', () => {
	it('przyciski, krok i napis w każdym stanie', () => {
		expect([widoczne(widokSesji({ rodzaj: 'gotowy' })), widokSesji({ rodzaj: 'gotowy' }).krok, widokSesji({ rodzaj: 'gotowy' }).wrocPyta]).toEqual([['start', 'wroc'], 0, false]);
		const trwa = widokSesji({ rodzaj: 'trwa', krok: 3, poczatek: 0 });
		expect([widoczne(trwa), trwa.krok, trwa.wrocPyta]).toEqual([['pauza', 'pomin', 'przerwij', 'wroc'], 3, true]);
		expect(widoczne(widokSesji({ rodzaj: 'pauza', krok: 1, minelo: 0 }))).toEqual(['wznow', 'pomin', 'przerwij', 'wroc']);
		const koniec = widokSesji({ rodzaj: 'zakonczony' });
		expect([widoczne(koniec), koniec.krok, koniec.napisKonca]).toEqual([['koniec'], undefined, 'Koniec']);
		expect(widokSesji({ rodzaj: 'przerwany' }).napisKonca).toBe('Przerwano');
	});
});
