import { writeFileSync } from 'node:fs';
import { join } from 'node:path';

const zrodlo = process.env.ZRODLO_PRM!;
const cel = join(import.meta.dirname, '../lokalne/zestawy.json');

const { zestawyPrm } = await import(zrodlo);

const napinanieS = 10;
const rozluznienieS = 50;

const zestawy = zestawyPrm.map((zestaw: any) => ({
	nazwa: zestaw.nazwa,
	grupy: zestaw.grupy.map((g: any) => ({
		nazwa: g.nazwa,
		fazy: [
			{ nazwa: 'Napinanie', czasS: napinanieS, instrukcje: { jak: g.jak, napnij: g.napnij, uwaga: g.uwaga } },
			{ nazwa: 'Rozluźnienie', czasS: rozluznienieS, instrukcje: { pusc: g.pusc, poczuj: g.poczuj } }
		]
	}))
}));

writeFileSync(cel, JSON.stringify({ wersja: 1, zestawy }, null, '\t') + '\n');
console.log(`${cel}: ${zestawy.length} zestawy`);
