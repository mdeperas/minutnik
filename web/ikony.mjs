import { readFile } from 'node:fs/promises';
import { webkit } from '@playwright/test';

const svg = await readFile('ikona.svg', 'utf8');
const przegladarka = await webkit.launch();
for (const rozmiar of [180, 192, 512]) {
	const strona = await przegladarka.newPage({ viewport: { width: rozmiar, height: rozmiar } });
	await strona.setContent(`<style>*{margin:0}svg{display:block;width:100vw;height:100vh}</style>${svg}`);
	await strona.screenshot({ path: `public/ikona-${rozmiar}.png` });
	await strona.close();
}
await przegladarka.close();
