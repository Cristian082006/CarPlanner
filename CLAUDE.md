# CarPlanner

Aplicație Flutter (Android/iOS) pentru gestionarea mașinilor: detalii vehicul, istoric revizii/carte
service, documente (RCA/CASCO/Rovinietă/ITP, asigurare locuință), remindere și notificări locale.
Stocare **exclusiv locală** pe dispozitiv (SQLite), fără backend/cloud.

## Stack tehnic

- Flutter SDK instalat la `C:\flutter` (mutat de pe D: din cauza unui bug de compilare Kotlin
  incrementală cross-drive — `kotlin.incremental=false` e setat în `android/gradle.properties`
  ca fix suplimentar).
- SQLite via `sqflite`, singleton în `lib/db/database_helper.dart`, cu migrații `onUpgrade`
  (versiune curentă: 15 — v2 a adăugat tabela `component_records`, v3 a adăugat coloana
  `changedComponentIds` pe `service_records`, v4 a adăugat `customIntervalKm/Months/Source` pe
  `component_records` + tabela `vehicle_extra_components`, v5 a adăugat coloana `engineCode` pe
  `vehicles`, v6 a adăugat un prim set de tabele de catalog `vehicle_models`/`maintenance_intervals`
  — **înlocuite complet la v7**, dropuite necondiționat la orice upgrade `oldVersion<7`, nu mai
  există în cod; v8/v9/v10/v11 au înlocuit succesiv *datele* din catalog cu exporturi tot mai mari,
  v12/v13 au fost completări punctuale pentru un singur motor (Ford Fiesta 1.6 TDCi, cerut de un
  utilizator), v14 a **eliminat** 882 de motorizări generate mecanic (vezi mai jos), iar v15 a
  înlocuit catalogul cu structura **consolidată** din `auto_mentenanta_5.sql` (un singur rând per
  nameplate, fără generații — vezi mai jos) — schema tabelelor rămânând neschimbată pe tot
  parcursul, mai puțin faptul că `modele.generatie` e NULL peste tot din v15).
  **Atenție la migrații reutilizate:**
  `_createComponentRecordsTable` construiește schema originală v2 (fără coloanele custom*) fiindcă
  e refolosită de calea de upgrade `oldVersion<2` — `_onCreate` aplică deltele ulterioare (ALTER)
  separat, la fel ca un upgrade real, ca să nu existe două căi de cod cu scheme diferite pentru
  instalare nouă vs. upgrade. Tabela `vehicles` NU are problema asta (construită inline, nu prin
  funcție reutilizată), deci coloana `engineCode` a putut fi adăugată direct în `CREATE TABLE` +
  un singur `ALTER` la upgrade.
