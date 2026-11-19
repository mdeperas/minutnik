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

PRM: jeden zestaw „12 grup” = krok „Wstęp” (faza „Wstęp” 30 s), 12 grup mięśni z dwiema fazami — „Napinanie” 10 s (`jak`, `napnij`, `uwaga`) i „Rozluźnienie” 50 s (`pusc`, `poczuj`), potem „Pełny relaks” (faza „Relaks” 2 min) i „Powrót” (faza „Powrót” 30 s); kroki bez napinania mają tekst w `jak`.

Grupa mięśni = grupa z fazą, której nazwa zaczyna się od „Napin”. Tylko takie liczą się do „Grupa N z M” i liczby grup na karcie zestawu i tylko one mają ryciny. Każda inna faza wygląda jak rozluźnienie (szałwia, oddech pudełkowy).

Dwa pliki o tej samej strukturze i czasach:

- `web/zestawy-publiczne.json` (w repo): te same teksty co w apce iOS (kopia 1:1 `lokalne/zestawy.json`). Bierze go zawsze PWA i apka iOS, gdy nie ma pliku lokalnego.
- `lokalne/zestawy.json` (poza gitem, `.gitignore`): teksty z książki, tylko do apki iOS na własnym telefonie.
  Generuje go `bin/generuj-zestawy` (Node ≥ 22.18, bez pakietów) z `lokalne/prm-ksiazka.json` (teksty z książki: `wstep`, `relaks`, `powrot`, `grupy[]` z instrukcjami napinania i rozluźnienia; wzór w `lokalne.example/`); czasy i nazwy faz dokłada generator.
  Źródłem nie jest `grupy-prm.ts` z kursu, bo ten plik jest wspólny ze stronami kursu i nie może mieć tekstów książki.
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
