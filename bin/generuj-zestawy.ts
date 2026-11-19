import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

type Instrukcje = Record<string, string>;
type Zrodlo = {
	wstep: string;
	relaks: string;
	powrot: string;
	grupy: { nazwa: string; napinanie: Instrukcje; rozluznienie: Instrukcje }[];
};

const zrodlo = join(import.meta.dirname, '../lokalne/prm-ksiazka.json');
const cel = join(import.meta.dirname, '../lokalne/zestawy.json');
const prm = JSON.parse(readFileSync(zrodlo, 'utf8')) as Zrodlo;

const krok = (grupa: string, faza: string, czasS: number, jak: string) => ({ nazwa: grupa, fazy: [{ nazwa: faza, czasS, instrukcje: { jak } }] });

const zestawy = [
	{
		nazwa: '12 grup',
		grupy: [
			krok('Wstęp', 'Wstęp', 30, prm.wstep),
			...prm.grupy.map((g) => ({
				nazwa: g.nazwa,
				fazy: [
					{ nazwa: 'Napinanie', czasS: 10, instrukcje: g.napinanie },
					{ nazwa: 'Rozluźnienie', czasS: 50, instrukcje: g.rozluznienie }
				]
			})),
			krok('Pełny relaks', 'Relaks', 120, prm.relaks),
			krok('Powrót', 'Powrót', 30, prm.powrot)
		]
	}
];

writeFileSync(cel, JSON.stringify({ wersja: 1, zestawy }, null, '\t') + '\n');
console.log(`${cel}: ${zestawy.length} zestaw, ${zestawy[0].grupy.length} kroków`);