- **Tabele de catalog** (schemă din v7, date din v15): schemă relațională `marci`→`modele`→`motoare`,
  din v15 cu structură **consolidată** din `auto_mentenanta_5.sql` — un singur rând în `modele` per
  nameplate (un singur „Fiesta”, un singur „Golf”...), fără distincție de generație (cerut explicit
  de utilizator: căutarea pe marcă+model+an să întoarcă TOATE motorizările modelului, nu doar pe
  cele ale unei generații). 26 mărci / 235 modele / **763 motorizări** (756 din export + cele 7
  coduri reale Fiesta VI 1.6 TDCi de la v13 — HHJC/HHJD/HHJE/TZJA/TZJB/T1JA/UBJA — re-adăugate
  manual la finalul secțiunilor `motoare`/`intervale_mentenanta` fiindcă **lipsesc din exportul
  consolidat**; nu le șterge la o portare viitoare fără să verifici că noul export le conține) /
  1075+14 reguli specifice (doar distribuție, componentele 5/6 — restul componentelor vin din
  regulile generice per combustibil, prin view). Coloana `modele.generatie` rămâne în schemă
  (query-urile o referă) dar e NULL peste tot. Exportul v15 a fost verificat la portare pentru
  bug-ul H/L de mai jos — zero perechi formulaice. `componente`/`intervale_generice`/`marci` sunt
  identice byte-cu-byte cu v7–v14, deci `componenta_id`-urile și `marca_id`-urile rămân valide.
  Test de regresie: `test/ford_fiesta_test.dart` (rulează pe macOS cu sqflite FFI; limitarea FFI
  din nota de mai jos era specifică mediului Windows vechi — `widget_test.dart` însă tot pică,
  fiindcă nu-și inițializează singur factory-ul FFI).
  Istoric pre-v15 (structură pe generații, 448 modele): datele v11–v14 veneau din
  `auto_mentenanta_3.sql` — **atenție,
  numele de fișier e reciclat**: v8 folosea tot `auto_mentenanta_3.sql` dar cu conținut complet diferit și
  mult mai mic (18/153/256); versiunea folosită la v11 e un export nou, primit separat, care
  întâmplător are același nume — nu presupune că fișierul cu acest nume e mereu identic, verifică
  mereu numărul de rânduri la o viitoare actualizare. v10 avea 26/448/778 din `auto_mentenanta_8.sql`,
  v9 avea 26/264/449 din `auto_mentenanta_7.sql`, v8 avea 18/153/256 din `auto_mentenanta_3.sql`
  (versiunea veche), v7 avea 18/60/91 din `auto_mentenanta_2.sql`).
  **Bug important găsit la v14, citește înainte de o viitoare actualizare:** exportul `auto_mentenanta_3.sql`
  (v11) genera fiecare motorizare "H" (variantă putere mare) și "L" (variantă putere mică) printr-o
  formulă mecanică fixă — `putere_cp(H) = bază*1,25`, `capacitate_cm3(H) = bază*1,12`,
  `putere_cp(L) = bază*0,82`, `capacitate_cm3(L) = bază*0,88` — verificat pe 800+ perechi, deviație
  sub 1%, deci umplutură formulaică, NU motoare reale cercetate individual (de-aici denumiri corupte
  gen „1.150 MultiJet"/„2.231 CRDi" — concatenare capacitate+putere greșită în scriptul generator, și
  coliziuni de coduri cu specificații contradictorii pe modele diferite). v14 a șters cele 882 de
  rânduri confirmate (au un motor "de bază" corespunzător pe același model, cu raportul exact) printr-un
  `DELETE FROM motoare WHERE id IN (...)` la finalul `referenceDataStatements` (statement dispărut
  odată cu înlocuirea integrală a datelor la v15). Morala rămâne valabilă: dacă un viitor export
  vine de la același tip de script generator, verifică din start dacă are aceeași problemă înainte
  de portare, nu doar la reclamații ulterioare (la v15 verificarea a fost făcută: zero perechi
  formulaice). Are intervale specifice per motor în `intervale_mentenanta` (doar
  distribuție — singurul lucru care chiar diferă per motor) și fallback pe intervale generice
  per combustibil în `intervale_generice` pentru restul componentelor; view-ul SQL
  `mentenanta_completa` combină automat cele două (`COALESCE` pe regula specifică, altfel cea
  generică). NU sunt date de utilizator — sunt recreate integral (DROP + CREATE + INSERT) la
  fiecare bump de versiune DB, direct din instrucțiunile SQL brute din
  `lib/utils/vehicle_reference_data.dart` (portate MySQL→SQLite dintr-un fișier furnizat de
  utilizator — nu cercetate/verificate de mine, sursă declarată de el; fișierul sursă însuși
  spune explicit că intervalele sunt orientative, nu preluate 1:1 din manualele fiecărui
  producător — verifică mereu cartea tehnică pentru o mașină reală). Pentru actualizări
  viitoare: cere un export SQL nou, adaptează doar sintaxa (fără `ENGINE=InnoDB`, `AUTO_INCREMENT`
  → `INTEGER PRIMARY KEY AUTOINCREMENT`, `ENUM` → `TEXT`, `UNIQUE KEY nume (...)` → `UNIQUE (...)`),
  înlocuiește `referenceDataStatements`, crește versiunea DB — **nu reordona/nu sări rânduri**:
  `motoare`/`intervale_mentenanta` referă `model_id`/`motor_id` prin numere hardcodate care
  presupun ordinea exactă de inserare (SQLite alocă id-uri auto-increment 1,2,3... în ordinea
  inserării, la fel ca AUTO_INCREMENT în fișierul original). Secțiunile `componente`/
  `intervale_generice`/`marci` au rămas identice între v7-v15 (nu au fost regenerate în fișierul
  sursă, verificat byte-cu-byte la fiecare actualizare), deci `componenta_id`-urile din
  `intervale_generice` și `marca_id`-urile din `modele` rămân valide neschimbate (`modele` însuși
  s-a schimbat integral la v15 — consolidare pe nameplate). Portarea v15 a fost făcută cu un
  script (parsare INSERT-uri din fișierul SQL + re-emitere în Dart + validare pe un SQLite
  in-memory: numărare rânduri, verificare perechi H/L, query-uri Fiesta/Golf/Polo) — preferă
  aceeași abordare la o viitoare actualizare, în locul copierii manuale.
- Notificări locale: `flutter_local_notifications` + `timezone`.
- OCR pe device (gratuit): `google_mlkit_text_recognition`, folosit pentru scanarea talonului auto
  și, pe lângă asta, pentru extragerea best-effort a datelor dintr-o poliță RCA/CASCO atașată ca PDF.
- Calendar: `add_2_calendar` (necesită permisiuni `READ_CALENDAR`/`WRITE_CALENDAR` +
  `<queries>` pentru `ACTION_INSERT` în AndroidManifest).
