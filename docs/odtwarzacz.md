# Odtwarzacz sesji (`SessionPlayer`)

Czysty typ (`Minutnik/Player/SessionPlayer.swift`), bez zegara, dźwięku i timerów. Każda akcja dostaje `now: Date`
i zwraca listę zdarzeń; granice (chapter 4+) tylko wołają `tick(now:)` i reagują na zdarzenia.

Kroki = fazy zestawu spłaszczone po kolei (grupa × faza, czas z `czasS`). Zegar: początek fazy (`startedAt`),
nie sumowanie ticków — koniec fazy = `startedAt + czas`, następna startuje dokładnie tam (bez dryfu).

## Stany

| Stan | Dane |
|---|---|
| gotowy (`ready`) | — |
| trwa (`running`) | krok, początek fazy |
| pauza (`paused`) | krok, ile fazy już minęło |
| zakończony (`finished`) | — |
| przerwany (`stopped`) | — |

## Przejścia

| Z | Akcja | Do | Zdarzenia |
|---|---|---|---|
| gotowy | `start` | trwa, krok 0 od `now` | `phaseStarted(0, now)` (pusty zestaw → zakończony, `sessionFinished`) |
| trwa | `tick`, przed końcem fazy | bez zmian | — |
| trwa | `tick`, po końcu fazy | trwa, następny krok od **końca** poprzedniego | `phaseStarted(k+1, koniec)` |
| trwa | `tick`, po końcu ostatniej | zakończony | `phaseStarted…`, `sessionFinished(koniec)` |
| trwa | `tick` po długim tle (np. 3 min) | trwa w fazie, w której wypada `now` | `phaseStarted` za każdą przeskoczoną fazę z jej planowym czasem; ewentualnie `sessionFinished` |
| trwa | `pause` | pauza (`pause`, `skip`, `stop` najpierw nadrabiają jak `tick`) | zdarzenia nadrabiania |
| pauza | `resume` | trwa, początek = `now − minęło` | — |
| trwa / pauza | `skip` | trwa, następny krok od `now` (pauza zdjęta) | `phaseStarted(k+1, now)` |
| trwa / pauza | `skip` ostatniej fazy | zakończony | `sessionFinished(now)` |
| trwa / pauza | `stop` | przerwany | `sessionStopped(now)` |
| inne pary | dowolna | bez zmian | — |

`start` tylko z gotowego; nowa sesja = nowy `SessionPlayer`.

## Wyjścia dla granic

- Zdarzenia niosą planowy czas (`at`). Nadrabianie oddaje wszystkie przeskoczone fazy — granica decyduje, czy grać
  dźwięk (np. tylko gdy `at` jest blisko `now`, jak „cicho” w pierwowzorze).
- `upcomingPhaseEnds()` — końce wszystkich pozostałych faz (oś czasu) do zaplanowania sygnałów/powiadomień z góry;
  w pauzie puste (po `resume` plan liczy się od nowa).
- `remainingInPhase(now:)`, `remainingInSession(now:)` — w pauzie zamrożone.

## Dźwięk w tle (chapter 5)

- `SessionModel` przy start/wznów/pomiń oddaje `ToneSignalPlayer.plan` całą oś: sygnał bieżącej fazy „teraz” (tylko start/pomiń)
  i sygnał na każdy koniec fazy z `upcomingPhaseEnds()`. Gracz zamienia daty na `AVAudioTime(hostTime:)` i robi
  `AVAudioPlayerNode.scheduleBuffer(_:at:)` — sygnały grają z osi audio, nie z tyknięć Timera. Tyknięcia tylko odświeżają ekran
  i wykrywają koniec sesji. Pauza/przerwij → `cancelPlan`; koniec/przerwij → `endSession` (silnik i sesja audio gasną
  3 s po ostatnim sygnale, `notifyOthersOnDeactivation`).
- Sesja audio: `.playback` (gra mimo przełącznika wyciszenia i w tle z `UIBackgroundModes: audio`) + `.mixWithOthers`.
  Nie `.duckOthers`: ściszenie trwa, dopóki sesja jest aktywna, czyli całe ~26 min; włączanie sesji tylko na czas sygnału
  wymagałoby aktywacji w tle przed każdym sygnałem (z tyknięcia Timera), a cel to jedna aktywacja na sesję.
  Źródło: https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions-swift.struct/duckothers
- Podtrzymanie w tle: osobnej ciszy nie dokładamy. Silnik `AVAudioEngine` działa przez całą sesję, a węzeł gracza
  między zaplanowanymi buforami renderuje ciszę na wyjście — z punktu widzenia systemu apka cały czas gra. Źródło:
  https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback (tryb `audio` + aktywna
  sesja `.playback` = granie w tle) *(wniosek: render ciszy przez działający silnik liczy się jako granie; sprawdza M2)*.
- Zmiana konfiguracji silnika (np. podłączenie słuchawek) zatrzymuje silnik → `ToneSignalPlayer` startuje go i planuje
  pozostałe sygnały od nowa.
- Przerwania i trasa (`SystemAudioSessionEvents`): przerwanie → `pause`; koniec przerwania z `shouldResume` → `resume`
  (tylko jeśli pauzę zrobiło przerwanie); `oldDeviceUnavailable` (wyjęte słuchawki) → `pause` bez wznawiania.
  https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions ;
  https://developer.apple.com/documentation/avfaudio/responding-to-audio-route-changes
- Powiadomienia: zgoda pytana przy starcie apki (ekran zestawów), banery bez dźwięku — dźwięk daje tylko apka, bez dublowania.
  Planowane z osi końców faz przy start/wznów/pomiń (tytuł = następna faza, na końcu „Koniec sesji”), kasowane przy pauzie,
  przerwaniu i końcu sesji; PRM ma 24 fazy, poniżej limitu 64.
- Live Activity: odłożona. Wymaga rozszerzenia widgetu (osobne App ID `com.md4ps.minutnik.widget`); na darmowym koncie
  rozszerzenia liczą się do limitu 3 apek (wg AltStore, niepotwierdzone przez Apple), więc zajęłoby ostatni wolny slot.
  Decyzja 2026-11-19: pominięta w MVP.
