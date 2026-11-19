import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join, relative } from 'node:path';

const cel = process.argv[2];
const lokalne = join(import.meta.dirname, '../lokalne');
const DLUGOSC_FRAZY = 5;

const czytaj = (plik: string) => readFileSync(join(lokalne, plik), 'utf8');
const linie = (tekst: string) => tekst.split('\n').map((l) => l.trim()).filter((l) => l !== '');
const wartosc = (tekst: string, wzor: RegExp) => tekst.match(wzor)?.[1];

const wpisy = linie(czytaj('zakazane.txt'));
const dozwolone = wpisy.filter((w) => w.startsWith('!')).map((w) => w.slice(1).toLowerCase());
const zakazane = [
	...wpisy.filter((w) => !w.startsWith('!')),
	process.env.DEVICE_ID,
	wartosc(czytaj('podpis.xcconfig'), /DEVELOPMENT_TEAM\s*=\s*(\S+)/),
	execFileSync('git', ['config', 'user.email']).toString().trim(),
	homedir()
].filter((w): w is string => !!w && w.length >= 4);

const normalizuj = (tekst: string) => tekst.toLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
const teksty = (wezel: unknown): string[] =>
	typeof wezel === 'string' ? [wezel] : wezel && typeof wezel === 'object' ? Object.entries(wezel).flatMap(([k, v]) => (k === 'nazwa' ? [] : teksty(v))) : [];
const frazy = (tekst: string) => {
	const slowa = normalizuj(tekst).split(' ');
	return slowa.slice(0, Math.max(0, slowa.length - DLUGOSC_FRAZY + 1)).map((_, i) => slowa.slice(i, i + DLUGOSC_FRAZY).join(' '));
};
const tekstyKsiazki = ['zestawy.json', 'o-cwiczeniu.json'];
const frazyKsiazki = new Set(tekstyKsiazki.flatMap((plik) => teksty(JSON.parse(czytaj(plik)))).flatMap(frazy));
if (!existsSync(join(cel, '.git'))) {
	console.error(`${cel}: to nie jest repo gita`);
	process.exit(1);
}

const pliki = readdirSync(cel, { recursive: true, withFileTypes: true })
	.filter((w) => w.isFile() && !join(w.parentPath, w.name).includes(`${cel}/.git/`))
	.map((w) => join(w.parentPath, w.name));
const zrodla = [
	...pliki.map((plik) => ({ nazwa: relative(cel, plik), tekst: readFileSync(plik).toString('utf8') })),
	{ nazwa: 'git log', tekst: execFileSync('git', ['-C', cel, 'log', '--format=%an %ae%n%cn %ce%n%B']).toString() }
];

const trafienia = zrodla.flatMap(({ nazwa, tekst }) => {
	const male = dozwolone.reduce((t, d) => t.replaceAll(d, ' '), tekst.toLowerCase());
	return [
		...zakazane.filter((w) => male.includes(w.toLowerCase())).map((w) => `${nazwa}: prywatna wartość nr ${zakazane.indexOf(w) + 1}`),
		...[...new Set(frazy(tekst))].filter((f) => frazyKsiazki.has(f)).map((f) => `${nazwa}: fraza z książki „${f}”`)
	];
});

if (trafienia.length) {
	for (const t of trafienia) console.error(t);
	console.error(`${cel}: ${trafienia.length} trafień, nie publikuj`);
	process.exit(1);
}
console.log(`${cel}: ${zrodla.length} plików i git log, ${zakazane.length} prywatnych wartości i ${frazyKsiazki.size} fraz z książki: zero trafień`);