- Poze: `image_picker` (cameră + galerie).
- Atașament PDF documente (RCA/CASCO): `file_picker` (selectare fișier), `printing`
  (`Printing.raster` — randează prima pagină a PDF-ului ca imagine pentru OCR, fără viewer
  nativ), `open_filex` (deschide PDF-ul cu viewer-ul implicit al telefonului). PDF-ul e stocat
  în aceeași coloană `photoPath` folosită și pentru poze (fără migrație DB) — UI-ul distinge
  poză vs. PDF după extensia fișierului (`.pdf`).
- i18n: sistem propriu, lightweight (NU `flutter_localizations`/ARB) — clasa statică `S` din
  `lib/l10n/strings.dart`.
- Iconița aplicației (design "Auto Calendar" — calendar cu header roșu "AUTO", cifra "24" și o
  mașină stilizată): generată cu `flutter_launcher_icons` (dev dependency) din 3 surse în
  `assets/icon/`: `icon.png` (1024×1024, fundal plin — degrade albastru→violet, folosit ca iconiță
  iOS și ca fallback Android), `icon_foreground.png` (aceeași compoziție, fundal transparent,
  scalată la 66% + offset 17% pentru zona sigură a iconițelor adaptive Android) și
  `icon_background.png` (doar degradeul, fără compoziție — layer-ul de fundal al iconiței adaptive
  Android, referit din `pubspec.yaml` la cheia `adaptive_icon_background:` ca path către imagine,
  NU cod de culoare hex, ca să păstreze exact degradeul din `icon.png`). Config complet în
  `pubspec.yaml` (cheia `flutter_launcher_icons:`).
  **Generare (v2, Chrome headless, NU `tool/generate_icon.dart`):** cele 3 PNG-uri de mai sus au
  fost randate dintr-un fișier HTML/CSS (gradient, SVG pentru mașină, text real) cu Chrome
  headless (`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome --headless
  --disable-gpu --hide-scrollbars --window-size=1024,1024 --screenshot=ieșire.png
  file:///cale/icon.html`; pentru fundal transparent adaugă `--default-background-color=00000000`
  și setează `background: transparent` în CSS) — NU cu `tool/generate_icon.dart` (Skia
  `CustomPainter` + `flutter test`), fiindcă acel pipeline **nu randează text deloc** în mediul de
  test (`TextPainter` produce cutii goale/tofu, fără glife reale — verificat, nu e o problemă de
  cod ci o limitare a fontului de test din `flutter_test`). `tool/generate_icon.dart` a rămas în
  cod dar e ACUM ÎNVECHIT/nefolosit pentru designul curent (mai desenează doar formele calendar+
  mașină vechi, fără header/text/degrade) — nu presupune că rulându-l obții iconița curentă; pentru
  orice modificare viitoare a designului, editează fișierele HTML (recreează-le după modelul de mai
  sus, nu mai există păstrate pe disc — au fost scrise în scratchpad-ul sesiunii) și re-randează cu
  Chrome headless, apoi `dart run flutter_launcher_icons`.

## Arhitectură — fișiere cheie

- `lib/main.dart` — entry point; apelează `RegionService.instance.load()` apoi
  `NotificationService.instance.init()` înainte de `runApp()`. `MaterialApp` e înfășurat într-un
  `ValueListenableBuilder<String>` pe `RegionService.instance.countryCode` (cu `key: ValueKey(...)`)
  pentru rebuild reactiv la schimbarea țării.
- `lib/db/database_helper.dart` — CRUD pentru vehicles, service_records, car_documents,
  reminders, component_records (FK `ON DELETE CASCADE` spre vehicle unde e cazul).
- `lib/services/notification_service.dart` — programează/anulează notificări. **Important:**
  toate apelurile către plugin (`_plugin.cancel`, `_plugin.zonedSchedule`) sunt învelite în
  try/catch — plugin-ul `flutter_local_notifications` poate arunca excepții netratate (ex.
  `PlatformException: Missing type parameter`, cauzat de cache corupt de notificări programate
  pe device) care altfel blochează la infinit ecranele de salvare (butonul rămâne pe
  "Se salvează..." fără să revină, deși datele chiar se salvează în DB). Nu elimina aceste
  try/catch-uri — sunt un fix pentru un bug real, reprodus și confirmat live pe device.
- `lib/services/region_service.dart` — `RegionService` (singleton, `ValueNotifier<String>
  countryCode`, persistat via `shared_preferences`, cheie `'RO'` = România, orice altă valoare
  (ex. `'INTL'`) = profil internațional generic).
