import type { Krok } from './odtwarzacz';
import { oddech } from './oddech';
import { odliczaniePomiedzy, type Chwila, type Sygnal } from './sygnaly';
import { rodzajFazy } from './wyglad';

export type Wibracja = 'tik' | 'zmiana';

export const wzoryWibracji: Record<Wibracja, number | number[]> = { tik: 40, zmiana: [80, 60, 80] };

export function wibracjaPoSygnale(sygnal: Sygnal | undefined): Wibracja | undefined {
	return sygnal ? 'zmiana' : undefined;
}

function zmianaEtapuOddechu(przed: Chwila, teraz: Chwila, krok: Krok): boolean {
	if (rodzajFazy(krok.nazwa) !== 'rozluznienie') return false;
	return oddech(krok.czasMs - teraz.zostalo).numer !== oddech(krok.czasMs - przed.zostalo).numer;
}

export function wibracjaPomiedzy(przed: Chwila | undefined, teraz: Chwila | undefined, kroki: readonly Krok[]): Wibracja | undefined {
	if (!przed || !teraz || przed.krok !== teraz.krok || teraz.zostalo <= 0) return undefined;
	if (odliczaniePomiedzy(przed, teraz) || zmianaEtapuOddechu(przed, teraz, kroki[teraz.krok])) return 'tik';
	return undefined;
}

export function wibruj(wibracja: Wibracja | undefined, vibrate: ((wzor: number | number[]) => boolean) | undefined): void {
	if (wibracja && typeof vibrate === 'function') vibrate(wzoryWibracji[wibracja]);
}
