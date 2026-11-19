export class Aktualizacja {
	private czeka = false;
	private wSesji = false;

	constructor(private readonly przeladuj: () => void) {}

	nowaWersja() {
		this.czeka = true;
		this.sprobuj();
	}

	poczatekSesji() {
		this.wSesji = true;
	}

	koniecSesji() {
		this.wSesji = false;
		this.sprobuj();
	}

	private sprobuj() {
		if (!this.czeka || this.wSesji) return;
		this.czeka = false;
		this.przeladuj();
	}
}
