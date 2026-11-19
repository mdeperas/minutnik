import type { Magazyn } from './historia';
import type { Sygnal } from './sygnaly';

export interface Dzwiek {
	odblokuj(): void;
	zagraj(sygnal: Sygnal): void;
}

export type Wibracja = 'tik' | 'zmiana';

export interface Wibracje {
	wibruj(rodzaj: Wibracja): void;
}

export interface BlokadaEkranu {
	trzymaj(): Promise<boolean>;
	pusc(): void;
}

export interface Srodowisko {
	teraz(): number;
	naKlatke(akcja: () => void): void;
	ograniczRuch(): boolean;
	widoczna(): boolean;
	poZmianieWidocznosci(akcja: () => void): () => void;
	dzwiek: Dzwiek;
	ekran: BlokadaEkranu;
	wibracje: Wibracje;
	data(): Date;
	magazynHistorii: Magazyn;
	udostepnij(plik: File): Promise<void>;
	zainstalowana(): boolean;
	poNowejWersji(akcja: () => void): void;
}

export interface Podrobki {
	tempo?: number;
	dzwiek?: Dzwiek;
	ekran?: BlokadaEkranu;
	wibracje?: Wibracje;
	widoczna?: () => boolean;
}

declare global {
	interface Window {
		__minutnikPodrobki?: Podrobki;
	}
}

type Ton = [hz: number, sekundy: number, opoznienie: number];

const tony: Record<Sygnal, Ton[]> = {
	napinanie: [[660, 0.35, 0], [880, 0.45, 0.18]],
	rozluznienie: [[660, 0.35, 0], [440, 0.6, 0.18]],
	odliczanie: [[990, 0.12, 0]],
	koniec: [[523, 0.4, 0], [659, 0.4, 0.2], [784, 0.8, 0.4]]
};

function dzwiekWebAudio(): Dzwiek {
	let audio: AudioContext | undefined;
	const wznow = () => {
		if (audio && audio.state !== 'running') void audio.resume().catch(() => {});
	};
	return {
		odblokuj() {
			const Kontekst = window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
			if (!Kontekst) return;
			const sesjaAudio = (navigator as unknown as { audioSession?: { type: string } }).audioSession;
			if (sesjaAudio) sesjaAudio.type = 'playback';
			audio ??= new Kontekst();
			wznow();
		},
		zagraj(sygnal) {
			if (!audio) return;
			wznow();
			for (const [hz, sekundy, opoznienie] of tony[sygnal]) {
				const t = audio.currentTime + opoznienie;
				const oscylator = audio.createOscillator();
				const glosnosc = audio.createGain();
				oscylator.frequency.value = hz;
				glosnosc.gain.setValueAtTime(0.0001, t);
				glosnosc.gain.exponentialRampToValueAtTime(0.25, t + 0.02);
				glosnosc.gain.exponentialRampToValueAtTime(0.0001, t + sekundy);
				oscylator.connect(glosnosc).connect(audio.destination);
				oscylator.start(t);
				oscylator.stop(t + sekundy + 0.05);
			}
		}
	};
}

const wzoryWibracji: Record<Wibracja, number | number[]> = { tik: 40, zmiana: [80, 60, 80] };

const wibracjeNavigatora: Wibracje = {
	wibruj(rodzaj) {
		if (typeof navigator.vibrate === 'function') navigator.vibrate(wzoryWibracji[rodzaj]);
	}
};

function blokadaWakeLock(): BlokadaEkranu {
	let blokada: WakeLockSentinel | undefined;
	let potrzebna = false;
	return {
		async trzymaj() {
			potrzebna = true;
			if (!('wakeLock' in navigator)) return false;
			if (blokada) return true;
			try {
				const nowa = await navigator.wakeLock.request('screen');
				if (!potrzebna || blokada) {
					void nowa.release().catch(() => {});
					return true;
				}
				blokada = nowa;
				nowa.addEventListener('release', () => {
					if (blokada === nowa) blokada = undefined;
				});
				return true;
			} catch {
				return false;
			}
		},
		pusc() {
			potrzebna = false;
			void blokada?.release().catch(() => {});
			blokada = undefined;
		}
	};
}

const kluczHistorii = 'minutnik.historia';

const magazynLocalStorage: Magazyn = {
	wczytaj: () => localStorage.getItem(kluczHistorii),
	zapisz: (tekst) => localStorage.setItem(kluczHistorii, tekst)
};

async function udostepnijLubPobierz(plik: File): Promise<void> {
	if (navigator.canShare?.({ files: [plik] })) {
		await navigator.share({ files: [plik] }).catch(() => {});
		return;
	}
	const adres = URL.createObjectURL(plik);
	const link = document.createElement('a');
	link.href = adres;
	link.download = plik.name;
	link.click();
	setTimeout(() => URL.revokeObjectURL(adres), 60_000);
}

function zainstalowana() {
	return matchMedia('(display-mode: standalone)').matches || (navigator as Navigator & { standalone?: boolean }).standalone === true;
}

function obserwujNoweWersje(akcja: () => void) {
	if (!import.meta.env.PROD || !('serviceWorker' in navigator)) return;
	const sw = navigator.serviceWorker;
	let pierwszaInstalacja = !sw.controller;
	sw.addEventListener('controllerchange', () => {
		if (pierwszaInstalacja) pierwszaInstalacja = false;
		else akcja();
	});
	sw.register(`${import.meta.env.BASE_URL}sw.js`)
		.then((rejestracja) => {
			document.addEventListener('visibilitychange', () => {
				if (document.visibilityState === 'visible') void rejestracja.update().catch(() => {});
			});
		})
		.catch(() => {});
}

export function srodowiskoPrzegladarki(podrobki: Podrobki = {}): Srodowisko {
	const mnoznik = podrobki.tempo ?? 1;
	return {
		teraz: () => performance.now() * mnoznik,
		naKlatke: (akcja) => requestAnimationFrame(() => akcja()),
		ograniczRuch: () => matchMedia('(prefers-reduced-motion: reduce)').matches,
		widoczna: podrobki.widoczna ?? (() => document.visibilityState === 'visible'),
		poZmianieWidocznosci(akcja) {
			document.addEventListener('visibilitychange', akcja);
			return () => document.removeEventListener('visibilitychange', akcja);
		},
		dzwiek: podrobki.dzwiek ?? dzwiekWebAudio(),
		ekran: podrobki.ekran ?? blokadaWakeLock(),
		wibracje: podrobki.wibracje ?? wibracjeNavigatora,
		data: () => new Date(),
		magazynHistorii: magazynLocalStorage,
		udostepnij: udostepnijLubPobierz,
		zainstalowana,
		poNowejWersji: obserwujNoweWersje
	};
}
