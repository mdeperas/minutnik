# Muzyka w tle sesji

| Plik | Źródło | Autor | Licencja |
|---|---|---|---|
| `web/public/muzyka/synthwave.m4a` | wygenerowana skryptem `muzyka/generuj.py` (numpy/scipy, AAC 96 kbps przez `afconvert`) | projekt Minutnik | jak repo (własny utwór, bez cudzych próbek) |
| `web/public/muzyka/kosmos.m4a` | wygenerowana skryptem `muzyka/generuj.py` | projekt Minutnik | jak repo (własny utwór, bez cudzych próbek) |
| `web/public/muzyka/las.m4a` | miks dwóch nagrań terenowych skryptem `muzyka/generuj.py` (las 1,0 + strumień 0,35 po wyrównaniu RMS, mono) | zob. niżej | CC0 + domena publiczna |

Nagrania w „Las” (pobierane przez skrypt, pamięć w `~/Library/Caches/minutnik-muzyka/`, nie w repo):

- Las wieczorem, śpiew ptaków: „Waidachswald Oberschefflenz Abend 20250616 2005.ogg”, autor Evillan (Wikimedia Commons), licencja CC0 1.0 —
  https://commons.wikimedia.org/wiki/File:Waidachswald_Oberschefflenz_Abend_20250616_2005.ogg
- Strumień w lesie: „Forest lawn creek.ogg”, autor Dsw4 (Wikimedia Commons), domena publiczna (autor zrzekł się praw) —
  https://commons.wikimedia.org/wiki/File:Forest_lawn_creek.ogg

Pętla 150 s, koniec przenika w początek (8 s), więc zapętlenie jest bez kliku.
Ponowne wygenerowanie: `python3 muzyka/generuj.py [synthwave|kosmos|las]` (deterministyczne, ziarno 7; `las` wymaga `ffmpeg` i sieci przy pierwszym razie).
