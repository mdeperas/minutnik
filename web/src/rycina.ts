import type { RodzajFazy } from './wyglad';

export type StanRyciny = 'napiecie' | 'rozluznienie';
export type MapaRycin = Record<string, Record<StanRyciny, string>>;

export function stanRyciny(rodzaj: RodzajFazy): StanRyciny {
	return rodzaj === 'napinanie' ? 'napiecie' : 'rozluznienie';
}

export function plikRyciny(mapa: MapaRycin, grupa: string, rodzaj: RodzajFazy): string | undefined {
	return mapa[grupa]?.[stanRyciny(rodzaj)];
}
