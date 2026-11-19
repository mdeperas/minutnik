export const plikServiceWorkera = 'sw.js';

export function plikiDoPrecache(base: string, sciezki: string[]): string[] {
	const pliki = sciezki
		.filter((s) => s !== plikServiceWorkera && !s.endsWith('.map'))
		.sort()
		.map((s) => (s === 'index.html' ? base : base + s));
	return [...new Set(pliki)];
}

function skrot(tekst: string): string {
	let h = 0x811c9dc5;
	for (let i = 0; i < tekst.length; i++) h = Math.imul(h ^ tekst.charCodeAt(i), 0x01000193);
	return (h >>> 0).toString(36);
}

export const nazwaCache = (wersja: string, pliki: string[]) => `minutnik-${wersja}-${skrot(pliki.join('\n'))}`;

export function kodServiceWorkera(wersja: string, base: string, pliki: string[]): string {
	return `const CACHE = ${JSON.stringify(nazwaCache(wersja, pliki))};
const PLIKI = ${JSON.stringify(pliki)};
const START = ${JSON.stringify(base)};
self.addEventListener('install', (e) => {
	e.waitUntil(caches.open(CACHE).then((c) => c.addAll(PLIKI)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', (e) => {
	e.waitUntil(
		caches.keys()
			.then((klucze) => Promise.all(klucze.filter((k) => k.startsWith('minutnik-') && k !== CACHE).map((k) => caches.delete(k))))
			.then(() => self.clients.claim())
	);
});
self.addEventListener('fetch', (e) => {
	const r = e.request;
	if (r.method !== 'GET' || new URL(r.url).origin !== location.origin) return;
	const klucz = r.mode === 'navigate' ? START : r;
	e.respondWith(caches.open(CACHE).then((c) => c.match(klucz, { ignoreSearch: true })).then((t) => t ?? fetch(r)));
});
`;
}
