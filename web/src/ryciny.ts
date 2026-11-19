import mapa from '../../grafika/ryciny/mapa.json';
import { plikRyciny, type MapaRycin } from './rycina';
import type { RodzajFazy } from './wyglad';

const pliki = import.meta.glob<string>('../../grafika/ryciny/*.svg', { query: '?raw', import: 'default', eager: true });

export function svgRyciny(grupa: string, rodzaj: RodzajFazy): { plik: string; svg: string } | undefined {
	const plik = plikRyciny(mapa as MapaRycin, grupa, rodzaj);
	const svg = plik ? pliki[`../../grafika/ryciny/${plik}`] : undefined;
	return plik && svg ? { plik, svg } : undefined;
}
