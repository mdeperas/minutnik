import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { kolory } from '../web/src/wyglad.ts';

const katalogRycin = join(import.meta.dirname, '../grafika/ryciny');
const cel = process.argv[2] ?? join(import.meta.dirname, '../Minutnik/Ryciny.xcassets');
const mapa: Record<string, Record<'napiecie' | 'rozluznienie', string>> = JSON.parse(readFileSync(join(katalogRycin, 'mapa.json'), 'utf8'));
const kolorStanu = { napiecie: kolory.napinanieObwod, rozluznienie: kolory.rozluznienie };

function hex(kolor: string): string {
	const hsl = kolor.match(/^hsl\((\d+) (\d+)% (\d+)%\)$/);
	if (!hsl) return kolor;
	const [h, s, l] = [Number(hsl[1]), Number(hsl[2]) / 100, Number(hsl[3]) / 100];
	const kanal = (n: number) => {
		const k = (n + h / 30) % 12;
		const v = l - s * Math.min(l, 1 - l) * Math.max(-1, Math.min(k - 3, 9 - k, 1));
		return Math.round(v * 255).toString(16).padStart(2, '0');
	};
	return `#${kanal(0)}${kanal(8)}${kanal(4)}`;
}

const bezLukowZerowych = (svg: string) =>
	svg.replace(/A(-?[\d.]+)[ ,]?(-?[\d.]+)[ ,]?-?[\d.]+[ ,]?[01][ ,]?[01][ ,]?(-?[\d.]+,-?[\d.]+)/g, (luk, rx, ry, koniec) => (Number(rx) === 0 || Number(ry) === 0 ? `L${koniec}` : luk));

const zapisz = (sciezka: string, tresc: unknown) => writeFileSync(sciezka, typeof tresc === 'string' ? tresc : JSON.stringify(tresc, null, 2));
const info = { author: 'xcode', version: 1 };

rmSync(cel, { recursive: true, force: true });
mkdirSync(cel, { recursive: true });
zapisz(join(cel, 'Contents.json'), { info });
for (const stany of Object.values(mapa)) {
	for (const stan of ['napiecie', 'rozluznienie'] as const) {
		const plik = stany[stan];
		const zestaw = join(cel, plik.replace(/\.svg$/, '.imageset'));
		mkdirSync(zestaw);
		zapisz(join(zestaw, plik), bezLukowZerowych(readFileSync(join(katalogRycin, plik), 'utf8')).replaceAll('currentColor', hex(kolorStanu[stan])));
		zapisz(join(zestaw, 'Contents.json'), { images: [{ filename: plik, idiom: 'universal' }], info, properties: { 'preserves-vector-representation': true } });
	}
}
const dane = join(cel, 'mapa-rycin.dataset');
mkdirSync(dane);
zapisz(join(dane, 'mapa.json'), readFileSync(join(katalogRycin, 'mapa.json'), 'utf8'));
zapisz(join(dane, 'Contents.json'), { data: [{ filename: 'mapa.json', idiom: 'universal', 'universal-type-identifier': 'public.json' }], info });
