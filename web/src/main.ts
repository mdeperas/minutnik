import surowe from 'virtual:zestawy';
import { dekodujKatalog } from './katalog';
import { otworzSesje } from './ekranSesji';
import { Aktualizacja } from './aktualizacja';
import { Historia } from './historia';
import { srodowiskoPrzegladarki } from './srodowisko';
import { minutyZestawu } from './tekstSesji';

const srodowisko = srodowiskoPrzegladarki(window.__minutnikPodrobki);
const listaEkran = document.querySelector<HTMLElement>('#lista-ekran')!;
const lista = document.querySelector<HTMLUListElement>('#zestawy')!;
const sesja = document.querySelector<HTMLElement>('#sesja')!;
const pytanie = document.querySelector<HTMLDialogElement>('#pytanie')!;
const historia = new Historia(srodowisko.magazynHistorii);

listaEkran.querySelector<HTMLElement>('.wersja')!.textContent = `Wersja ${__WERSJA__} · ${__DATA_WYDANIA__}`;
listaEkran.querySelector<HTMLElement>('.instalacja')!.hidden = srodowisko.zainstalowana();
const aktualizacja = new Aktualizacja(() => location.reload());
srodowisko.poNowejWersji(() => aktualizacja.nowaWersja());

try {
	dekodujKatalog(surowe).forEach((zestaw, indeks) => {
		const wiersz = document.createElement('li');
		const przycisk = document.createElement('button');
		przycisk.type = 'button';
		przycisk.className = indeks % 2 === 0 ? 'karta napinanie' : 'karta rozluznienie';
		const nazwa = document.createElement('span');
		nazwa.className = 'karta-nazwa';
		nazwa.textContent = zestaw.nazwa;
		const fakty = document.createElement('span');
		fakty.className = 'karta-fakty';
		for (const tekst of [minutyZestawu(zestaw)]) {
			const pigulka = document.createElement('span');
			pigulka.className = 'pigulka';
			pigulka.textContent = tekst;
			fakty.append(pigulka);
		}
		const start = document.createElement('span');
		start.className = 'karta-start';
		start.setAttribute('aria-hidden', 'true');
		start.textContent = 'Start ›';
		przycisk.setAttribute('aria-label', `${zestaw.nazwa}, ${minutyZestawu(zestaw)}`);
		przycisk.append(nazwa, fakty, start);
		przycisk.addEventListener('click', () => {
			listaEkran.hidden = true;
			aktualizacja.poczatekSesji();
			otworzSesje(zestaw, sesja, pytanie, srodowisko, historia, () => {
				aktualizacja.koniecSesji();
				listaEkran.hidden = false;
				przycisk.focus();
			});
		});
		wiersz.append(przycisk);
		lista.append(wiersz);
	});
} catch (blad) {
	const komunikat = document.createElement('p');
	komunikat.setAttribute('role', 'alert');
	komunikat.textContent = blad instanceof Error ? blad.message : String(blad);
	lista.replaceWith(komunikat);
}
