import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const katalogRycin = join(import.meta.dirname, '../grafika/ryciny');
const pliki = process.argv.slice(2);
const domyslne = [join(import.meta.dirname, '../lokalne/zestawy.json'), join(import.meta.dirname, '../web/zestawy-publiczne.json')].filter((plik) => existsSync(plik));
const zestawy = pliki.length ? pliki : domyslne;
const STANY = ['napiecie', 'rozluznienie'] as const;
const mapa: Record<string, Record<(typeof STANY)[number], string>> = JSON.parse(readFileSync(join(katalogRycin, 'mapa.json'), 'utf8'));

type Katalog = { zestawy: { nazwa: string; grupy: { nazwa: string; fazy: { nazwa: string }[] }[] }[] };
const grupaMiesni = (g: { fazy: { nazwa: string }[] }) => g.fazy.some((f) => f.nazwa.toLowerCase().startsWith('napin'));

const braki = zestawy.flatMap((plik) =>
	(JSON.parse(readFileSync(plik, 'utf8')) as Katalog).zestawy.flatMap((z) =>
		z.grupy
			.filter(grupaMiesni)
			.flatMap((g) => STANY.filter((stan) => !mapa[g.nazwa]?.[stan] || !existsSync(join(katalogRycin, mapa[g.nazwa][stan]))).map((stan) => `${plik}: ${z.nazwa} / ${g.nazwa} (${stan})`))
	)
);
const bezKoloru = Object.values(mapa).flatMap((stany) => STANY.map((stan) => stany[stan])).filter((p) => existsSync(join(katalogRycin, p)) && !readFileSync(join(katalogRycin, p), 'utf8').includes('currentColor'));

if (braki.length || bezKoloru.length) {
	for (const b of braki) console.error(`Brak ryciny: ${b}`);
	for (const p of bezKoloru) console.error(`Rycina bez currentColor: ${p}`);
	process.exit(1);
}
console.log(`Ryciny: ${Object.keys(mapa).length} grup, oba stany, wszystkie zestawy pokryte.`);
