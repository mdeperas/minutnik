import { dataIso, wynikSesji, type Historia } from './historia';
import type { Zestaw } from './katalog';
import { Odtwarzacz, krokiZestawu, type Zdarzenie } from './odtwarzacz';
import type { Srodowisko } from './srodowisko';
import { odliczaniePomiedzy, sygnalPoZmianie, type Chwila } from './sygnaly';
import { oddech, skalaPluc, zmianaEtapuPomiedzy } from './oddech';
import { linieInstrukcji, minutySekundy, pozycjaGrupy } from './tekstSesji';
import { svgRyciny } from './ryciny';
import { widokSesji } from './widokSesji';
import { rodzajFazy, wygladFazy, wyroznia } from './wyglad';

type Akcja = 'rycina' | 'start' | 'pauza' | 'wznow' | 'pomin' | 'przerwij' | 'koniec' | 'wroc' | 'dalej' | 'przerwij-i-wyjdz';

export function otworzSesje(zestaw: Zestaw, ekran: HTMLElement, pytanie: HTMLDialogElement, srodowisko: Srodowisko, historia: Historia, zamknij: () => void): void {
	const odtwarzacz = new Odtwarzacz(krokiZestawu(zestaw));
	const el = <T extends Element>(selektor: string) => ekran.querySelector<T>(selektor)!;
	const przycisk = (akcja: Akcja) => el<HTMLButtonElement>(`[data-akcja="${akcja}"]`);
	const svg = el<SVGSVGElement>('.pierscien svg');
	const postep = el<SVGCircleElement>('.postep');
	const cyfry = el<HTMLElement>('.cyfry');
	const faza = el<HTMLElement>('.faza');
	const grupa = el<HTMLElement>('.grupa');
	const pozycja = el<HTMLElement>('.pozycja');
	const zostaloSesji = el<HTMLElement>('.zostalo-sesji');
	const opis = el<HTMLDListElement>('.opis');
	const rycina = el<HTMLElement>('.rycina');
	const uwagaEkranu = el<HTMLElement>('.uwaga-ekran');
	const zaslona = el<HTMLElement>('.zaslona');
	let zwinRycine: ReturnType<typeof setTimeout> | undefined;
	const blokOddechu = el<HTMLElement>('.oddech');
	const obrysOddechu = el<SVGRectElement>('.oddech-obrys');
	const plucaOddechu = el<SVGRectElement>('.oddech-pluca');
	const etapOddechu = el<HTMLElement>('.oddech-etap');
	const sekundaOddechu = el<HTMLElement>('.oddech-sekunda');
	let pokazanyKrok = -1;
	let otwarta = true;
	let ekranTrzymany = false;
	let poczatek: Date | undefined;
	let ostatniaChwila: Chwila | undefined;

	el<HTMLElement>('.tytul').textContent = zestaw.nazwa;

	const pokazInstrukcje = (krok: number) => {
		const k = odtwarzacz.kroki[krok];
		const f = zestaw.grupy[k.grupa].fazy[k.faza];
		const rodzaj = rodzajFazy(k.nazwa);
		opis.replaceChildren(
			...linieInstrukcji(f.instrukcje).flatMap((linia) => {
				const dt = document.createElement('dt');
				dt.textContent = linia.etykieta;
				dt.classList.toggle('wyroznione', wyroznia(rodzaj, linia.etykieta));
				const dd = document.createElement('dd');
				dd.textContent = linia.tekst;
				return [dt, dd];
			})
		);
		grupa.textContent = zestaw.grupy[k.grupa].nazwa;
		pozycja.textContent = pozycjaGrupy(k.grupa, zestaw.grupy.length);
		faza.textContent = k.nazwa;
		const obraz = svgRyciny(zestaw.grupy[k.grupa].nazwa, rodzaj);
		rycina.hidden = !obraz;
		if (obraz && rycina.dataset.plik !== obraz.plik) {
			schowajRycine();
			rycina.dataset.plik = obraz.plik;
			rycina.innerHTML = obraz.svg;
		}
	};

	const rysuj = () => {
		const teraz = srodowisko.teraz();
		const stan = odtwarzacz.stan;
		const widok = widokSesji(stan);
		for (const [akcja, widac] of Object.entries(widok.przyciski)) przycisk(akcja as Akcja).hidden = !widac;
		const sesjaZegar = minutySekundy(odtwarzacz.zostaloWSesji(teraz));
		zostaloSesji.textContent = `Zostało ${sesjaZegar}`;
		zostaloSesji.setAttribute('aria-label', `Cała sesja: ${sesjaZegar}`);
		const krok = widok.krok;
		ekran.dataset.stan = krok === undefined ? 'koniec' : stan.rodzaj;
		if (krok === undefined) {
			cyfry.textContent = widok.napisKonca ?? '';
			faza.textContent = '';
			rycina.hidden = true;
			blokOddechu.hidden = true;
			cyfry.removeAttribute('aria-label');
			postep.style.strokeDashoffset = '1';
			svg.style.removeProperty('--skala');
			return;
		}
		if (krok !== pokazanyKrok) {
			if (pokazanyKrok >= 0 && !srodowisko.ograniczRuch()) obrocPierscien();
			pokazanyKrok = krok;
			pokazInstrukcje(krok);
		}
		const k = odtwarzacz.kroki[krok];
		const zostalo = stan.rodzaj === 'gotowy' ? k.czasMs : odtwarzacz.zostaloWFazie(teraz);
		const wyglad = wygladFazy(k.nazwa, zostalo, k.czasMs, srodowisko.ograniczRuch());
		ekran.dataset.faza = wyglad.rodzaj;
		cyfry.textContent = wyglad.cyfry;
		cyfry.setAttribute('aria-label', `Zostało ${minutySekundy(zostalo)}`);
		postep.style.strokeDashoffset = String(1 - wyglad.zostaloObwodu);
		svg.style.setProperty('--skala', String(wyglad.skala));
		rysujOddech(wyglad.rodzaj === 'rozluznienie' && stan.rodzaj !== 'gotowy', k.czasMs - zostalo);
	};

	const obrocPierscien = () => {
		svg.animate([{ rotate: '0deg' }, { rotate: '360deg' }], { duration: 900, easing: 'cubic-bezier(0.2, 0.8, 0.2, 1)' });
	};

	const schowajRycine = () => {
		clearTimeout(zwinRycine);
		zwinRycine = undefined;
		rycina.classList.remove('powiekszona');
		rycina.style.removeProperty('transform');
		zaslona.classList.remove('widac');
	};

	const powiekszRycine = () => {
		if (zwinRycine !== undefined) return schowajRycine();
		if (rycina.hidden) return;
		const r = rycina.getBoundingClientRect();
		const skala = Math.min((innerWidth * 0.9) / r.width, (innerHeight * 0.7) / r.height);
		const dx = innerWidth / 2 - (r.left + r.width / 2);
		const dy = innerHeight / 2 - (r.top + r.height / 2);
		zaslona.hidden = false;
		void zaslona.offsetWidth;
		zaslona.classList.add('widac');
		rycina.classList.add('powiekszona');
		rycina.style.transform = `translate(${dx}px, ${dy}px) scale(${skala})`;
		zwinRycine = setTimeout(schowajRycine, 2_500);
	};

	const rysujOddech = (widac: boolean, mineloMs: number) => {
		blokOddechu.hidden = !widac;
		if (!widac) return;
		const o = oddech(mineloMs);
		blokOddechu.dataset.etap = o.etap;
		if (etapOddechu.textContent !== o.napis) etapOddechu.textContent = o.napis;
		sekundaOddechu.textContent = String(o.sekunda);
		obrysOddechu.style.strokeDashoffset = String(1 - o.postepCyklu);
		plucaOddechu.style.setProperty('--oddech', String(skalaPluc(o.pelnosc, srodowisko.ograniczRuch())));
	};

	const wSesji = () => odtwarzacz.stan.rodzaj === 'trwa' || odtwarzacz.stan.rodzaj === 'pauza';

	const trzymajEkran = () => {
		ekranTrzymany = true;
		void srodowisko.ekran.trzymaj().then((trzyma) => {
			if (otwarta) uwagaEkranu.hidden = trzyma;
		});
	};

	const pilnujEkranu = () => {
		if (wSesji() && !ekranTrzymany) trzymajEkran();
		if (!wSesji() && ekranTrzymany) {
			ekranTrzymany = false;
			srodowisko.ekran.pusc();
		}
	};

	const krokTeraz = () => {
		const stan = odtwarzacz.stan;
		return stan.rodzaj === 'trwa' || stan.rodzaj === 'pauza' ? stan.krok : 0;
	};

	const zapiszWpis = (zdarzenia: Zdarzenie[], krokPrzed: number) => {
		const wynik = wynikSesji(zdarzenia, krokPrzed, odtwarzacz.kroki.length);
		if (!wynik || !poczatek) return;
		historia.dodaj({
			setName: zestaw.nazwa,
			startedAt: dataIso(poczatek),
			endedAt: dataIso(srodowisko.data()),
			completed: wynik.ukonczona,
			phasesDone: wynik.fazy,
			phasesTotal: odtwarzacz.kroki.length
		});
		poczatek = undefined;
	};

	const poZdarzeniach = (zdarzenia: Zdarzenie[], krokPrzed: number) => {
		zapiszWpis(zdarzenia, krokPrzed);
		const sygnal = sygnalPoZmianie(zdarzenia, odtwarzacz.kroki);
		if (sygnal) {
			srodowisko.dzwiek.zagraj(sygnal);
			srodowisko.wibracje.wibruj('zmiana');
		}
		pilnujEkranu();
	};

	const dzialaj = (ruch: (teraz: number) => Zdarzenie[]) => {
		const krok = krokTeraz();
		poZdarzeniach(ruch(srodowisko.teraz()), krok);
	};

	const chwilaTeraz = (): Chwila | undefined => {
		const stan = odtwarzacz.stan;
		return stan.rodzaj === 'trwa' ? { krok: stan.krok, zostalo: odtwarzacz.zostaloWFazie(srodowisko.teraz()) } : undefined;
	};

	const zmianaOddechu = (przed: Chwila | undefined, teraz: Chwila | undefined) => {
		if (!teraz) return false;
		const k = odtwarzacz.kroki[teraz.krok];
		return zmianaEtapuPomiedzy(przed, teraz, k.czasMs, rodzajFazy(k.nazwa));
	};

	const odliczaj = () => {
		const chwila = chwilaTeraz();
		const tik = odliczaniePomiedzy(ostatniaChwila, chwila);
		if (tik) srodowisko.dzwiek.zagraj('odliczanie');
		if (tik || zmianaOddechu(ostatniaChwila, chwila)) srodowisko.wibracje.wibruj('tik');
		ostatniaChwila = chwila;
	};

	const petla = () => {
		if (!otwarta) return;
		if (srodowisko.widoczna()) {
			dzialaj((t) => odtwarzacz.tik(t));
			odliczaj();
			rysuj();
		}
		srodowisko.naKlatke(petla);
	};

	const poPowrocie = () => {
		if (!otwarta || !srodowisko.widoczna()) return;
		dzialaj((t) => odtwarzacz.tik(t));
		ostatniaChwila = chwilaTeraz();
		if (wSesji()) trzymajEkran();
		rysuj();
	};

	const wyjdz = () => {
		otwarta = false;
		schowajRycine();
		przestanSluchac();
		if (ekranTrzymany) srodowisko.ekran.pusc();
		ekran.removeEventListener('click', klik);
		pytanie.removeEventListener('click', klik);
		if (pytanie.open) pytanie.close();
		ekran.hidden = true;
		zamknij();
	};

	const akcje: Record<Akcja, () => void> = {
		rycina: powiekszRycine,
		start: () => {
			srodowisko.dzwiek.odblokuj();
			poczatek = srodowisko.data();
			dzialaj((t) => odtwarzacz.start(t));
		},
		pauza: () => dzialaj((t) => odtwarzacz.pauza(t)),
		wznow: () => dzialaj((t) => odtwarzacz.wznow(t)),
		pomin: () => dzialaj((t) => odtwarzacz.pomin(t)),
		przerwij: () => dzialaj((t) => odtwarzacz.przerwij(t)),
		koniec: wyjdz,
		wroc: () => (widokSesji(odtwarzacz.stan).wrocPyta ? pytanie.showModal() : wyjdz()),
		dalej: () => pytanie.close(),
		'przerwij-i-wyjdz': () => {
			dzialaj((t) => odtwarzacz.przerwij(t));
			wyjdz();
		}
	};

	function klik(zdarzenie: Event) {
		const akcja = (zdarzenie.target as Element).closest<HTMLElement>('[data-akcja]')?.dataset.akcja as Akcja | undefined;
		if (!akcja || !(akcja in akcje)) return;
		akcje[akcja]();
		if (otwarta) rysuj();
	}

	const przestanSluchac = srodowisko.poZmianieWidocznosci(poPowrocie);
	ekran.addEventListener('click', klik);
	pytanie.addEventListener('click', klik);
	uwagaEkranu.hidden = true;
	ekran.hidden = false;
	rysuj();
	przycisk('start').focus();
	petla();
}
