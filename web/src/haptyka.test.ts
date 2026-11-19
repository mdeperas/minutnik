import { describe, expect, it, vi } from 'vitest';
import type { Krok } from './odtwarzacz';
import { wibracjaPoSygnale, wibracjaPomiedzy, wibruj } from './haptyka';

const krok = (nazwa: string, czasMs: number): Krok => ({ grupa: 0, faza: 0, nazwa, czasMs });
const kroki = [krok('Napinanie', 10_000), krok('Rozluźnienie', 50_000)];
const w = (k: number, zostalo: number) => ({ krok: k, zostalo });

describe('haptyka', () => {
	it('nowa faza i koniec sesji dają podwójne stuknięcie, brak sygnału nic', () => {
		expect(wibracjaPoSygnale('napinanie')).toBe('zmiana');
		expect(wibracjaPoSygnale('koniec')).toBe('zmiana');
		expect(wibracjaPoSygnale(undefined)).toBeUndefined();
	});

	it('odliczanie 3-2-1 stuka w każdej fazie', () => {
		expect(wibracjaPomiedzy(w(0, 3_100), w(0, 3_000), kroki)).toBe('tik');
		expect(wibracjaPomiedzy(w(0, 1_010), w(0, 990), kroki)).toBe('tik');
		expect(wibracjaPomiedzy(w(0, 2_900), w(0, 2_100), kroki)).toBeUndefined();
	});

	it('w rozluźnieniu stuka co 4 s, w napinaniu nie', () => {
		expect(wibracjaPomiedzy(w(1, 46_100), w(1, 45_900), kroki)).toBe('tik');
		expect(wibracjaPomiedzy(w(1, 46_900), w(1, 46_100), kroki)).toBeUndefined();
		expect(wibracjaPomiedzy(w(0, 8_100), w(0, 7_900), kroki)).toBeUndefined();
	});

	it('zmiana kroku, koniec fazy i brak chwili nie stukają', () => {
		expect(wibracjaPomiedzy(w(0, 100), w(1, 49_900), kroki)).toBeUndefined();
		expect(wibracjaPomiedzy(w(1, 100), w(1, 0), kroki)).toBeUndefined();
		expect(wibracjaPomiedzy(undefined, w(1, 45_900), kroki)).toBeUndefined();
	});

	it('wibruje wzorem rodzaju, a bez navigator.vibrate (Safari na iPhonie) nic nie robi', () => {
		const vibrate = vi.fn(() => true);
		wibruj('tik', vibrate);
		wibruj('zmiana', vibrate);
		wibruj(undefined, vibrate);
		expect(vibrate.mock.calls).toEqual([[40], [[80, 60, 80]]]);
		expect(() => wibruj('tik', undefined)).not.toThrow();
	});
});
