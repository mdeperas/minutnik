# Minutnik

Apka iOS (SwiftUI, iOS 17+): odtwarzacz kroków ćwiczeń (zestaw → grupy → fazy z czasami), pierwszy zestaw PRM;
dźwięk w tle przez background audio. Stan: lista zestawów → ekran odtwarzacza (grupa, faza, instrukcje, haptyka), sygnały w tle, historia sesji lokalnie (`historia.json` w Application Support) z eksportem JSON. Rozpoznanie: `docs/research/`.
Wzorzec projektu: apka Thread Cam (tam nic nie zmieniamy).

## Środowisko
- Kopia źródeł: remote `origin` = prywatne `mdeperas/minutnik-zrodla` (`git push origin --all`); publiczne `mdeperas/minutnik` dostaje tylko PWA przez `bin/publikuj`, kodu tam nie pushujemy. `lokalne/` jest poza gitem i poza kopią.

- Darmowe Apple ID (Personal Team, ID w `lokalne/podpis.xcconfig`): brak iCloud capability, App Groups niepewne,
  najwyżej 3 apki na telefonie (Thread Cam + Minutnik), podpis ważny 7 dni od pobrania profilu, niezależnie od Thread Cam.
- Projekt Xcode generuje `xcodegen` z `project.yml`; `Minutnik.xcodeproj/` i `build/` są w `.gitignore`.
- Prywatne wartości żyją tylko w `lokalne/` (w `.gitignore`; wzór w `lokalne.example/`, raz po klonie `cp -R lokalne.example lokalne`):
  `srodowisko.sh` (ID iPhone'a), `podpis.xcconfig` (Team ID, przez `Minutnik.xcconfig`), `zakazane.txt` (frazy, które nie mogą wyjść publicznie; linia `!fraza` = wyjątek wycinany przed sprawdzeniem, np. login `!mdeperas`),
  `prm-ksiazka.json` (teksty PRM z książki, źródło) i `zestawy.json` (z niego `bin/generuj-zestawy`), `o-cwiczeniu.json` (ekran „O ćwiczeniu” w apce, blisko książki; wzór formatu w `lokalne.example/`). Bez `lokalne/` testy i build na symulatorze idą na `web/zestawy-publiczne.json`.
- Publiczna kopia: `bin/przygotuj-publiczne [katalog]` (domyślnie `~/Repositories/minutnik-publiczne`) robi z HEAD nowe repo z jednym commitem,
  bez `docs/research/`, i sprawdza je `bin/sprawdz-publiczne.ts` (prywatne wartości z `lokalne/`, e-mail z gita, `$HOME`, frazy 5 słów z `lokalne/o-cwiczeniu.json`).
  Historia tego repo zostaje prywatna; publikujemy tylko tę kopię.
- Publikacja: publiczne repo `mdeperas/minutnik`, strona `https://mdeperas.github.io/minutnik/`. Workflow `.github/workflows/pages.yml`
  (push na master publicznego repo): `npm ci` → `npm test` → `npm run e2e` (WebKit) → build → deploy Pages; czerwony test = brak deployu.
  Aktualizacja: commit tutaj, potem `bin/publikuj` (bramki web lokalnie, świeża kopia z `bin/przygotuj-publiczne`, jej drzewo jako nowy commit
  na klonie publicznego repo, ponowne `sprawdz-publiczne.ts`, zwykły push bez force; historia prywatna nie wychodzi). Autor commitów publicznych:
  `PUBLICZNY_AUTOR` w `lokalne/srodowisko.sh` (adres noreply GitHuba). Przebieg: `gh run watch -R mdeperas/minutnik`.
- Testy: `xcodegen generate -q && xcodebuild test -project Minutnik.xcodeproj -scheme Minutnik -destination 'platform=iOS Simulator,name=Minutnik iPhone 18 Pro' -derivedDataPath build`
- Własny symulator „Minutnik iPhone 18 Pro” (iPhone 18 Pro, iOS 27.2; brak → `xcrun simctl create 'Minutnik iPhone 18 Pro' com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro com.apple.CoreSimulator.SimRuntime.iOS-27-2`).
  Nie używaj wspólnego „iPhone 18 Pro” ani „ThreadCam iPhone 18 Pro”: równoległe E2E na jednym symulatorze przejmują sobie ekran.
- Przed serią przebiegów `xcrun simctl boot 'Minutnik iPhone 18 Pro'`; na koniec `xcrun simctl shutdown 'Minutnik iPhone 18 Pro'`, jeśli był wyłączony.
- Dwa schematy: `Minutnik` = bramka commitu (unit + integracja, limit 30 s); `MinutnikE2E` = UI-testy na symulatorze
  (`MinutnikUITests`), bramka merge'a razem z commitu (limit 5 min). E2E nie trafia do schematu `Minutnik`.
- E2E: `xcodegen generate -q && xcodebuild test -project Minutnik.xcodeproj -scheme MinutnikE2E -destination 'platform=iOS Simulator,name=Minutnik iPhone 18 Pro' -derivedDataPath build`
- Tryb e2e: argument `-e2e` (`-e2e-off` wyłącza), zapamiętany w defaults `e2e` także na start z ikony.
  Podróbki granic w `SimulatedEnvironment`: zegar przyspieszony (`MINUTNIK_E2E_TIME_SCALE` w `launchEnvironment`, zapamiętany w defaults `e2e`), dźwięk i powiadomienia nagrywające wywołania.
- Ryciny: źródło prawdy `grafika/ryciny/` (`mapa.json` grupa → stan). Generator rysunków `grafika/generator/gen.py` (bazy w `zrodla/`, nadpisuje `grafika/ryciny/`).
  Apka: `xcodegen` (`preGenCommand`) odpala `bin/ryciny-do-apki` → `Minutnik/Ryciny.xcassets` (w `.gitignore`, wektory, kolor fazy wpieczony: napięcie = obwód napinania, rozluźnienie = szałwia z `web/src/wyglad.ts`; łuki o zerowym promieniu zamienione na linie, bo CoreSVG ich nie czyta).
  Wybór: `FigureCatalog`. PWA: `web/src/ryciny.ts` (`?raw` w buildzie, wyróżnienie przez `color`).
- Mapa ścieżek i testów: `docs/COVERAGE.md`.
- Muzyka w tle: pliki `web/public/muzyka/*.m4a` (apka bierze je jako zasoby przez `project.yml`), generator `muzyka/generuj.py`, licencje `muzyka/ŹRÓDŁA.md`. PWA nie wkłada ich do precache (cache `minutnik-muzyka` na żądanie).

## PWA (`web/`)

- Vite + czysty TypeScript, bez frameworka i bez zależności w runtime; dev: `vite`, `typescript`, `vitest`, `@playwright/test`.
  `node_modules/`, `dist/` i wyniki Playwrighta są w `web/.gitignore`. Raz po klonie: `cd web && npm ci && npx playwright install webkit`.
- Bramka commitu (Vitest, limit 30 s): `cd web && npm test`. Bramka merge'a, razem z commitu (Playwright, WebKit + profil iPhone 15,
  limit 5 min, sam buduje i stawia `vite preview` na porcie 4173): `cd web && npm run e2e`. Build: `npm run build` → `web/dist/` (`base` `/minutnik/` pod Pages).
