import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
DLUGOSC = 150.0
PRZENIKANIE = 8.0
CEL = Path(__file__).resolve().parent.parent / "web" / "public" / "muzyka"


def czas(sekundy):
    return np.arange(int(sekundy * SR)) / SR


def hz(nuta):
    return 440.0 * 2 ** ((nuta - 69) / 12)


def dolnoprzepustowy(sygnal, granica):
    return sosfilt(butter(2, granica, fs=SR, output="sos"), sygnal)


def obwiednia(n, atak, zanik):
    e = np.ones(n)
    a, z = int(atak * SR), int(zanik * SR)
    e[:a] = np.linspace(0, 1, a)
    e[-z:] *= np.linspace(1, 0, z)
    return e


def pila(f, t, faza=0.0):
    return 2 * ((f * t + faza) % 1) - 1


def synthwave(los):
    calosc = DLUGOSC + PRZENIKANIE
    wyjscie = np.zeros(int(calosc * SR) + SR * 4)
    akordy = [[57, 60, 64, 67], [53, 57, 60, 64], [48, 52, 55, 59], [55, 59, 62, 66]]
    takt = 8.0
    for i in range(int(calosc / takt) + 1):
        akord = akordy[i % len(akordy)]
        start = int(i * takt * SR)
        t = czas(takt + 2)
        pad = np.zeros_like(t)
        for nuta in akord:
            for odstrojenie in (-0.12, 0.0, 0.12):
                pad += pila(hz(nuta + odstrojenie), t, los.random())
        pad = dolnoprzepustowy(pad, 900) * obwiednia(len(t), 2.0, 2.5) * 0.05
        bas = np.sin(2 * np.pi * hz(akord[0] - 24) * t) * obwiednia(len(t), 1.0, 2.0) * 0.22
        wyjscie[start:start + len(t)] += pad + bas
        for k in range(16):
            nuta = akord[[0, 2, 1, 3][k % 4]] + 12
            t2 = czas(0.9)
            ton = (np.sin(2 * np.pi * hz(nuta) * t2) + 0.3 * np.sin(4 * np.pi * hz(nuta) * t2)) * np.exp(-t2 * 5) * 0.06
            p = start + int(k * takt / 16 * SR)
            wyjscie[p:p + len(t2)] += ton
    echo = int(0.375 * SR)
    for _ in range(3):
        wyjscie[echo:] += 0.35 * wyjscie[:-echo]
    return wyjscie[: int(calosc * SR)]


def kosmos(los):
    calosc = DLUGOSC + PRZENIKANIE
    t = czas(calosc)
    wyjscie = np.zeros_like(t)
    for nuta, okres in ((38, 41.0), (45, 53.0), (50, 37.0), (57, 61.0), (62, 47.0)):
        lfo = 0.5 + 0.5 * np.sin(2 * np.pi * t / okres + los.random() * 6.28)
        ton = sum(np.sin(2 * np.pi * hz(nuta + d) * t) for d in (-0.07, 0.0, 0.07))
        wyjscie += ton * lfo * 0.05
    szum = dolnoprzepustowy(los.standard_normal(len(t)), 400)
    wyjscie += szum * (0.5 + 0.5 * np.sin(2 * np.pi * t / 23.0)) * 0.08
    for _ in range(40):
        p = int(los.random() * (calosc - 6) * SR)
        nuta = los.choice([74, 76, 79, 81, 86])
        t2 = czas(6)
        wyjscie[p:p + len(t2)] += np.sin(2 * np.pi * hz(nuta) * t2) * np.exp(-t2 * 0.8) * obwiednia(len(t2), 0.3, 0.5) * 0.025
    return wyjscie


def zapetl(sygnal):
    n, x = int(DLUGOSC * SR), int(PRZENIKANIE * SR)
    petla = sygnal[:n].copy()
    w = np.linspace(0, np.pi / 2, x)
    petla[:x] = sygnal[:x] * np.sin(w) + sygnal[n:n + x] * np.cos(w)
    return petla / np.max(np.abs(petla)) * 0.7


def zapisz(nazwa, sygnal):
    with tempfile.TemporaryDirectory() as katalog:
        wav = Path(katalog) / "p.wav"
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((sygnal * 32767).astype("<i2").tobytes())
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "96000", str(wav), str(CEL / f"{nazwa}.m4a")], check=True)


if __name__ == "__main__":
    CEL.mkdir(parents=True, exist_ok=True)
    for nazwa, utworz in (("synthwave", synthwave), ("kosmos", kosmos)):
        if len(sys.argv) > 1 and nazwa not in sys.argv[1:]:
            continue
        zapisz(nazwa, zapetl(utworz(np.random.default_rng(7))))
