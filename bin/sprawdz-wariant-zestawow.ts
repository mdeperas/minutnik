import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const oryginal = join(import.meta.dirname, '../lokalne/zestawy.json');
const wariant = process.argv[2] ?? join(import.meta.dirname, '../web/zestawy-publiczne.json');

type Instrukcje = Record<string, string>;
type Faza = { nazwa: string; czasS: number; instrukcje?: Instrukcje };
type Katalog = { wersja: number; zestawy: { nazwa: string; grupy: { nazwa: string; fazy: Faza[] }[] }[] };

const szkielet = (k: Katalog) =>
	JSON.stringify({
		wersja: k.wersja,
		zestawy: k.zestawy.map((z) => ({
			nazwa: z.nazwa,
			grupy: z.grupy.map((g) => ({
				nazwa: g.nazwa,
				fazy: g.fazy.map((f) => ({ nazwa: f.nazwa, czasS: f.czasS, klucze: Object.keys(f.instrukcje ?? {}).sort() }))
			}))
		}))
	});

const pusteTeksty = (k: Katalog) =>
	k.zestawy.flatMap((z) =>
		z.grupy.flatMap((g) =>
			g.fazy.flatMap((f) =>
				Object.entries(f.instrukcje ?? {})
					.filter(([, tekst]) => typeof tekst !== 'string' || tekst.trim() === '')
					.map(([klucz]) => `${z.nazwa} / ${g.nazwa} / ${f.nazwa} / ${klucz}`)
			)
		)
	);

const czytaj = (sciezka: string) => JSON.parse(readFileSync(sciezka, 'utf8')) as Katalog;
const b = czytaj(wariant);
const bledy: string[] = [];
const zOryginalem = existsSync(oryginal);
if (zOryginalem && szkielet(czytaj(oryginal)) !== szkielet(b)) bledy.push('struktura różni się od oryginału (zestawy, grupy, fazy, czasy albo klucze instrukcji)');
bledy.push(...pusteTeksty(b).map((m) => `pusty tekst: ${m}`));

if (bledy.length > 0) {
	console.error(`${wariant}:\n- ${bledy.join('\n- ')}`);
	process.exit(1);
}
console.log(zOryginalem ? `${wariant}: struktura zgodna z oryginałem` : `${wariant}: teksty niepuste; brak lokalne/zestawy.json, struktury nie porównuję`);
