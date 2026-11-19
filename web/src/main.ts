import surowe from 'virtual:zestawy';
import { dekodujKatalog } from './katalog';
import { otworzSesje } from './ekranSesji';
import { Aktualizacja } from './aktualizacja';
import { Historia, kodujHistorie, opisWpisu, plikEksportu } from './historia';
import { srodowiskoPrzegladarki } from './srodowisko';
import { podsumowanie } from './tekstSesji';

const srodowisko = srodowiskoPrzegladarki(window.__minutnikPodrobki);
const listaEkran = document.querySelector<HTMLElement>('#lista-ekran')!;
const lista = document.querySelector<HTMLUListElement>('#zestawy')!;
const sesja = document.querySelector<HTMLElement>('#sesja')!;
const pytanie = document.querySelector<HTMLDialogElement>('#pytanie')!;
const sekcjaHistorii = document.querySelector<HTMLElement>('#historia')!;
const wpisy = sekcjaHistorii.querySelector<HTMLUListElement>('.wpisy')!;
const historia = new Historia(srodowisko.magazynHistorii);
const formatDaty = new Intl.DateTimeFormat('pl-PL', { day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' });

function pokazHistorie() {
	sekcjaHistorii.hidden = historia.wpisy.length === 0;
	wpisy.replaceChildren(
		...historia.odNajnowszych.map((wpis) => {
			const wiersz = document.createElement('li');
			const linie = [wpis.setName, formatDaty.format(new Date(wpis.startedAt)), opisWpisu(wpis)].map((tekst) => {
				const linia = document.createElement('span');
				linia.textContent = tekst;
				return linia;
			});
			linie[0].className = 'nazwa';
			wiersz.append(...linie);
			return wiersz;
		})
	);
}

sekcjaHistorii.querySelector('.eksport')!.addEventListener('click', () => {
	void srodowisko.udostepnij(new File([kodujHistorie(historia.wpisy)], plikEksportu, { type: 'application/json' }));
});
pokazHistorie();

listaEkran.querySelector<HTMLElement>('.wersja')!.textContent = `Wersja ${__WERSJA__}`;
listaEkran.querySelector<HTMLElement>('.instalacja')!.hidden = srodowisko.zainstalowana();
const aktualizacja = new Aktualizacja(() => location.reload());
srodowisko.poNowejWersji(() => aktualizacja.nowaWersja());

try {
	for (const zestaw of dekodujKatalog(surowe)) {
		const wiersz = document.createElement('li');
		const przycisk = document.createElement('button');
		przycisk.type = 'button';
		const nazwa = document.createElement('span');
		nazwa.textContent = zestaw.nazwa;
		const opis = document.createElement('span');
		opis.className = 'podsumowanie';
		opis.textContent = podsumowanie(zestaw);
		przycisk.append(nazwa, opis);
		przycisk.addEventListener('click', () => {
			listaEkran.hidden = true;
			aktualizacja.poczatekSesji();
			otworzSesje(zestaw, sesja, pytanie, srodowisko, historia, () => {
				aktualizacja.koniecSesji();
				pokazHistorie();
				listaEkran.hidden = false;
				przycisk.focus();
			});
		});
		wiersz.append(przycisk);
		lista.append(wiersz);
	}
} catch (blad) {
	const komunikat = document.createElement('p');
	komunikat.setAttribute('role', 'alert');
	komunikat.textContent = blad instanceof Error ? blad.message : String(blad);
	lista.replaceWith(komunikat);
}
