export interface Sekcja {
	naglowek: string;
	akapity: string[];
	punkty: string[];
}

export interface TekstDoCzytania {
	tytul: string;
	sekcje: Sekcja[];
	zrodlo: string;
}

export class BladTekstu extends Error {}

type Obiekt = Record<string, unknown>;

const blad = (gdzie: string) => new BladTekstu(`Błędny tekst „O ćwiczeniu”: ${gdzie}`);

function obiekt(wartosc: unknown, gdzie: string): Obiekt {
	if (typeof wartosc !== 'object' || wartosc === null || Array.isArray(wartosc)) throw blad(gdzie);
	return wartosc as Obiekt;
}

function tekst(wartosc: unknown, gdzie: string): string {
	if (typeof wartosc !== 'string' || wartosc.trim() === '') throw blad(gdzie);
	return wartosc;
}

function teksty(wartosc: unknown, gdzie: string): string[] {
	if (wartosc === undefined) return [];
	if (!Array.isArray(wartosc)) throw blad(gdzie);
	return wartosc.map((w, i) => tekst(w, `${gdzie}[${i}]`));
}

export function dekodujTekst(surowe: unknown): TekstDoCzytania {
	const plik = obiekt(surowe, 'plik');
	if (!Array.isArray(plik.sekcje) || plik.sekcje.length === 0) throw blad('sekcje');
	return {
		tytul: tekst(plik.tytul, 'tytul'),
		zrodlo: tekst(plik.zrodlo, 'zrodlo'),
		sekcje: plik.sekcje.map((s, i) => {
			const sekcja = obiekt(s, `sekcje[${i}]`);
			const wynik = {
				naglowek: tekst(sekcja.naglowek, `sekcje[${i}].naglowek`),
				akapity: teksty(sekcja.akapity, `sekcje[${i}].akapity`),
				punkty: teksty(sekcja.punkty, `sekcje[${i}].punkty`)
			};
			if (wynik.akapity.length + wynik.punkty.length === 0) throw blad(`sekcje[${i}] bez treści`);
			return wynik;
		})
	};
}
