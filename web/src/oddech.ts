export type EtapOddechu = 'wdech' | 'pelne' | 'wydech' | 'puste';

const etapMs = 4_000;

const etapy: readonly EtapOddechu[] = ['wdech', 'pelne', 'wydech', 'puste'];

const napisy: Record<EtapOddechu, string> = { wdech: 'Wdech', pelne: 'Trzymaj', wydech: 'Wydech', puste: 'Trzymaj' };

export interface Oddech {
	etap: EtapOddechu;
	napis: string;
	sekunda: number;
	numer: number;
	postepEtapu: number;
	pelnosc: number;
}

export function oddech(mineloMs: number): Oddech {
	const ms = Math.max(0, mineloMs);
	const numer = Math.floor(ms / etapMs);
	const wEtapie = ms - numer * etapMs;
	const etap = etapy[numer % etapy.length];
	const postepEtapu = wEtapie / etapMs;
	return {
		etap,
		napis: napisy[etap],
		sekunda: etapMs / 1000 - Math.floor(wEtapie / 1000),
		numer,
		postepEtapu,
		pelnosc: etap === 'wdech' ? postepEtapu : etap === 'wydech' ? 1 - postepEtapu : etap === 'pelne' ? 1 : 0
	};
}

const najmniejszePluca = 0.4;

export function skalaPluc(pelnosc: number, ograniczRuch: boolean): number {
	return ograniczRuch ? 1 : najmniejszePluca + (1 - najmniejszePluca) * pelnosc;
}

export interface PierscienOddechu {
	cyfry: string;
	napis: string;
	pluca: number;
}

export function pierscienOddechu(mineloMs: number, ograniczRuch: boolean): PierscienOddechu {
	const o = oddech(mineloMs);
	return { cyfry: String(o.sekunda), napis: o.napis, pluca: skalaPluc(o.pelnosc, ograniczRuch) };
}

