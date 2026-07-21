# CarPlanner

Aplicație Flutter (Android/iOS) pentru gestionarea mașinilor: detalii vehicul, istoric revizii/carte
service, documente (RCA/CASCO/Rovinietă/ITP, asigurare locuință), remindere și notificări locale.
Stocare **exclusiv locală** pe dispozitiv (SQLite), fără backend/cloud.

## Stack tehnic

- Flutter SDK instalat la `C:\flutter` (mutat de pe D: din cauza unui bug de compilare Kotlin
  incrementală cross-drive — `kotlin.incremental=false` e setat în `android/gradle.properties`
  ca fix suplimentar).
- SQLite via `sqflite`, singleton în `lib/db/database_helper.dart`, cu migrații `onUpgrade`
  (versiune curentă: 8 — v2 a adăugat tabela `component_records`, v3 a adăugat coloana
  `changedComponentIds` pe `service_records`, v4 a adăugat `customIntervalKm/Months/Source` pe
  `component_records` + tabela `vehicle_extra_components`, v5 a adăugat coloana `engineCode` pe
  `vehicles`, v6 a adăugat un prim set de tabele de catalog `vehicle_models`/`maintenance_intervals`
  — **înlocuite complet la v7**, dropuite necondiționat la orice upgrade `oldVersion<7`, nu mai
  există în cod; v8 a înlocuit integral *datele* din catalogul de la v7 cu un export mai mare,
  schema tabelelor rămânând neschimbată). **Atenție la migrații reutilizate:**
  `_createComponentRecordsTable` construiește schema originală v2 (fără coloanele custom*) fiindcă
  e refolosită de calea de upgrade `oldVersion<2` — `_onCreate` aplică deltele ulterioare (ALTER)
  separat, la fel ca un upgrade real, ca să nu existe două căi de cod cu scheme diferite pentru
  instalare nouă vs. upgrade. Tabela `vehicles` NU are problema asta (construită inline, nu prin
  funcție reutilizată), deci coloana `engineCode` a putut fi adăugată direct în `CREATE TABLE` +
  un singur `ALTER` la upgrade.
- **Tabele de catalog** (schemă din v7, date din v8): schemă relațională `marci`→`modele`→`motoare`
  (18 mărci / 153 modele / 256 motorizări, portate din `auto_mentenanta_3.sql` — v7 avea 18/60/91,
  din `auto_mentenanta_2.sql`), cu intervale specifice per motor în `intervale_mentenanta` (mai
  ales distribuție — singurul lucru care chiar diferă per motor) și fallback pe intervale generice
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
  `intervale_generice` au rămas identice între v7 și v8 (nu au fost regenerate în fișierul sursă),
  deci `componenta_id`-urile din `intervale_generice` rămân valide neschimbate.
- Notificări locale: `flutter_local_notifications` + `timezone`.
- OCR pe device (gratuit): `google_mlkit_text_recognition`, folosit pentru scanarea talonului auto.
- Calendar: `add_2_calendar` (necesită permisiuni `READ_CALENDAR`/`WRITE_CALENDAR` +
  `<queries>` pentru `ACTION_INSERT` în AndroidManifest).
- Poze: `image_picker` (cameră + galerie).
- i18n: sistem propriu, lightweight (NU `flutter_localizations`/ARB) — clasa statică `S` din
  `lib/l10n/strings.dart`.

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
- **Rezolvarea intervalului de mentenanță** (`vehicle_detail_screen.dart` →
  `_applyMaintenanceProfile`): cod motor (`getEngineForCode` găsește rândul din `motoare` după
  `cod_motor_key` normalizat → `getMaintenanceIntervalsForMotorId` citește din view-ul
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
3. Notificări locale pentru expirare documente (la N zile înainte + în ziua expirării) și
   pentru revizii programate.
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
9. Buton „Sugerează intervale pentru {marcă} {model}” pe tabul Info al mașinii — aplică (cu
   dialog de confirmare) intervalele găsite pentru `engineCode` în schema relațională de catalog
   (vezi mai sus), cu fallback pe model → marcă → mașină-veche (an < 2000) → nimic. Actualizează
   toate componentele găsite pentru codul motor (ulei, filtre, distribuție, curea accesorii,
   lichide, plăcuțe/discuri frână, bujii, ulei cutie, baterie...) și adaugă automat orice
   componentă lipsă din tracker (inclusiv „Ulei cutie de viteze”/„Ștergătoare parbriz”, adăugate
   mereu). Fără nicio potrivire, doar adaugă componentele universale lipsă, fără să schimbe
   intervale.
10. Câmp „Cod motor” pe vehicul (opțional) — completat manual sau best-effort din scanarea
    talonului (`document_scanner_service.dart`); alimentează catalogul din punctul 9.

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
