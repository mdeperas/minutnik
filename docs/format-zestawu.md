# Format zestawu ćwiczeń (wersja 1)

Wspólny plik JSON dla apki iOS i PWA. W apce czyta go `ExerciseCatalog`, w PWA `dekodujKatalog` (`web/src/katalog.ts`), oba z tym samym formatem.

Struktura: plik → zestawy → grupy → fazy. Fazy wykonuje się po kolei, każda grupa raz.

| Pole | Typ | Opis |
|---|---|---|
| `wersja` | liczba | Wersja formatu. Apka zna tylko `1`; inna → błąd „Nieznana wersja formatu zestawów”. |
| `zestawy[]` | lista | Zestawy do wyboru. |
| `zestawy[].nazwa` | tekst | Np. „12 grup”. |
| `zestawy[].grupy[]` | lista | Kroki zestawu (u PRM: grupy mięśni). |
| `grupy[].nazwa` | tekst | Np. „Przedramiona”. |
| `grupy[].fazy[]` | lista | Fazy grupy w kolejności; dowolna liczba i nazwy. |
| `fazy[].nazwa` | tekst | Np. „Napinanie”. |
| `fazy[].czasS` | liczba | Domyślny czas fazy w sekundach. |
| `fazy[].instrukcje` | obiekt, opcjonalny | Teksty: `jak`, `napnij`, `uwaga`, `pusc`, `poczuj` — każdy opcjonalny. |

PRM: każda grupa ma dwie fazy — „Napinanie” 10 s (`jak`, `napnij`, `uwaga`) i „Rozluźnienie” 50 s (`pusc`, `poczuj`).

Dwa pliki o tej samej strukturze i czasach:

- `web/zestawy-publiczne.json` (w repo): instrukcje własnymi słowami. Bierze go zawsze PWA i apka iOS, gdy nie ma pliku lokalnego.
- `lokalne/zestawy.json` (poza gitem, `.gitignore`): teksty z książki, tylko do apki iOS na własnym telefonie.
  Generuje go `bin/generuj-zestawy` (Node ≥ 22.18, bez pakietów) ze źródła `ZRODLO_PRM` w `lokalne/srodowisko.sh`.
  Build iOS kopiuje go do apki (`bin/zestawy-do-apki`, faza „Zestawy” w `project.yml`); bez niego kopiuje wariant publiczny.

Po regeneracji `bin/sprawdz-wariant-zestawow` pilnuje, że struktura wariantu publicznego zgadza się z plikiem lokalnym (bez pliku lokalnego sprawdza tylko niepuste teksty).

## Przykład

```json
{
  "wersja": 1,
  "zestawy": [
    {
      "nazwa": "12 grup",
      "grupy": [
        {
          "nazwa": "Przedramiona",
          "fazy": [
            {
              "nazwa": "Napinanie",
              "czasS": 10,
              "instrukcje": {
                "jak": "Ręce leżą swobodnie, dłonie wolne.",
                "napnij": "Zaciśnij pięści, poczuj napięcie w przedramionach.",
                "uwaga": "Ramiona zostają luźne, pracują tylko dłonie."
              }
            },
            {
              "nazwa": "Rozluźnienie",
              "czasS": 50,
              "instrukcje": { "pusc": "Rozwiń palce i zostaw dłonie bez ruchu.", "poczuj": "Dłonie robią się cięższe i cieplejsze." }
            }
          ]
        },
        { "nazwa": "Oddech", "fazy": [{ "nazwa": "Wdech", "czasS": 4 }, { "nazwa": "Wydech", "czasS": 6 }] }
      ]
    }
  ]
}
```