- „O ćwiczeniu”: PWA czyta `web/o-cwiczeniu-publiczne.json` (streszczenie własnymi słowami, `dekodujTekst` w `src/oCwiczeniu.ts`); apka dostaje przy buildzie `lokalne/o-cwiczeniu.json`, bez niego wariant publiczny (`bin/zestawy-do-apki`). Przewija się tylko ten ekran. `sprawdz-publiczne.ts` szuka fraz z `lokalne/o-cwiczeniu.json`.
- Zestawy: PWA importuje w buildzie `web/zestawy-publiczne.json` (kopia 1:1 `lokalne/zestawy.json`) przez alias `virtual:zestawy` (`vite.config.ts`);
  tak idzie też do deployu. Inny plik tylko do lokalnej próby: `MINUTNIK_ZESTAWY=<ścieżka> npm run build`.
  Polecenia ćwiczeń w PWA = teksty z apki iOS (user ma zgodę na użycie, 19.11.2026).
  Zgodność struktury z oryginałem: `bin/sprawdz-wariant-zestawow` (po każdym `bin/generuj-zestawy`).
  Format sprawdza `dekodujKatalog` (`web/src/katalog.ts`) według `docs/format-zestawu.md`.
- Standardy jak w apce: bez komentarzy, logika bez DOM w czystych modułach z testem Vitest (`src/*.test.ts`), widok cienki;
  granice (zegar, dźwięk, wake lock, storage) wchodzą jednym punktem, podróbki e2e przez ten punkt, w widoku bez `if e2e`.
  Każdy nowy test raz celowo psujemy.
