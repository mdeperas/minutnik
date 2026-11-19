export type RodzajFazy = 'napinanie' | 'rozluznienie';

export const kolory = {
	tlo: '#17181c',
	tor: '#353841',
	tekstDrugi: '#c1c3c8',
	napinanieObwod: 'hsl(190 80% 64%)',
	napinanieNapis: 'hsl(190 90% 84%)',
	rozluznienie: '#8fbfa3'
} as const;

export const najmniejszaSkala = 0.8;

export interface WygladFazy {
	rodzaj: RodzajFazy;
	kolorObwodu: string;
	kolorNapisu: string;
	zostaloObwodu: number;
	skala: number;
	cyfry: string;
}

export function rodzajFazy(nazwa: string): RodzajFazy {
	return nazwa.toLowerCase().startsWith('napin') ? 'napinanie' : 'rozluznienie';
}

export function wyroznia(rodzaj: RodzajFazy, etykieta: string): boolean {
	return rodzaj === 'napinanie' ? etykieta === 'Napnij' : etykieta === 'Puść' || etykieta === 'Poczuj';
}

export function cyfry(zostaloMs: number): string {
	const sekundy = Math.ceil(Math.max(0, zostaloMs) / 1000);
	if (sekundy < 60) return String(sekundy);
	return `${Math.floor(sekundy / 60)}:${String(sekundy % 60).padStart(2, '0')}`;
}

export function wygladFazy(nazwa: string, zostaloMs: number, czasMs: number, ograniczRuch: boolean): WygladFazy {
	const rodzaj = rodzajFazy(nazwa);
	const minelo = czasMs > 0 ? Math.min(1, Math.max(0, 1 - zostaloMs / czasMs)) : 1;
	const zmiana = (1 - najmniejszaSkala) * minelo;
	const napinanie = rodzaj === 'napinanie';
	return {
		rodzaj,
		kolorObwodu: napinanie ? kolory.napinanieObwod : kolory.rozluznienie,
		kolorNapisu: napinanie ? kolory.napinanieNapis : kolory.rozluznienie,
		zostaloObwodu: 1 - minelo,
		skala: ograniczRuch ? 1 : napinanie ? 1 - zmiana : najmniejszaSkala + zmiana,
		cyfry: cyfry(zostaloMs)
	};
}