- `lib/services/document_scanner_service.dart` — OCR talon. Extrage marca/modelul căutând
  explicit codul de câmp EU `D.3` (regex cu gardă anti-etichetă), NU prin heuristica "linia de
  după marcă" (asta a fost un bug real, fixat — vezi test de regresie în
  `test/document_scanner_service_test.dart`). Extrage și `engineCode` căutând eticheta "motor"/
  "cod motor" — **spre deosebire de D.3, talonul românesc NU are un câmp standardizat UE dedicat
  codului de motor**, deci extracția e best-effort (rată de succes probabil scăzută/inconsistentă
  în funcție de formatul talonului fotografiat); utilizatorul completează manual când OCR-ul nu
  găsește nimic, la fel ca la orice alt câmp.
- `lib/l10n/strings.dart` — clasa `S`, ~90+ getteri/metode de string, fiecare cu ramură RO/EN
  bazată pe `RegionService.instance.language`. Orice text nou afișat în UI trebuie adăugat aici,
  NU hardcodat în ecran.
- `lib/utils/constants.dart` — `DocumentTypeX.label` (RO: RCA/CASCO/Rovinietă/ITP/Asigurare
  locuință/Alt document; INTL: Liability/Comprehensive Insurance, Road Toll, Technical
  Inspection, Home Insurance, Other Document).
- `lib/utils/vehicle_components.dart` — definiții componente esențiale (ulei, filtre, plăcuțe
  etc.) cu interval recomandat (km/luni) și status calculat (OK/Recomandat curând/Depășit).
  `extraComponentCatalog` = componente suplimentare (ulei cutie de viteze, ștergătoare) care NU
  apar implicit pe nicio mașină — doar dacă sunt legate explicit via `vehicle_extra_components`.
  `ComponentDefinition.effectiveIntervalLabel(record)` / `computeComponentStatus` preferă
  `record.customIntervalKm/Months` (setat de un profil de mentenanță) peste valoarea generică.
- `lib/utils/maintenance_profiles.dart` — profiluri de interval ulei motor/filtru **pe model**,
  cu fallback pe marcă (catalog static, scris de mine — NU e AI, NU e query live; userul a ales
  explicit varianta offline în locul unui API AI cu cheie proprie, ca să rămână coerent cu „fără
  backend/cloud”). `resolveMaintenanceProfile(make, model, year)`: mașini de dinainte de 2000 →
  mereu profilul conservator „mașină veche” (8000 km/8 luni), indiferent de marcă/model — pentru
  restul, potrivire pe model (`makeModelProfiles`) → fallback pe marcă (`makeMaintenanceProfiles`)
  → `null` dacă marca nu e recunoscută. **Important, citește înainte să extinzi catalogul:**
  pentru multe modele din aceeași marcă/generație, intervalul *real* oficial e identic (motoarele
  sunt împărțite între modele — verificat cu search pentru Dacia/VW) — valorile per model de aici
  sunt estimate pe segment (oraș vs. compact vs. SUV/premium), NU documentate per nume de model.
  Userul a cerut explicit granularitate pe model știind asta; nu prezenta genul ăsta de date ca
  fiind mai precise decât sunt. Acoperă doar engine_oil/oil_filter (singurul diferențiator
  suficient de sigur de generalizat) — nu extinde la curea de distribuție etc. fără să verifici
  sursele, riscul de a afișa un interval greșit pe o componentă relevantă pentru siguranță e real.
- **Decodare VIN → motor** (`lib/utils/vin_decoder.dart` + `lib/utils/engine_lookup.dart` +
  `lib/widgets/engine_candidates_dialog.dart`): `vin_decoder.dart` decodifică din VIN doar ce e cu
  adevărat standardizat universal prin ISO 3779 — WMI (poziții 1-3 → marcă, tabel `_wmiToMake`
  neexhaustiv, axat pe piața RO/UE) și anul-model (poziția 10, cu dezambiguizarea ciclului de 30
  ani din `_decodeModelYear`); NU încearcă să extragă un cod de motor direct din caractere (asta ar
  necesita tabele proprietare per producător pe care nu le avem). `engine_lookup.dart`
  (`resolveEngineCandidatesFromVin`) combină anul/marca decodate cu catalogul static
  (`getCandidateEnginesForVin` din `database_helper.dart`) printr-o cascadă de restrângere: marcă+
  model+an exact → marcă+model orice an (doar dacă modelul a fost completat — NU lărgim la toată
  marca dacă modelul chiar nu e în catalog, ar arăta motoare de la alt model care par corecte dar nu
  sunt) → doar marcă (ultimă opțiune, doar când modelul lipsește). `engine_candidates_dialog.dart`
  (`showEngineCandidatesDialog`) arată lista candidaților (cu intervalul de ani per motor) și, dacă
  potrivirea nu e exactă, un avertisment vizibil că motoarele arătate pot fi de la altă generație.
  Acest tripleu e folosit din **două locuri**: butonul de lângă câmpul VIN din
  `add_edit_vehicle_screen.dart` (completează `Cod motor`/`Combustibil` în formular) și din
  `_applyMaintenanceProfile` mai jos (completează `engineCode`-ul mașinii dacă lipsește, înainte de
  a căuta intervale) — nu duplica logica de cascadă/dialog dacă mai apare un al treilea loc care
  are nevoie de ea, extinde-le pe astea.