- Historia: `web/src/historia.ts` (format zgodny z `historia.json` apki, eksport `minutnik-historia.json`; nieczytelny zapis zostaje nietknięty).
- Sesja: `Odtwarzacz` (`web/src/odtwarzacz.ts`, port `SessionPlayer`, reguły w `docs/odtwarzacz.md`, czas w ms z zewnątrz) i `wygladFazy` (`web/src/wyglad.ts`, port `PhaseLook`).
  Testy logiki na własnych małych zestawach, nie na treści PRM (PWA dostanie inny wariant tekstów).
- PWA offline: `vite.config.ts` po buildzie dopisuje `dist/sw.js` (`src/precache.ts`: lista plików builda, cache `minutnik-<wersja>-<skrót listy plików>`, wersja = `git rev-parse --short HEAD` albo `MINUTNIK_WERSJA`).
  Nowy SW przejmuje stronę od razu (`skipWaiting` + `clients.claim`), a `Aktualizacja` (`src/aktualizacja.ts`) przeładowuje ją tylko poza sesją. Stary cache znika od razu, więc bundle zostaje jednym plikiem JS/CSS bez leniwych chunków.
  Ikony: źródło `web/ikona.svg`, PNG w `web/public/` z `bin/generuj-ikony` (render WebKitem Playwrighta). Klucz `minutnik.historia` i ścieżka `/minutnik/` bez zmian, bo inaczej iPhone zgubi historię.
- Granice PWA: `srodowisko.ts` (zegar, data, klatka, reduced-motion, widoczność, tryb standalone, rejestracja service workera, Web Audio, Wake Lock, historia w `localStorage` pod `minutnik.historia`, udostępnianie pliku). Podróbki e2e: `window.__minutnikPodrobki` ustawiane tylko przez `page.addInitScript` (`web/e2e/podrobki.ts`: tempo zegara, nagrywanie sygnałów i Wake Lock; `podrobUdostepnianie` podmienia `navigator.share`); adres strony niczego nie przełącza.

## Odnowienie podpisu co 7 dni

- Wszystkie nazwy i ścieżki skryptów (bundle, schemat, expiry, logi): `bin/lib.sh`, i tylko tam; ID iPhone'a czyta z `lokalne/srodowisko.sh`.
  Wyjątek: plist LaunchAgenta to szablon z `__REPO__`/`__HOME__` (launchd nie czyta `lib.sh`).
- `bin/install.sh` instaluje z profilem, który już leży na Macu — **nie przedłuża** 7 dni.
- `bin/renew.sh` przedłuża: odkłada profil `com.md4ps.minutnik`, czeka aż Xcode (GUI) pobierze nowy,
  instaluje i wypisuje nową datę. Wymaga iPhone'a na kablu i Xcode z zalogowanym kontem (Xcode 27 gubi konto:
  po 60 s bez profilu zaloguj Apple ID w Settings → Accounts i uruchom ponownie). Renew Thread Cam w tej samej sesji Xcode.
- `bin/remind.sh` + `bin/com.md4ps.minutnik.remind.plist` (LaunchAgent, 9:00 i 14:00): powiadomienie, gdy do wygaśnięcia
  zostało ≤ 36 h (próba: `REMIND_HOURS=100000 bin/remind.sh`; log w `~/Library/Logs/Minutnik/remind.log`).
  Instalacja/po zmianie plista: `bin/zainstaluj-przypomnienie` (wstawia ścieżki repo i `$HOME` w szablon, zakłada katalog logów, `launchctl bootstrap`). Datę zapisuje `install.sh` do
  `~/Library/Application Support/Minutnik/expiry` (osobno od Thread Cam); brak pliku → powiadomienie.

## Logi z telefonu

- Apka loguje przez `Log` (`os.Logger`, subsystem `com.md4ps.minutnik`, kategorie `navigation`, `session`, `sound`), poziom `.notice`/`.error`
  (`.info` na iOS nie trafia do `log collect`).
