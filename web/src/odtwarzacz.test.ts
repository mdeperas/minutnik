import { describe, expect, it } from 'vitest';
import type { Zestaw } from './katalog';
import { Odtwarzacz, krokiZestawu, minioneFazy, sygnalPoZdarzeniach, type Krok } from './odtwarzacz';

const s = (sekundy: number) => sekundy * 1000;

function zestawProby(grupy = 3): Krok[] {
	return Array.from({ length: grupy }, (_, grupa) => [
		{ grupa, faza: 0, nazwa: 'Napinanie', czasMs: s(10) },
		{ grupa, faza: 1, nazwa: 'Rozluźnienie', czasMs: s(50) }
	]).flat();
}

function wystartowany(grupy = 3): Odtwarzacz {
	const o = new Odtwarzacz(zestawProby(grupy));
	o.start(0);
	return o;
}

const faza = (krok: number, sekundy: number) => ({ rodzaj: 'faza', krok, o: s(sekundy) });

describe('Odtwarzacz', () => {
	it('spłaszcza zestaw na kroki po kolei, czasy w ms', () => {
		const zestaw: Zestaw = {
			nazwa: 'Próba',
			grupy: [
				{ nazwa: 'A', fazy: [{ nazwa: 'Wdech', czasS: 4 }, { nazwa: 'Wydech', czasS: 6 }] },
				{ nazwa: 'B', fazy: [{ nazwa: 'Wdech', czasS: 2 }] }
			]
		};
		expect(krokiZestawu(zestaw)).toEqual([
			{ grupa: 0, faza: 0, nazwa: 'Wdech', czasMs: 4000 },
			{ grupa: 0, faza: 1, nazwa: 'Wydech', czasMs: 6000 },
			{ grupa: 1, faza: 0, nazwa: 'Wdech', czasMs: 2000 }
		]);
	});

	it('gotowy startuje zawsze od 1. fazy 1. grupy', () => {
		const o = new Odtwarzacz(zestawProby());
		expect(o.stan).toEqual({ rodzaj: 'gotowy' });
		expect(o.zostaloWSesji(0)).toBe(s(180));
		expect(o.start(0)).toEqual([faza(0, 0)]);
		expect(o.stan).toEqual({ rodzaj: 'trwa', krok: 0, poczatek: 0 });
	});

	it('start poza gotowym nic nie robi', () => {
		const o = wystartowany();
		expect(o.start(s(5))).toEqual([]);
		expect(o.stan).toEqual({ rodzaj: 'trwa', krok: 0, poczatek: 0 });
	});

	it('pusty zestaw kończy się od razu', () => {
		const o = new Odtwarzacz([]);
		expect(o.start(0)).toEqual([{ rodzaj: 'koniec', o: 0 }]);
		expect(o.stan).toEqual({ rodzaj: 'zakonczony' });
	});

	it('tik przed końcem fazy nic nie zmienia', () => {
		const o = wystartowany();
		expect(o.tik(9900)).toEqual([]);
		expect(o.zostaloWFazie(9900)).toBe(100);
	});

	it('koniec fazy startuje następną dokładnie w chwili końca', () => {
		const o = wystartowany();
		expect(o.tik(10400)).toEqual([faza(1, 10)]);
		expect(o.stan).toEqual({ rodzaj: 'trwa', krok: 1, poczatek: s(10) });
	});

	it('koniec ostatniej fazy kończy sesję', () => {
		const o = wystartowany(1);
		expect(o.tik(s(60))).toEqual([faza(1, 10), { rodzaj: 'koniec', o: s(60) }]);
		expect(o.stan).toEqual({ rodzaj: 'zakonczony' });
		expect(o.zostaloWSesji(s(60))).toBe(0);
	});

	it('skok o 3 min przechodzi przez wszystkie zaległe fazy', () => {
		const o = wystartowany(4);
		expect(o.tik(s(185))).toEqual([faza(1, 10), faza(2, 60), faza(3, 70), faza(4, 120), faza(5, 130), faza(6, 180)]);
		expect(o.stan).toEqual({ rodzaj: 'trwa', krok: 6, poczatek: s(180) });
		expect(o.zostaloWSesji(s(185))).toBe(s(55));
	});

	it('skok o 5 min w środku sesji ląduje w fazie, w której wypada teraz', () => {
		const o = wystartowany(8);
		o.tik(s(65));
		const zdarzenia = o.tik(s(365));
		expect(minioneFazy(zdarzenia)).toBe(10);
		expect(zdarzenia.at(-1)).toEqual(faza(12, 360));
		expect(o.stan).toEqual({ rodzaj: 'trwa', krok: 12, poczatek: s(360) });
		expect(o.zostaloWFazie(s(365))).toBe(s(5));
	});

	it('skok po końcu sesji kończy ją w planowej chwili', () => {
		const o = wystartowany(2);
		const zdarzenia = o.tik(s(500));
		expect(zdarzenia.at(-1)).toEqual({ rodzaj: 'koniec', o: s(120) });
		expect(minioneFazy(zdarzenia)).toBe(3);
		expect(o.stan).toEqual({ rodzaj: 'zakonczony' });
	});

	it('po nadrabianiu z tła jeden sygnał niezależnie od liczby faz', () => {
		const o = wystartowany(4);
		expect(sygnalPoZdarzeniach(o.tik(s(5)))).toBe(false);
		expect(sygnalPoZdarzeniach(o.tik(s(185)))).toBe(true);
		expect(sygnalPoZdarzeniach(o.tik(s(1000)))).toBe(true);
		expect(sygnalPoZdarzeniach([{ rodzaj: 'przerwana', o: 0 }])).toBe(false);
	});

	it('pauza zamraża pozostały czas i oś końców', () => {
		const o = wystartowany();
		expect(o.pauza(s(4))).toEqual([]);
		expect(o.stan).toEqual({ rodzaj: 'pauza', krok: 0, minelo: s(4) });
		expect(o.tik(s(400))).toEqual([]);
		expect(o.zostaloWFazie(s(400))).toBe(s(6));
		expect(o.zostaloWSesji(s(400))).toBe(s(176));
		expect(o.nadchodzaceKonce()).toEqual([]);
	});

	it('pauza po minionym końcu fazy najpierw nadrabia', () => {
		const o = wystartowany();
		expect(o.pauza(s(12))).toEqual([faza(1, 10)]);
		expect(o.stan).toEqual({ rodzaj: 'pauza', krok: 1, minelo: s(2) });
	});

	it('wznów liczy od teraz minus minione, bez dryfu', () => {
		const o = wystartowany();
		o.pauza(s(4));
		expect(o.wznow(s(100))).toEqual([]);
		expect(o.stan).toEqual({ rodzaj: 'trwa', krok: 0, poczatek: s(96) });
		expect(o.tik(105900)).toEqual([]);
		expect(o.tik(s(106))).toEqual([faza(1, 106)]);
	});

	it('wiele pauz i wznowień nie daje dryfu', () => {
		const o = wystartowany(1);
		let teraz = 0;
		for (let i = 0; i < 20; i++) {
			teraz += 1300;
			o.pauza(teraz);
			teraz += 7700;
			o.wznow(teraz);
		}
		expect(o.zostaloWSesji(teraz)).toBe(s(60 - 26));
	});

	it('wznów w trakcie nic nie robi', () => {
		const o = wystartowany();
		expect(o.wznow(s(3))).toEqual([]);
		expect(o.stan).toEqual({ rodzaj: 'trwa', krok: 0, poczatek: 0 });
	});

	it('pomiń przeskakuje jedną fazę, nie grupę', () => {
		const o = wystartowany();
		expect(o.pomin(s(3))).toEqual([faza(1, 3)]);
		expect(o.stan).toEqual({ rodzaj: 'trwa', krok: 1, poczatek: s(3) });
	});

	it('pomiń w pauzie zdejmuje pauzę', () => {
		const o = wystartowany();
		o.pauza(s(3));
		expect(o.pomin(s(30))).toEqual([faza(1, 30)]);
		expect(o.stan).toEqual({ rodzaj: 'trwa', krok: 1, poczatek: s(30) });
	});

	it('pomiń ostatnią fazę kończy sesję', () => {
		const o = wystartowany(1);
		o.pomin(s(1));
		expect(o.pomin(s(2))).toEqual([{ rodzaj: 'koniec', o: s(2) }]);
		expect(o.stan).toEqual({ rodzaj: 'zakonczony' });
	});

	it('pomiń ostatnią fazę w pauzie kończy sesję', () => {
		const o = wystartowany(1);
		o.pomin(s(1));
		o.pauza(s(2));
		expect(o.pomin(s(9))).toEqual([{ rodzaj: 'koniec', o: s(9) }]);
	});

	it('pomiń po długim tle pomija fazę, w której wypada teraz', () => {
		const o = wystartowany();
		expect(o.pomin(s(65))).toEqual([faza(1, 10), faza(2, 60), faza(3, 65)]);
	});

	it('przerwij kończy sesję bez końca i blokuje dalsze akcje', () => {
		const o = wystartowany();
		expect(o.przerwij(s(5))).toEqual([{ rodzaj: 'przerwana', o: s(5) }]);
		expect(o.stan).toEqual({ rodzaj: 'przerwany' });
		expect(o.pomin(s(6))).toEqual([]);
		expect(o.wznow(s(6))).toEqual([]);
		expect(o.zostaloWSesji(s(6))).toBe(0);
	});

	it('przerwij w pauzie', () => {
		const o = wystartowany();
		o.pauza(s(5));
		expect(o.przerwij(s(9))).toEqual([{ rodzaj: 'przerwana', o: s(9) }]);
	});

	it('przerwij w gotowym nic nie robi', () => {
		const o = new Odtwarzacz(zestawProby());
		expect(o.przerwij(0)).toEqual([]);
		expect(o.stan).toEqual({ rodzaj: 'gotowy' });
	});

	it('nadchodzące końce to cała reszta sesji', () => {
		const o = wystartowany(2);
		o.tik(s(15));
		expect(o.nadchodzaceKonce()).toEqual([
			{ krok: 1, o: s(60) },
			{ krok: 2, o: s(70) },
			{ krok: 3, o: s(120) }
		]);
	});

	it('nadchodzące końce przesuwają się po pauzie', () => {
		const o = wystartowany(1);
		o.pauza(s(5));
		o.wznow(s(25));
		expect(o.nadchodzaceKonce().map((k) => k.o)).toEqual([s(30), s(80)]);
	});

	it('zakończony ignoruje każdą akcję', () => {
		const o = wystartowany(1);
		o.tik(s(60));
		const t = s(61);
		expect([...o.pauza(t), ...o.wznow(t), ...o.pomin(t), ...o.przerwij(t), ...o.tik(t), ...o.start(t)]).toEqual([]);
		expect(o.stan).toEqual({ rodzaj: 'zakonczony' });
	});

	it('pauza z zegarem przed początkiem fazy zostawia pełną fazę', () => {
		const o = wystartowany();
		o.pauza(s(-3));
		expect(o.stan).toEqual({ rodzaj: 'pauza', krok: 0, minelo: 0 });
		expect(o.zostaloWFazie(s(-3))).toBe(s(10));
	});
});
