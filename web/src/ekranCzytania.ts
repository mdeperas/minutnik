import type { TekstDoCzytania } from './oCwiczeniu';

export function wypelnijCzytanie(ekran: HTMLElement, tekst: TekstDoCzytania) {
	ekran.querySelector<HTMLElement>('.tytul')!.textContent = tekst.tytul;
	const tresc = ekran.querySelector<HTMLElement>('.tresc')!;
	for (const sekcja of tekst.sekcje) {
		const blok = document.createElement('section');
		const naglowek = document.createElement('h2');
		naglowek.textContent = sekcja.naglowek;
		blok.append(naglowek);
		for (const akapit of sekcja.akapity) {
			const p = document.createElement('p');
			p.textContent = akapit;
			blok.append(p);
		}
		if (sekcja.punkty.length) {
			const lista = document.createElement('ul');
			for (const punkt of sekcja.punkty) {
				const li = document.createElement('li');
				li.textContent = punkt;
				lista.append(li);
			}
			blok.append(lista);
		}
		tresc.append(blok);
	}
	const zrodlo = document.createElement('p');
	zrodlo.className = 'zrodlo';
	zrodlo.textContent = tekst.zrodlo;
	tresc.append(zrodlo);
}

export function polaczCzytanie(ekran: HTMLElement, start: HTMLElement, otworz: HTMLButtonElement) {
	otworz.addEventListener('click', () => {
		start.hidden = true;
		ekran.hidden = false;
		ekran.scrollTop = 0;
		ekran.querySelector<HTMLElement>('.wroc')!.focus();
	});
	for (const wroc of ekran.querySelectorAll<HTMLButtonElement>('[data-akcja="wroc"]')) {
		wroc.addEventListener('click', () => {
			ekran.hidden = true;
			start.hidden = false;
			otworz.focus();
		});
	}
}