- **Rezolvarea intervalului de mentenanță** (`vehicle_detail_screen.dart` →
  `_applyMaintenanceProfile`): dacă mașina n-are `engineCode` completat dar are un VIN valid,
  încearcă întâi să-l deducă via decodarea VIN de mai sus (utilizatorul alege din dialog sau
  anulează — nu se completează nimic fără interacțiune); rezultatul (dacă există) se salvează pe
  vehicul înainte de a continua. Apoi: cod motor (`getEngineForCode` găsește rândul din `motoare`
  după `cod_motor_key` normalizat → `getMaintenanceIntervalsForMotorId` citește din view-ul
  `mentenanta_completa`, care combină regulile specifice cu cele generice) → dacă nu are rânduri,
  fallback pe model/marcă din `maintenance_profiles.dart` (`resolveMaintenanceProfile(make, model,
  year)`) → mașină veche (an < 2000) → nimic. Un motor poate avea **multe rânduri** (ulei, filtre,
  distribuție, curea accesorii, lichide, plăcuțe/discuri frână, bujii, ulei cutie, baterie...),
  fiecare mapat la componenta din `vehicle_components.dart` prin `_componentIdsForName` (potrivire
  EXACTĂ pe numele `componenta`, nu pe prefix — numele sunt acum fixe, definite în
  `vehicle_reference_data.dart`, nu variază per marcă). Componente găsite în date dar fără id încă
  în tracker (ulei diferențial, DPF, AdBlue) sunt pur și simplu ignorate (`_componentIdsForName`
  întoarce listă goală) — nu extinde `vehicle_components.dart` pentru ele fără cerere explicită.
  Componentele găsite care nu sunt în `essentialComponents` (ex. `glow_plugs` — bujii incandescente,
  doar diesel) se leagă automat de mașină via `addExtraComponent`, la fel ca extra-urile universale.
- `lib/screens/settings_screen.dart` — ecran Setări cu **doar 2 opțiuni** (nu country picker
  complet cu toate țările): România vs. „Alte țări (Internațional)”, plus o notă că denumiri
  per-țară suplimentare vin într-o versiune viitoare. Pachetul `country_picker` a fost eliminat
  din `pubspec.yaml` — nu-l re-adăuga fără cerere explicită.
- `lib/utils/document_verification_utils.dart` — buton „Verifică pe site-ul oficial” pentru
  RCA/ITP/Rovinietă (pe `DocumentTile` și pe `AddEditDocumentScreen`). **Nu** face interogare
  automată reală: RAR (`prog.rarom.ro/rarpol`), AIDA/BAAR (`aida.info.ro/polite-rca`) și CNAIR
  (`cnadnr.ro/ro/verificare-rovinieta`) au toate CAPTCHA/„nu sunt robot” obligatoriu pe formular
  — ocolirea CAPTCHA nu e permisă, indiferent de cerere. Aplicația doar deschide pagina oficială
  corectă (`url_launcher`) și copiază în clipboard identificatorul cerut (nr. înmatriculare
  pentru RCA/Rovinietă, VIN pentru ITP — RAR nu acceptă doar numărul de înmatriculare);
  utilizatorul rezolvă CAPTCHA-ul și introduce manual data găsită înapoi în document. Nu
  transforma asta într-un scraper real fără să confirmi din nou cu utilizatorul — vezi discuția
  din sesiunea care a adăugat asta.

## Funcționalități implementate

1. CRUD mașini (multiple), revizii/carte service, documente, remindere personale.
2. RCA/CASCO/Rovinietă/ITP + asigurare locuință afișate direct pe ecranul principal (nu ascunse
   în tab-uri), cu buton „Salvează în calendar” per document.
3. Notificări locale pentru expirare documente (la N zile înainte + în ziua expirării), pentru
   revizii programate și pentru componente (vezi punctul 12).
4. Scanare OCR a talonului (cameră/galerie) → auto-completare marcă/model/VIN/nr. înmatriculare.
5. Tracker componente esențiale (ulei, filtre, plăcuțe, curea etc.) cu interval recomandat și
   status calculat pe baza kilometrajului curent + data ultimei schimbări.
6. Sistem țară/limbă (Setări → România sau Internațional), schimbabil oricând, cu România
   păstrând exact comportamentul original.
7. La adăugarea/editarea unei revizii, secțiune de bife cu componentele esențiale (aceleași din
   tracker) — bifarea unei componente face upsert automat în `component_records` cu data (și
   kilometrajul, dacă e completat) reviziei curente, păstrând notițele existente ale componentei.
   Bifele salvate se țin per revizie în `ServiceRecord.changedComponentIds`.
