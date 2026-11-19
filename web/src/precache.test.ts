import { describe, expect, it } from 'vitest';
import { kodServiceWorkera, nazwaCache, plikiDoPrecache } from './precache';

describe('precache', () => {
	it('bierze pliki builda pod base, index jako start, bez samego workera i map', () => {
		expect(plikiDoPrecache('/minutnik/', ['sw.js', 'index.html', 'assets/a-1.js', 'assets/a-1.js.map', 'ikona-180.png', 'muzyka/kosmos.m4a'])).toEqual([
			'/minutnik/assets/a-1.js',
			'/minutnik/ikona-180.png',
			'/minutnik/'
		]);
	});

	it('muzyka idzie do osobnego cache na żądanie, którego nowa wersja nie kasuje', () => {
		const kod = kodServiceWorkera('abc', '/m/', ['/m/a-1.js']);
		expect(kod).toContain('"/m/muzyka/"');
		expect(kod).toContain('k !== CACHE_NA_ZADANIE');
	});

	it('nazwa cache zależy od wersji i od plików builda, więc każdy nowy build ma nowy cache', () => {
		expect(kodServiceWorkera('abc', '/m/', ['/m/a-1.js'])).toContain(`"${nazwaCache('abc', ['/m/a-1.js'])}"`);
		expect(nazwaCache('abc', ['/m/a-1.js'])).toMatch(/^minutnik-abc-/);
		expect(nazwaCache('def', ['/m/a-1.js'])).not.toBe(nazwaCache('abc', ['/m/a-1.js']));
		expect(nazwaCache('abc', ['/m/a-2.js'])).not.toBe(nazwaCache('abc', ['/m/a-1.js']));
	});
});
