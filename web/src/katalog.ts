export interface Instrukcje {
	jak?: string;
	napnij?: string;
	uwaga?: string;
	pusc?: string;
	poczuj?: string;
}

export interface Faza {
	nazwa: string;
	czasS: number;
	instrukcje?: Instrukcje;
}

export interface Grupa {
	nazwa: string;
	fazy: Faza[];
}

export interface Zestaw {
	nazwa: string;
	grupy: Grupa[];
}

export class BladKatalogu extends Error {}

const kluczeInstrukcji = ['jak', 'napnij', 'uwaga', 'pusc', 'poczuj'] as const;

type Obiekt = Record<string, unknown>;

function bladW(gdzie: string): BladKatalogu {
	return new BladKatalogu(`Błędny plik zestawów: ${gdzie}`);
}

function obiekt(wartosc: unknown, gdzie: string): Obiekt {
	if (typeof wartosc !== 'object' || wartosc === null || Array.isArray(wartosc)) throw bladW(gdzie);
	return wartosc as Obiekt;
}

function lista(wartosc: unknown, gdzie: string): unknown[] {
	if (!Array.isArray(wartosc)) throw bladW(gdzie);
	return wartosc;
}

function tekst(wartosc: unknown, gdzie: string): string {
	if (typeof wartosc !== 'string') throw bladW(gdzie);
	return wartosc;
}

function instrukcje(wartosc: unknown, gdzie: string): Instrukcje | undefined {
	if (wartosc === undefined) return undefined;
	const o = obiekt(wartosc, gdzie);
	const wynik: Instrukcje = {};
	for (const klucz of kluczeInstrukcji) {
		if (o[klucz] !== undefined) wynik[klucz] = tekst(o[klucz], `${gdzie}.${klucz}`);
	}
	return wynik;
}

function faza(wartosc: unknown, gdzie: string): Faza {
	const o = obiekt(wartosc, gdzie);
	const czasS = o.czasS;
	if (typeof czasS !== 'number' || !Number.isFinite(czasS) || czasS <= 0) throw bladW(`${gdzie}.czasS`);
	const wynik: Faza = { nazwa: tekst(o.nazwa, `${gdzie}.nazwa`), czasS };
	const opis = instrukcje(o.instrukcje, `${gdzie}.instrukcje`);
	if (opis) wynik.instrukcje = opis;
	return wynik;
}

function grupa(wartosc: unknown, gdzie: string): Grupa {
	const o = obiekt(wartosc, gdzie);
	return {
		nazwa: tekst(o.nazwa, `${gdzie}.nazwa`),
		fazy: lista(o.fazy, `${gdzie}.fazy`).map((f, i) => faza(f, `${gdzie}.fazy[${i}]`))
	};
}

function zestaw(wartosc: unknown, gdzie: string): Zestaw {
	const o = obiekt(wartosc, gdzie);
	return {
		nazwa: tekst(o.nazwa, `${gdzie}.nazwa`),
		grupy: lista(o.grupy, `${gdzie}.grupy`).map((g, i) => grupa(g, `${gdzie}.grupy[${i}]`))
	};
}

export function dekodujKatalog(surowe: unknown): Zestaw[] {
	const plik = obiekt(surowe, 'plik');
	if (plik.wersja !== 1) throw new BladKatalogu('Nieznana wersja formatu zestawów');
	return lista(plik.zestawy, 'zestawy').map((z, i) => zestaw(z, `zestawy[${i}]`));
}