8. Buton „Verifică pe site-ul oficial” pentru documente RCA/ITP/Rovinietă — deschide pagina
   oficială corectă (RAR/AIDA/CNAIR) și copiază nr. înmatriculare sau VIN în clipboard; NU e
   interogare automată reală (vezi `lib/utils/document_verification_utils.dart` mai sus, motivul
   e CAPTCHA-ul obligatoriu pe toate cele trei surse).
9. Buton „Sugerează intervale pentru {marcă} {model}” pe tabul Info al mașinii — dacă lipsește
   `engineCode` dar există un VIN valid, încearcă întâi să-l deducă din VIN (vezi „Decodare VIN →
   motor” mai sus), apoi aplică (cu dialog de confirmare) intervalele găsite pentru `engineCode`
   în schema relațională de catalog, cu fallback pe model → marcă → mașină-veche (an < 2000) →
   nimic. Actualizează toate componentele găsite pentru codul motor (ulei, filtre, distribuție,
   curea accesorii, lichide, plăcuțe/discuri frână, bujii, ulei cutie, baterie...) și adaugă
   automat orice componentă lipsă din tracker (inclusiv „Ulei cutie de viteze”/„Ștergătoare
   parbriz”, adăugate mereu). Fără nicio potrivire, doar adaugă componentele universale lipsă,
   fără să schimbe intervale.
10. Câmp „Cod motor” pe vehicul (opțional) — completat manual, best-effort din scanarea talonului
    (`document_scanner_service.dart`), sau prin decodare VIN (butonul din formular sau automat la
    „Sugerează intervale”, vezi mai sus); alimentează catalogul din punctul 9.
11. Decodare VIN → motor (buton lângă câmpul VIN din formularul mașinii) — vezi secțiunea
    „Decodare VIN → motor” de mai sus pentru detalii tehnice.
12. Notificări pentru componentele din tracker, în două mecanisme complementare (ambele în
    `notification_service.dart`): **(a)** partea în *luni* a intervalului e programată dinainte
    (`scheduleComponentReminder` — o notificare la 85% din interval „recomandat curând” + una la
    100% „depășit”, calculate din `lastChangedDate` + `customIntervalMonths ?? intervalMonths`),
    apelată din toate cele 3 locuri care fac `upsertComponentRecord` (ecranul de editare
    componentă, bifele de la revizie, aplicarea profilului de mentenanță); **(b)** partea în *km*
    nu poate fi programată dinainte (nu știm când se atinge kilometrajul), deci e verificată
    reactiv (`checkComponentStatuses`) — trimite o notificare imediată (`_plugin.show`) pentru
    fiecare componentă care tocmai a intrat în dueSoon/overdue, cu deduplicare persistentă în
    `SharedPreferences` (cheie `component_notified_{vehicleId}_{componentId}` = ultimul status
    notificat; se șterge când statusul revine la ok/unset, ca o viitoare depășire să notifice din
    nou). Testat pe device: setarea kilometrajului 0→40000 cu plăcuțe schimbate la 0 km a produs
    notificarea „Plăcuțe frână față — depășit” o singură dată (a doua salvare identică nu a
    re-notificat). **`checkComponentStatuses` trebuie apelat din ORICE loc care schimbă ceva ce
    afectează raportul km/lună al unei componente** — nu doar la salvarea kilometrajului mașinii.
    Bug real găsit și fixat: inițial era apelat DOAR din `add_edit_vehicle_screen.dart` (salvarea
    mașinii) — editarea directă a unei componente din `edit_component_screen.dart` (care schimbă
    `lastChangedMileage`) nu declanșa nicio verificare, deci o componentă putea trece direct în
    dueSoon/overdue fără nicio notificare. Acum e apelat din toate cele 4 locuri care pot schimba
    raportul: **(1)** `add_edit_vehicle_screen.dart` — kilometraj nou pe mașină; **(2)**
    `edit_component_screen.dart` — `lastChangedMileage`/`lastChangedDate` schimbate direct;
    **(3)** `add_edit_service_record_screen.dart` — bifele de componente de la o revizie (revizia
    poate fi înregistrată la un kilometraj diferit de cel curent salvat pe mașină); **(4)**
    `vehicle_detail_screen.dart` (`_applyMaintenanceProfile`) — un `customIntervalKm` nou (ex. de
    la 90.000 km generic la 60.000 km specific motorului) poate împinge o componentă direct în
    dueSoon/overdue chiar fără nicio schimbare de `lastChangedMileage`.
