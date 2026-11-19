import { describe, expect, it } from 'vitest';
import { Historia, dataIso, dekodujHistorie, wynikSesji, kodujHistorie, opisWpisu, type Magazyn, type Wpis } from './historia';

const wpis = (setName: string, completed = true): Wpis => ({
	setName,
	startedAt: '2026-11-19T07:00:00Z',
	endedAt: '2026-11-19T07:14:40Z',
	completed,
	phasesDone: completed ? 24 : 5,
	phasesTotal: 24
});

function pamiec(poczatek: string | null = null): Magazyn & { tekst: string | null; zapisy: number } {
	return {
		tekst: poczatek,
		zapisy: 0,
		wczytaj() {
			return this.tekst;
		},
		zapisz(tekst) {
			this.tekst = tekst;
			this.zapisy++;
		}
	};
}

describe('format historii', () => {
	it('koduje klucze jak historia.json z apki i dekoduje z powrotem', () => {
		const tekst = kodujHistorie([wpis('A')]);
		expect(Object.keys(JSON.parse(tekst)[0])).toEqual(['completed', 'endedAt', 'phasesDone', 'phasesTotal', 'setName', 'startedAt']);
		expect(dekodujHistorie(tekst)).toEqual([wpis('A')]);
	});

	it('czyta plik zapisany przez apkę iOS', () => {
		const ios = '[\n  {\n    "completed" : false,\n    "endedAt" : "2026-11-19T07:05:00Z",\n    "phasesDone" : 3,\n    "phasesTotal" : 24,\n    "setName" : "PRM",\n    "startedAt" : "2026-11-19T07:00:00Z"\n  }\n]';
		expect(dekodujHistorie(ios)[0]).toMatchObject({ setName: 'PRM', phasesDone: 3, completed: false });
	});

	it('data bez milisekund, jak .iso8601 w Swifcie', () => {
		expect(dataIso(new Date(Date.UTC(2026, 10, 19, 7, 0, 0, 123)))).toBe('2026-11-19T07:00:00Z');
	});

	it('odrzuca zły kształt', () => {
		expect(() => dekodujHistorie('{}')).toThrow();
		expect(() => dekodujHistorie('[{"setName":"A"}]')).toThrow();
		expect(() => dekodujHistorie('nie json')).toThrow();
		expect(() => dekodujHistorie(JSON.stringify([{ ...wpis('A'), completed: "tak" }]))).toThrow();
	});

	it('opis: ukończona i przerwana z minutami', () => {
		expect(opisWpisu(wpis('A'))).toBe('Ukończona · 15 min');
		expect(opisWpisu(wpis('A', false))).toBe('Przerwana po 5 z 24 faz · 15 min');
	});
});

describe('wynikSesji', () => {
	it('bez końca i przerwania nie ma wpisu', () => {
		expect(wynikSesji([{ rodzaj: 'faza', krok: 1, o: 0 }], 0, 4)).toBeUndefined();
	});

	it('koniec liczy wszystkie fazy', () => {
		expect(wynikSesji([{ rodzaj: 'koniec', o: 0 }], 2, 4)).toEqual({ ukonczona: true, fazy: 4 });
	});

	it('przerwanie liczy fazy przed bieżącą, także po nadrobieniu', () => {
		expect(wynikSesji([{ rodzaj: 'przerwana', o: 0 }], 2, 4)).toEqual({ ukonczona: false, fazy: 2 });
		expect(wynikSesji([{ rodzaj: 'faza', krok: 3, o: 0 }, { rodzaj: 'przerwana', o: 0 }], 2, 4)).toEqual({ ukonczona: false, fazy: 3 });
	});
});

describe('Historia', () => {
	it('dopisuje i zapisuje, najnowsza na górze', () => {
		const m = pamiec();
		const h = new Historia(m);
		h.dodaj(wpis('A'));
		h.dodaj(wpis('B'));
		expect(h.odNajnowszych.map((w) => w.setName)).toEqual(['B', 'A']);
		expect(new Historia(m).wpisy).toHaveLength(2);
	});

	it('nieczytelny zapis nie zostaje nadpisany', () => {
		const m = pamiec('[{"zepsute"');
		const h = new Historia(m);
		h.dodaj(wpis('A'));
		expect(h.wpisy).toHaveLength(1);
		expect(m.tekst).toBe('[{"zepsute"');
		expect(m.zapisy).toBe(0);
	});

	it('błąd zapisu nie gubi wpisu w pamięci', () => {
		const h = new Historia({ wczytaj: () => null, zapisz: () => { throw new Error('pełno'); } });
		h.dodaj(wpis('A'));
		expect(h.wpisy).toHaveLength(1);
	});
});