- `bin/logs.sh [minuty]` (domyślnie 30): iPhone na kablu, **wymaga `sudo`**; bez terminala hasło w okienku macOS
  (`bin/askpass.sh`, `sudo -A`); wynik w `~/Library/Logs/Minutnik/phone-<data>.log`.

## Standardy

- Bez komentarzy w kodzie; nazwy mają mówić same.
- Logika bez UIKit/AVFoundation żyje w czystych typach i ma test jednostkowy. Widoki są cienkie.
- Zachowanie modelu testujemy integracyjnie (`*IntegrationTests`): prawdziwy model, podrobione tylko granice
  (zegar, dźwięk, zdarzenia sesji audio, powiadomienia, defaults). Każdy nowy test raz celowo psujemy (`strategia-testow`).
- Dźwięk: `AVAudioSession` `.playback` + `.mixWithOthers`, tryb tła `audio`; sygnały całej sesji planowane z góry na osi
  czasu audio (`ToneSignalPlayer.plan`), Timer tylko odświeża ekran. Szczegóły i uzasadnienie: `docs/odtwarzacz.md`.
- Granice (zegar, dźwięk, defaults, pliki) wchodzą jednym punktem: `AppEnvironment` w `MinutnikApp`. Podróbki e2e
  (`SimulatedEnvironment`) tylko pod `#if targetEnvironment(simulator)`: `install.sh` buduje Debug na telefon,
  więc `#if DEBUG` ich nie odcina. W widokach i modelu bez `if e2e`.
- Teksty UI po polsku, krótkie.
- Commit po polsku, tytuł ≤ 72 znaki, w treści „dlaczego”.

## Przed code review

1. Testy na symulatorze zielone (komenda wyżej).
2. Zmiana dotyka UI, dźwięku albo zegara → także schemat `MinutnikE2E` zielony na symulatorze.
3. `mattpocock-skills:code-review` od `origin/master` (Standards = ta sekcja, Spec = cel zmiany z czatu).

## Przed pushem

1. Uwagi z code review poprawione albo świadomie odłożone (zapisane w commicie lub w czacie).
2. Testy zielone po poprawkach.
3. Zmiana dotyka dźwięku, tła albo zegara → `bin/install.sh` i lista ręczna niżej na telefonie,
   raz na końcu (kroki z oczekiwanym wynikiem, user odpisuje ✅/❌).
4. `git push`.

## Ręcznie na telefonie (czego symulator nie sprawdzi)

Jedna lista do zbiorczej próby, po kolei; przy każdym punkcie odpisz ✅/❌. Live Activity nie ma w MVP
(rozszerzenie zajęłoby ostatni slot apki na darmowym koncie), więc nie jest sprawdzana.

- M1 Start: `bin/install.sh` → ikona „Minutnik” na telefonie → apka startuje, widać „Minutnik” i wersję z commitem.
  Oczekiwane: przy pierwszym starcie pytanie o powiadomienia → „Pozwól”; Thread Cam dalej startuje z ikony.
- M2 Tło (na liście dotknij „PRM” → „Start”):
  - a) zablokuj ekran zaraz po „Start” → sygnał każdej fazy słychać na zablokowanym telefonie, na końcu trzy tony;
    przy końcu każdej fazy cichy baner z nazwą następnej fazy, na końcu „Koniec sesji” (dźwięk daje tylko apka);
  - b) przełącznik wyciszenia włączony → sygnały dalej słychać;
  - c) muzyka w Spotify/Muzyce, potem „Start” → muzyka gra dalej w tej samej głośności, sygnały na jej tle;
    po końcu albo „Przerwij” muzyka gra bez zmian;
  - d) połączenie telefoniczne (albo Siri) w trakcie fazy → sesja w pauzie („Wznów”); po rozłączeniu sama rusza,
    „Zostało” liczy od miejsca przerwania, sygnały wracają w rytmie;
  - e) słuchawki w trakcie sesji, potem wyjęcie → pauza bez samoczynnego wznowienia; „Wznów” → sygnały wracają;
  - f) „Pauza”, potem blokada ekranu na dłużej niż faza → cisza, żadnego sygnału ani banera; „Wznów” → sygnały
    i banery wracają od bieżącej fazy; „Przerwij” → żadnych kolejnych banerów.
