import { dataIso, wynikSesji, type Historia } from './historia';
import type { Zestaw } from './katalog';
import { Odtwarzacz, krokiZestawu, type Zdarzenie } from './odtwarzacz';
import type { Srodowisko } from './srodowisko';
import { sygnalPoZmianie } from './sygnaly';
import { linieInstrukcji, minutySekundy, pozycjaGrupy } from './tekstSesji';
import { svgRyciny } from './ryciny';
import { widokSesji } from './widokSesji';
import { rodzajFazy, wygladFazy, wyroznia } from './wyglad';

type Akcja = 'start' | 'pauza' | 'wznow' | 'pomin' | 'przerwij' | 'koniec' | 'wroc' | 'dalej' | 'przerwij-i-wyjdz';

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
	let pokazanyKrok = -1;
	let otwarta = true;
	let ekranTrzymany = false;
	let poczatek: Date | undefined;

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
			cyfry.removeAttribute('aria-label');
			postep.style.strokeDashoffset = '1';
			svg.style.removeProperty('--skala');
			return;
		}
		if (krok !== pokazanyKrok) {
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
		if (sygnal) srodowisko.dzwiek.zagraj(sygnal);
		pilnujEkranu();
	};

	const dzialaj = (ruch: (teraz: number) => Zdarzenie[]) => {
		const krok = krokTeraz();
		poZdarzeniach(ruch(srodowisko.teraz()), krok);
	};

	const petla = () => {
		if (!otwarta) return;
		if (srodowisko.widoczna()) {
			dzialaj((t) => odtwarzacz.tik(t));
			rysuj();
		}
		srodowisko.naKlatke(petla);
	};

	const poPowrocie = () => {
		if (!otwarta || !srodowisko.widoczna()) return;
		dzialaj((t) => odtwarzacz.tik(t));
		if (wSesji()) trzymajEkran();
		rysuj();
	};

	const wyjdz = () => {
		otwarta = false;
		przestanSluchac();
		if (ekranTrzymany) srodowisko.ekran.pusc();
		ekran.removeEventListener('click', klik);
		pytanie.removeEventListener('click', klik);
		if (pytanie.open) pytanie.close();
		ekran.hidden = true;
		zamknij();
	};

	const akcje: Record<Akcja, () => void> = {
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
