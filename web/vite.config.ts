import { execSync } from 'node:child_process';
import { readdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig, type Plugin } from 'vitest/config';
import { kodServiceWorkera, plikServiceWorkera, plikiDoPrecache } from './src/precache.ts';

const domyslneZestawy = fileURLToPath(new URL('./zestawy-publiczne.json', import.meta.url));
const base = '/minutnik/';

function wersjaZGita() {
	try {
		return execSync('git rev-parse --short HEAD', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
	} catch {
		return 'dev';
	}
}

const wersja = process.env.MINUTNIK_WERSJA ?? wersjaZGita();

function serviceWorker(): Plugin {
	let katalog = '';
	return {
		name: 'minutnik-service-worker',
		apply: 'build',
		configResolved: (config) => void (katalog = resolve(config.root, config.build.outDir)),
		closeBundle() {
			const sciezki = readdirSync(katalog, { recursive: true, withFileTypes: true })
				.filter((wpis) => wpis.isFile())
				.map((wpis) => join(wpis.parentPath, wpis.name).slice(katalog.length + 1));
			writeFileSync(join(katalog, plikServiceWorkera), kodServiceWorkera(wersja, base, plikiDoPrecache(base, sciezki)));
		}
	};
}

export default defineConfig({
	base,
	define: { __WERSJA__: JSON.stringify(wersja) },
	plugins: [serviceWorker()],
	resolve: {
		alias: { 'virtual:zestawy': process.env.MINUTNIK_ZESTAWY ?? domyslneZestawy }
	},
	server: { fs: { allow: ['..'] } },
	test: { include: ['src/**/*.test.ts'], testTimeout: 30_000 }
});