- M3 Odtwarzacz: przy każdej nowej fazie (też po „Pomiń”) podwójne stuknięcie wibracji, w rozluźnieniu stuknięcie co 4 s,
  przy 3-2-1 mocne stuknięcia, na końcu sesji trzy; wszystko przy grających sygnałach (Core Haptics `playsHapticsOnly`);
  w sesji nie ma „Wróć”, gest od lewej krawędzi nic nie robi; „Pauza” → „Przerwij” → „Wróć do listy” wraca do listy;
  w rozluźnieniu duży pierścień oddechu (Wdech/Trzymaj/Wydech/Trzymaj, 4-3-2-1), pod nim mały licznik fazy;
  instrukcje fazy czytelne bez przewijania przy domyślnej czcionce.
- M4 Historia: po sesji do końca i drugiej przerwanej na liście sekcja „Historia”: najnowsza na górze,
  „Ukończona · N min” i „Przerwana po K z N faz”; po zabiciu apki i ponownym starcie wpisy są dalej;
  „Eksportuj” → arkusz udostępniania z `minutnik-historia.json` → zapis w Plikach, plik ma oba wpisy.
- M5 Wygląd: lista i sesja na ciemnym tle; w sesji pierścień od góry ubywa zgodnie z zegarem, przy napinaniu morski
  (cyfry i „NAPINANIE”), przy rozluźnieniu szałwiowa zieleń; pierścień płynnie się kurczy przy napinaniu i rośnie przy
  rozluźnieniu, a z Reduce Motion stoi (ubywa tylko obwód); jak minutnik PRM na stronie kursu.

- M6 Muzyka: na starcie „Muzyka: Kosmos” → „Start” → muzyka gra ciszej niż sygnały, tiki 3-2-1 słychać; zablokuj ekran → muzyka i sygnały grają dalej;
  „Pauza” → muzyka płynnie cichnie, „Wznów” → wraca; ikona nuty u góry → wycisza; na końcu muzyka wygasa; pętla po 2,5 min bez kliku;
  po zabiciu apki wybór „Kosmos” zostaje. To samo raz z „Synthwave” i z „Las” (ptaki i strumień). Ikona nuty: wyciszona = szara nuta przekreślona, jak w PWA.

## Ręcznie na iPhonie: PWA (czego Playwright nie sprawdzi)

Po `bin/publikuj` i zielonym przebiegu, Safari na iPhonie; przy każdym punkcie ✅/❌.

- W1 Instalacja: Safari → `https://mdeperas.github.io/minutnik/` → Udostępnij → „Dodaj do ekranu początkowego” → ikona „Minutnik” z rysunkiem, nie zrzut strony.
- W2 Pełny ekran: start z ikony → bez paska Safari, ciemne tło pod paskiem stanu i przy dolnej krawędzi; na liście wersja z commitem.
- W3 Ekran nie gaśnie: PRM → „Start”, telefon odłożony na 2 min → ekran świeci, sesja idzie (auto-blokada np. 30 s).
- W4 Sygnały: ton przy każdej nowej fazie, na końcu sesji sygnał końca; przełącznik wyciszenia włączony → zapisz, czy słychać (Web Audio może milknąć).
- W5 Nadrabianie: w sesji wyjście do innej apki na ~3 fazy i powrót → licznik we właściwej fazie, **jeden** sygnał; w tle cisza, bez powiadomień.
- W6 Historia/eksport: sesja do końca i druga przerwana → „Ukończona · N min” i „Przerwana po K z N faz”, najnowsza na górze;
  po zamknięciu apki z przełącznika wpisy są dalej; „Eksportuj” → arkusz z `minutnik-historia.json` → zapis w Plikach, oba wpisy.
- W7 Offline: tryb samolotowy, zamknięcie i start z ikony → lista i sesja działają.
- W9 Muzyka: „Muzyka: Synthwave” → „Start” → muzyka gra (ekran włączony) pod sygnałami; „Pauza” wycisza płynnie; przycisk z nutą wycisza (nuta przekreślona);
  po pierwszym odtworzeniu tryb samolotowy → ta sama ścieżka dalej gra.
- W8 Aktualizacja: po nowym `bin/publikuj` start z ikony → po chwili nowa wersja na liście bez ręcznego odświeżania;
  publikacja w trakcie sesji → sesja nie przeładowuje się, nowa wersja dopiero po jej końcu; historia zostaje.
