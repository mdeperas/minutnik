# Muzyka w tle sesji

| Plik | Źródło | Autor | Licencja |
|---|---|---|---|
| `web/public/muzyka/synthwave.m4a` | wygenerowana skryptem `muzyka/generuj.py` (numpy/scipy, AAC 96 kbps przez `afconvert`) | projekt Minutnik | jak repo (własny utwór, bez cudzych próbek) |
| `web/public/muzyka/kosmos.m4a` | wygenerowana skryptem `muzyka/generuj.py` | projekt Minutnik | jak repo (własny utwór, bez cudzych próbek) |

Pętla 150 s, koniec przenika w początek (8 s), więc zapętlenie jest bez kliku.
Ponowne wygenerowanie: `python3 muzyka/generuj.py [synthwave|kosmos]` (deterministyczne, ziarno 7).
Las/natura: jeszcze nie ma (wymaga nagrań CC0, np. Freesound z filtrem CC0).
