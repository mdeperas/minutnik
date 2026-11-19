import type { Krok, Zdarzenie } from './odtwarzacz';
import { rodzajFazy } from './wyglad';

export type Sygnal = 'napinanie' | 'rozluznienie' | 'koniec';

export function sygnalPoZmianie(zdarzenia: readonly Zdarzenie[], kroki: readonly Krok[]): Sygnal | undefined {
	const ostatnie = zdarzenia.filter((z) => z.rodzaj !== 'przerwana').at(-1);
	if (!ostatnie) return undefined;
	if (ostatnie.rodzaj === 'koniec') return 'koniec';
	if (ostatnie.rodzaj === 'faza') return rodzajFazy(kroki[ostatnie.krok].nazwa);
	return undefined;
}