13. Reminder LUNAR de kilometraj (`scheduleMileageReminder`/`cancelMileageReminder` în
    `notification_service.dart`) — completează punctul 12: partea de status în *km* a
    componentelor (`computeComponentStatus`, deja gestionează corect apropiat/egal/depășit prin
    `maxRatio >= 0.85`/`>= 1.0`) nu se poate actualiza singură dacă utilizatorul nu mai deschide
    ecranul de editare a mașinii cu un kilometraj nou — reminder-ul încurajează exact asta.
    Recurent, o dată pe lună, în ziua din `vehicle.createdAt` (limitată la 1-28) la ora 9, via
    `matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime` din
    `flutter_local_notifications` — suportat nativ de plugin pe Android/iOS, nu necesită
    re-programare manuală lunară din partea aplicației. Programat din 3 locuri: la salvarea
    mașinii (`add_edit_vehicle_screen.dart`, alături de `checkComponentStatuses`), anulat la
    ștergerea mașinii, și re-programat (idempotent) pentru toate mașinile la fiecare încărcare a
    `HomeScreen` — ultimul e migrarea pentru mașinile adăugate înainte de această funcționalitate,
    care altfel n-ar avea niciodată reminder-ul programat.
14. Atașare PDF la un document RCA/CASCO (`PhotoPickerField` cu `allowPdf: true`, folosit doar din
    `add_edit_document_screen.dart`) — utilizatorul poate atașa PDF-ul poliței deja cumpărate, ca
    să-l poată arăta unui polițist offline. Stocat în `photoPath` (reutilizat, fără migrație DB);
    `DocumentTile` arată un buton dedicat „Deschide PDF" (via `open_filex`) când `photoPath` se
    termină în `.pdf`. La atașare pe un document de tip `rca`/`casco`,
    `DocumentScannerService.scanRcaPdf` randează prima pagină ca imagine (`printing`'s
    `Printing.raster`, doar pagina 0 — polițele RCA pun asigurătorul/seria/valabilitatea pe prima
    pagină) și rulează același OCR (`google_mlkit_text_recognition`) folosit pentru talon, apoi
    `parseRcaText` extrage asigurătorul, seria/numărul poliței și valabilitatea. Regexurile au fost
    reglate pe o poliță RCA reală (HD Insurance/Hellas Direct) trimisă de utilizator — formatul
    "Seria RO/32/V32/LM Nr. 1100737277" și "Valabilitate Contract de la DD/MM/YYYY până la
    DD/MM/YYYY" par să vină dintr-un șablon standardizat A.S.F., deci sunt tratate ca pattern-uri
    primare (nu doar euristici generice); pentru asigurător e încercată întâi lista
    `_knownInsurers`, apoi fallback pe eticheta „DENUMIRE ASIGURĂTOR:" (tăiată la primul marker
    cunoscut — R.C./C.U.I./Sucursală etc. — ca să nu înghită și câmpurile următoare de pe același
    rând). Best-effort ca la codul de motor din VIN: nu blochează niciodată atașarea PDF-ului dacă
    OCR-ul eșuează sau nu găsește nimic. Test de regresie cu textul real:
    `test/document_scanner_service_test.dart` (`group('parseRcaText', ...)`).
    **Cinci bug-uri reale găsite și fixate testând pe DOUĂ polițe RCA reale trimise de utilizator,
    de la asigurători diferiți (Hellas Direct/HD Insurance și Anytime/Interamerican Hellenic) — nu
    doar pe text extras cu `pdftotext`, care ascunde toate:**
    - **Fundal transparent la randare**: pe iOS, `Printing.raster` întoarce pixeli RGBA cu fundal
      TRANSPARENT (pagina PDF nu are un fill alb opac) — trimisă ca atare la ML Kit, transparența
      se decodează ca negru, iar textul negru pe „negru" devine ilizibil (OCR găsea 0 caractere,
      deși imaginea randată avea dimensiuni și dimensiune fișier normale). Fix: randarea e
      compusă pe un canvas alb opac (`dart:ui` `Canvas`/`PictureRecorder`) înainte de OCR — vezi
      comentariul din `scanRcaPdf`.
    - **Confuzie diacritice OCR**: ML Kit a citit „până" ca „pånă" (å în loc de â) pe polița reală
      testată — eticheta de expirare (`_expiryDateLabel`) nu accepta acea variantă, deci data
      rămânea mereu necompletată deși restul câmpurilor (inclusiv data de început, aceeași linie)
      se extrăgeau corect. Fix: clasa de caractere a etichetei acceptă acum mai multe variante
      OCR-confuzabile ale diacriticelor (à/á/â/ã/ä/å), nu doar â.
    - Un al treilea bug, în UI nu în OCR: `_expiryDateTouched` (flag care previne suprascrierea
      unei date introduse manual de user) era inițializat `true` doar pentru că documentul era în
      editare (`d != null`), chiar dacă acea dată era doar valoarea implicită auto-generată
      (`DateTime.now() + 365 zile`), nu una introdusă real — asta bloca PERMANENT completarea
      automată a datei de expirare la re-atașarea unui PDF pe un document deja salvat. Fix:
      flag-ul pornește mereu `false`, devine `true` doar când userul chiar deschide manual
      date-picker-ul de expirare (`_pickDate(isStart: false)`) — deci completarea din PDF poate
      suprascrie o dată neatinsă manual, dar nu una aleasă explicit de user în sesiunea curentă.
    - **A doua poliță reală testată (Anytime/Interamerican Hellenic) nu completa data de
      început**: eticheta `_startDateLabel` cere „valabil" + „de la" pe același rând — pe acest
      PDF OCR-ul n-a mai recunoscut deloc cuvântul „Valabilitate" (cuvânt lung, predispus la
      erori), deci eticheta nu se potrivea, deși „până la" (fără nicio dependență de „valabil")
      tot a funcționat. Fix: dacă eticheta de expirare s-a găsit dar cea de început nu, ultima
      dată găsită ÎNAINTE de „până la" pe același rând e folosită direct ca dată de început —
      funcționează indiferent dacă eticheta „de la" a supraviețuit OCR-ului sau nu.
    - **Aceeași poliță nu completa numele asigurătorului**: acest asigurător nu folosește deloc
      eticheta „DENUMIRE ASIGURĂTOR:” (spre deosebire de Hellas Direct) — numele apare direct pe
      rândul de după antetul „CONTRACT DE ASIGURARE DE RĂSPUNDERE CIVILĂ AUTO RCA”. Fix: fallback
      pozițional suplimentar care caută acest antet și ia rândul următor ca nume asigurător (cu
      aceeași logică de tăiere la markeri cunoscuți). **Atenție**: markerul de tăiere „Sucursală”
      a fost eliminat din `_providerCutMarker` — pe această poliță „SUCURSALA BUCUREȘTI” e parte
      din numele legal propriu-zis al asigurătorului („...ATENA - SUCURSALA BUCUREȘTI”), nu
      eticheta unui câmp următor; păstrarea lui trunchia numele la jumătate.

