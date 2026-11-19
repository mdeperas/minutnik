import type { Krok, Zdarzenie } from './odtwarzacz';
import { rodzajFazy } from './wyglad';

export type Sygnal = 'napinanie' | 'rozluznienie' | 'koniec' | 'odliczanie';

export interface Chwila {
	krok: number;
	zostalo: number;
}

const progiOdliczania = [3_000, 2_000, 1_000];

export function odliczaniePomiedzy(przed: Chwila | undefined, teraz: Chwila | undefined): boolean {
	if (!przed || !teraz || przed.krok !== teraz.krok) return false;
	return progiOdliczania.some((prog) => teraz.zostalo <= prog && prog < przed.zostalo && teraz.zostalo > 0);
}

export function sygnalPoZmianie(zdarzenia: readonly Zdarzenie[], kroki: readonly Krok[]): Sygnal | undefined {
	const ostatnie = zdarzenia.filter((z) => z.rodzaj !== 'przerwana').at(-1);
	if (!ostatnie) return undefined;
	if (ostatnie.rodzaj === 'koniec') return 'koniec';
	if (ostatnie.rodzaj === 'faza') return rodzajFazy(kroki[ostatnie.krok].nazwa);
	return undefined;
}