## Roadmap — NU implementat, doar documentat (nu construi fără cerere explicită)

- Interogare **complet automată** RAR/AIDA/CNAIR (fără interacțiune din partea utilizatorului) —
  imposibilă fără un API plătit de la un broker care rezolvă el CAPTCHA pe partea lui; vezi nota
  despre `document_verification_utils.dart` de mai sus pentru ce există în schimb.
- Cumpărare RCA/Rovinietă in-app via broker + Apple/Google Pay (premium).
- Denumiri specifice per-țară pentru alte țări în afară de România (în prezent doar un profil
  generic „Internațional”).
- Selector de monedă, toggle km/mile, formatare dată localizată.

## Testare pe device fizic

- Telefon de test: Samsung SM-A405FN, conectat via **WiFi debugging** (adb wireless).
- SDK Android la `C:\Users\dodea\AppData\Local\Android\Sdk\platform-tools`.
- Device id-ul mDNS se poate schimba la fiecare reconectare (ex. suffix `(2)`, `(3)`...) — verifică
  mereu cu `adb devices -l` înainte de a rula comenzi cu `-s`.
- Conexiunea wireless cade des (ecran stins / timeout) — dacă o comandă adb se blochează sau dă
  `device offline`/`not found`, rulează `adb kill-server && adb start-server` și reconectează.
- Pentru instalare rapidă peste wifi (release build complet e ~80MB și poate da timeout), preferă
  `flutter build apk --release --split-per-abi` și instalează doar `app-arm64-v8a-release.apk`
  (~30MB) via `adb install -r`.
- `flutter run --release` rămâne **atașat** după lansare (proces rezident, așteaptă input pentru
  quit) — nu se termină singur după instalare reușită; pentru un install-and-detach curat, preferă
  `flutter build apk` + `adb install -r` separat.
- `test/widget_test.dart` e cunoscut ca fiind flaky/minimal pe acest mediu Windows — `sqflite`
  FFI (`sqflite_common_ffi`) nu are un `databaseFactory` funcțional aici. Nu insista să-l repari;
  e o limitare de mediu, nu o regresie de cod.
- **Inspectare directă a DB de pe device/emulator** (util când un bug pare să fie în date, nu în
  cod): `adb -s <device> exec-out run-as com.dodea.car_planner cat databases/car_planner.db >
  local.db`, apoi interoghează cu `sqlite3` local (disponibil la `C:\platform-tools\sqlite3` pe
  mașina asta). Funcționează fiindcă build-ul debug e `run-as`-abil implicit. Șterge fișierul local
  după — poate conține date personale ale userului (plăcuțe, VIN etc. din mașinile lui reale, nu
  doar din cele de test).

## Convenții

- Fără `flutter_localizations`/codegen ARB — orice string nou de UI merge în `lib/l10n/strings.dart`.
- Fără comentarii inutile în cod — doar acolo unde motivul din spate nu e evident din cod.
- Nu adăuga funcționalități din roadmap fără cerere explicită a utilizatorului.
