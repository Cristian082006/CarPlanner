# CarPlanner

Aplicație Flutter (Android/iOS) pentru gestionarea mașinilor: detalii vehicul, istoric revizii/carte
service, documente (RCA/CASCO/Rovinietă/ITP, asigurare locuință), remindere și notificări locale.
Stocare **exclusiv locală** pe dispozitiv (SQLite), fără backend/cloud.

## Stack tehnic

- Flutter SDK instalat la `C:\flutter` (mutat de pe D: din cauza unui bug de compilare Kotlin
  incrementală cross-drive — `kotlin.incremental=false` e setat în `android/gradle.properties`
  ca fix suplimentar).
- **Toolchain Android fixat la AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14.3** (`android/settings.gradle.kts`,
  `android/gradle/wrapper/gradle-wrapper.properties`) — coborâte explicit de la valorile implicite
  ale template-ului Flutter la data creării proiectului (AGP 9.0.1 / Kotlin 2.3.20 / Gradle 9.1.0),
  descoperit la portarea pe macOS fără toolchain Android preexistent (proiectul fusese testat doar
  pe Windows până acum, cu un toolchain probabil mai vechi). **AGP 9+ obligă la o alegere globală
  „built-in Kotlin" (`android.builtInKotlin=true/false`) pentru tot proiectul deodată** — dar
  pluginurile din acest proiect sunt la stadii diferite de migrare: `file_picker` (v11+) presupune
  deja built-in Kotlin activat (nu mai aplică el însuși plugin-ul Kotlin pe AGP 9+), în timp ce
  `add_2_calendar` încă aplică manual `org.jetbrains.kotlin.android` — combinație imposibil de
  satisfăcut simultan sub AGP 9 (fie unul, fie celălalt eșuează la compilare cu „cannot find
  symbol"/„KGP was not found on the classpath"). AGP 8.11.1/Kotlin 2.2.20 (minimul recomandat chiar
  de avertismentele Flutter tool) nu au această problemă. **Dacă mai apare un asemenea conflict la
  o viitoare actualizare de pluginuri**, nu presupune că soluția e activarea/dezactivarea
  `android.builtInKotlin` — verifică întâi dacă TOATE pluginurile folosite sunt migrate la același
  stil, altfel rămâi pe un AGP <9.
- SQLite via `sqflite`, singleton în `lib/db/database_helper.dart`, cu migrații `onUpgrade`
  (versiune curentă: 31 — v2 a adăugat tabela `component_records`, v3 a adăugat coloana
  `changedComponentIds` pe `service_records`, v4 a adăugat `customIntervalKm/Months/Source` pe
  `component_records` + tabela `vehicle_extra_components`, v5 a adăugat coloana `engineCode` pe
  `vehicles`, v6 a adăugat un prim set de tabele de catalog `vehicle_models`/`maintenance_intervals`
  — **înlocuite complet la v7**, dropuite necondiționat la orice upgrade `oldVersion<7`, nu mai
  există în cod; v8/v9/v10/v11 au înlocuit succesiv *datele* din catalog cu exporturi tot mai mari,
  v12/v13 au fost completări punctuale pentru un singur motor (Ford Fiesta 1.6 TDCi, cerut de un
  utilizator), v14 a **eliminat** 882 de motorizări generate mecanic (vezi mai jos), v15 a
  înlocuit catalogul cu structura **consolidată** din `auto_mentenanta_5.sql` (un singur rând per
  nameplate, fără generații — vezi mai jos), v16 a corectat intervalul de ulei motor pentru diesel
  (vezi „Verificare acuratețe intervale” mai jos), iar v17 a adăugat reguli specifice de ulei motor
  pentru Honda (i-CTDi/i-DTEC) și Mitsubishi (DI-D) — la cererea explicită a utilizatorului, aplicate
  chiar și acolo unde fallback-ul generic era deja conservator, nu doar unde era periculos ca la
  Dacia (vezi mai jos), iar v18 a mai adăugat un lot: Fiat/Jeep MultiJet 1.6/2.0, Suzuki 1.9 DDiS
  (ambele conservatoare) și **Porsche V6 TDI — a doua descoperire, după Dacia, de fallback prea
  permisiv (periculos)**, iar v19 a adăugat Land Rover TDV6/TD4 (conservatoare) — Nissan M9R/R9M și
  Jeep 3.0 CRD au fost verificate dar nu au primit regulă (surse conflictuale, vezi mai jos), iar
  v20 a mai adăugat Fiat 1.3 MultiJet, Mitsubishi L200 4N15 și Land Rover Td5/TDV8/SDV6 (toate
  conservatoare). **v21 e lotul final** (utilizatorul a cerut continuare autonomă până la
  finalizarea întregului catalog): Toyota D-4D, PSA HDi/BlueHDi (interval diferit per generație) și
  Volvo 2.4D/D5 (interval diferit per generație) — toate conservatoare; VW/Audi/Seat/Skoda TDI CR,
  BMW, Mercedes OM6xx, Opel CDTI și Mazda Skyactiv-D au rămas fără regulă (surse conflictuale sau
  insuficiente, vezi mai jos), iar v22 a reverificat Hyundai/Kia CRDi cu surse UK/EU specifice și
  DE DATA ASTA a dat un rezultat suficient de consistent (15000 km/12 luni) pentru un fix — spre
  deosebire de runda anterioară (v19, surse US/UK amestecate, ambigue), iar v23 a reverificat Renault
  dCi cu surse UK specifice: K9K confirmat corect (egal cu fallback-ul generic), F9Q/M9R au primit
  reguli diferite (fără FAP vs. cu FAP), iar v24 a reverificat Nissan M9R/R9M (rămas fără regulă —
  conflict real de data asta, nu ambiguitate) și Jeep CRD (fix aplicat, sursă UK consistentă), iar
  v25 a reverificat BMW diesel cu surse UK — de data asta fix aplicat (18000 mile/24 luni, sursă UK
  consistentă), iar v26 a reverificat VW/Audi/Seat/Skoda TDI CR cu surse UK — fix aplicat (schema
  Fixed, 15000 km/12 luni) pe toate cele 64 de motoare rămase, iar v27 a reverificat ultimele 4
  cazuri ambigue (Nissan M9R/R9M, Mercedes OM6xx, Opel CDTI, Mazda Skyactiv-D) cu surse UK — Nissan
  a rămas fără regulă (conflict real chiar și în surse UK), celelalte 3 au primit fix, iar v28 a
  găsit motivul real al conflictului M9R (schimbare de schemă la o actualizare de model, sfârșit
  2010) și a aplicat fix pe R9M (motorul mai nou care l-a înlocuit) — schema tabelelor rămânând
  neschimbată pe tot parcursul, mai puțin faptul că `modele.generatie` e NULL peste tot din v15,
  iar v29 a extins lista de modele Ford (la cererea utilizatorului, pornind de la un caz concret:
  un Focus 120cp benzină+GPL nerecunoscut din talon) — GPL e tratat ca Benzina (conversie
  aftermarket, codul de motor de pe talon rămâne cel original pe benzină; catalogul nu are și nu a
  primit o categorie separată de combustibil GPL/bi-fuel). Cauza reală a cazului concret: lipsea
  varianta 1.6 Ti-VCT 125cp „Sigma" (cod **IQDB**) la Focus — adăugată. În plus, la cererea
  explicită „adaugă toate modelele de Ford" (limitat de utilizator la modele 2005+ vândute pe
  piața RO/UE, nu tot istoricul Ford), au fost adăugate 10 modele noi: **Ka** (2008-2016),
  **Ka+** (2016-2021), **C-Max** (2003-2019, o singură nameplate consolidată ca la celelalte
  modele post-v15, deși acoperă 2 generații), **B-Max** (2012-2017), **S-Max** (2006-prezent),
  **Galaxy** (2006-prezent), **Edge** (2016-2018), **Ranger** (2006-prezent), **Tourneo Custom**
  (2013-prezent), **Tourneo Connect** (2013-2023) — toate adăugate la finalul tabelei `modele`
  (id 236-245), NU inserate în mijloc, ca să nu deraieze id-urile hardcodate din `motoare`/
  `intervale_mentenanta` ale celorlalte mărci de după Ford în listă (Honda etc.). Motorizări
  adăugate DOAR pentru modelele cu cel puțin un cod confirmat de 2 surse independente în cercetarea
  web făcută pentru acest lot: C-Max (HXDA 1.6 Ti-VCT 100, G8DA 1.6 TDCi 90, IQDB 1.6 Ti-VCT 125),
  S-Max și Galaxy (QXWA/UFWA 2.0 TDCi 140, cod comun — aceeași platformă WA6), Edge (T9CE 2.0 TDCi
  Bi-Turbo 210), Ranger (WEAT 3.0 TDCi 156 și WLAT 2.5 TDCi 143 pentru generația 2006-2011, P4AT
  2.2 TDCi 160/P5AT 3.2 TDCi 200/YN2X 2.0 EcoBlue Bi-Turbo 213 pentru generația 2012-2022, distins
  prin lanț vs. curea de distribuție). **Ka, Ka+, B-Max, Tourneo Custom și Tourneo Connect NU au
  primit nicio motorizare** — singurele coduri găsite pentru ele proveneau dintr-o singură sursă
  neconfirmată sau erau doar cifre de putere fără cod alfanumeric verificabil (mai ales la Tourneo,
  nicio sursă cu cod real găsită deloc) — există doar ca model în catalog, fără potrivire pe cod de
  motor (la fel ca Mustang Mach-E, deja fără motoare fiindcă e electric). Verificat cu test scratch
  (șters după confirmare) că IQDB se rezolvă distinct pe Focus vs. C-Max prin `make`/`model`
  (mecanismul existent din `getEngineForCode`, nu unul nou), că G8DB rămâne neschimbat pe Fiesta
  (90cp) în ciuda noului G8DA de pe C-Max (cod diferit, nu coliziune), și că toate cele 5 modele
  fără motorizare întorc listă goală prin `getCandidateEnginesForVin`.
  **v30 (fix real al cazului concret, la scurt timp după v29):** IQDB (125cp/92kW) nu era de fapt
  motorul colegului utilizatorului — talonul lui arată explicit **88kW/120cp**, o variantă diferită
  de 1.6 Ti-VCT, mai veche (2011-2012), cu codul **MUDA/MUDD** (confirmat pe kateurope.com,
  auto-data.net, motorinsel.eu — toate dau 1596cc/88kW/120cp pentru acest cod exact). Observație
  importantă: sursele arată MUDA/MUDD ca fiind folosit inițial (poate exclusiv) pe trimul
  "Flexifuel" (motor pregătit pentru etanol E85, NU GPL) al Focus/C-Max — dar e același bloc fizic
  Sigma 1.6 Ti-VCT ca varianta normală pe benzină, deci codul de pe talon rămâne valabil indiferent
  de conversia GPL aftermarket a colegului (GPL ≠ E85, dar hardware-ul motorului e identic). IQDB nu
  a fost eliminat — rămâne un motor real pentru alți Focus/C-Max (2014-2018, 125cp) — MUDA/MUDD s-a
  adăugat suplimentar, pe Focus (id 54) ȘI C-Max (id 238, același motor a fost disponibil și acolo
  ca Flexifuel). Nicio schimbare de schemă, doar date noi — DROP+reseed ca la toate migrațiile
  anterioare de catalog.
  **v31 (verificare intervale ulei Ford, la cerere explicită):** după ce s-au adăugat multe
  motorizări Ford noi la v29/v30, utilizatorul a cerut verificarea intervalelor de schimb pentru
  toată gama. Rezultat: **Fiesta/Focus/C-Max/Kuga/Mondeo/S-Max/Galaxy rămân AMBIGUE** — surse Haynes
  pentru modele specifice (Fiesta Mk7, Focus Mk3) dau consistent 12500 mile/12 luni (~20000 km,
  petrol ȘI diesel deopotrivă), dar alte surse (Kuga Euro6.2, afirmații generale Ford UK) dau 18000
  mile/24 luni pentru modele mai noi — posibil o extindere reală de-a lungul timpului (ca la BMW/VW
  în v25/v26), dar fără o sursă care să confirme explicit pragul de an — **nicio regulă aplicată**,
  la fel ca VW/BMW/Mercedes înainte de re-verificările lor dedicate; poate fi reluat separat cu
  surse UK specifice dacă se cere. **Ford Ranger** (WEAT/WLAT/P4AT/P5AT/YN2X, toate cele 5 motoare
  diesel din catalog, motor id 777-781) e diferit — sursă dedicată AUTODOC + confirmare forum UK dau
  consistent **15000 km/12 luni**, vizibil mai scurt decât gama de pasageri (plauzibil, uz
  comercial/off-road mai solicitant) — regulă aplicată pe toate cele 5 (sursa nu diferențiază între
  ele). Aceeași sesiune a mai adăugat filtrarea listei de motoare candidate din dialogul de decodare
  VIN după puterea (CP) citită de pe talon la câmpul P.2 (`lib/screens/add_edit_vehicle_screen.dart`,
  `_scannedPowerCp` — populat din `document_scanner_service.dart`, care extrage P.2 ca pereche
  "kW (CP)" dacă valoarea din paranteză e plauzibilă ca putere, altfel convertește kW→CP; extrage și
  anul din câmpul B, la fel — ambele confirmate de utilizator că funcționează pe talonul lui real).
  **v32 (motorizări VW Polo lipsă, la cerere explicită):** utilizatorul a observat, testând
  filtrarea din decodarea VIN pe un Polo, că multe motorizări reale lipseau din catalog (doar 6
  existau pentru Polo). Cercetare web cu minim 2 surse independente per motor (auto-data.net,
  autodoc, ultimatespecs, proxyparts, mymotorlist, zeperfs, encycarpedia) — adăugate 9 motorizări
  noi (model_id 219): **ASY** (1.9 SDI 64, 2001-2009), **BME** (1.2 12V 64, 2001-2007), **BNM**
  (1.4 TDI 70, 2005-2009, predecesorul lui CFWA), **BTS** (1.6 16V 105, 2006-2010), **CFW** (1.2
  TDI 75, 2009-2014), **CAYC** (1.6 TDI 90, 2009-2015), **CTHE** (1.4 TSI GTI 180, 2010-2014),
  **CHYA**/**CHYB** (1.0 MPI atmosferic 65/75cp, 2017+, distinct de CHZC/DKRF care sunt 1.0 TSI
  turbo). **NU** adăugate (surse insuficiente/ambigue la o singură căutare): BMD (1.2 6V), BBY/BUD
  (1.4 16V — posibil același motor fizic ca AUA deja existent, sub alt cod, neclar diferențiat),
  DKFC (nicio sursă găsită), și inițial presupusul "ANJ" pentru 1.2 TDI 75cp — corectat la **CFW**
  înainte de adăugare, după ce cercetarea n-a confirmat codul ANJ. **Bug real găsit și fixat în
  timpul acestei actualizări**: primele rânduri au fost inserate greșit în MIJLOCUL tabelei
  `motoare` (imediat după blocul Polo existent), ceea ce a deplasat id-urile auto-increment ale
  TUTUROR rândurilor de după — a stricat exact regula de distribuție hardcodată pentru codurile
  Fiesta 1.6 TDCi de la v13 (`test/ford_fiesta_test.dart` a prins bug-ul imediat). Fix: rândurile
  noi mutate la FINALUL absolut al tabelei `motoare` (după ultimul rând Ford), fără să atingă
  id-ul niciunui rând existent — regulă deja documentată mai jos, dar încălcată din neatenție la
  prima încercare; verificat cu teste (`test/polo_engines_test.dart`, plus corectarea contorului
  vechi din `test/ford_fiesta_test.dart` de la 6 la 15 motorizări Polo). Inițial nu s-au adăugat
  reguli de interval specifice pentru cele 9 motoare noi (rămân pe fallback generic per
  combustibil) — dar utilizatorul a cerut imediat după o trecere dedicată de verificare, la fel ca
  la celelalte mărci din istoric. **Rezultat cercetare (tot v32, aceeași sesiune):** cele 4 motoare
  diesel noi (ASY/BNM/CFW/CAYC) au primit regulă specifică — **15000 km/12 luni**, surse UK
  (autodoc.co.uk, buycarparts.co.uk, uk-polos.net, oil-change.info) convergente, exact aceeași
  cifră ca la fix-ul VAG TDI CR de la v26 (schema Fixed, aleasă acolo ca fiind mai sigură decât
  Longlife/Variable) — deși ASY (1.9 SDI) e tehnic injecție indirectă, nu common-rail, cifra
  practică de schimb ulei iese identică. Cele 5 motoare pe benzină (BME/BTS/CTHE/CHYA/CHYB) rămân
  pe fallback generic — nicio sursă dedicată găsită pentru ele, nu era scopul cercetării. Regula a
  fost adăugată printr-un `INSERT...SELECT` după `cod_motor` (nu id-uri hardcodate), tocmai ca să
  nu repete bug-ul de mai sus dacă motoarele s-ar reordona vreodată. Verificat cu teste
  (`test/polo_engines_test.dart`).
  **v33 (motorizări Ford Focus lipsă, la cerere explicită, doar 2005+):** utilizatorul a întrebat
  dacă Focus are toate motorizările — nu, lipseau 1.0 EcoBoost (100/125cp), 2.0 EcoBoost ST
  (250cp), 2.3 EcoBoost RS (350cp), variante suplimentare de 2.0 TDCi și 1.5 TDCi. Cercetare web:
  doar **M1DA** și **M2DA** (1.0 EcoBoost 125/100cp) au cod alfanumeric confirmat de minim 2 surse
  independente (247spares ×2, galamotors, 3ngines, 365engines, mymotorlist) — restul (ST/RS/TDCi
  suplimentar) au doar cifre de putere fără cod verificabil, la fel ca Ka+/Tourneo la v29, deci
  **nu au fost adăugate**. **Bug real găsit în timpul cercetării**: codul **M1DA**, deja existent
  în catalog pentru Focus ca „1.6 Ti-VCT 105", era **greșit** în exportul original — 5+ surse
  independente confirmă unanim că M1DA e de fapt **1.0 EcoBoost 125cp** (998cc, 3 cilindri), nu
  1.6 Ti-VCT. Corectat (rândul rămâne pe aceeași poziție, doar valorile s-au schimbat — nu
  afectează niciun id existent) + adăugat **M2DA** (1.0 EcoBoost 100cp) la finalul tabelei
  `motoare` (cod deja folosit pe Fiesta pentru același motor fizic, la o altă combinație
  marcă+model — permis, `UNIQUE(model_id, cod_motor)` nu e global). Interval de ulei cercetat
  pentru M1DA/M2DA dar **rămas ambiguu**: o sursă dă 15000 km/12 luni, alta dă 12500 mile/12 luni
  (~20000 km) pentru modele pre-2019 vs. 18500 mile/24 luni pentru 2019+ — exact aceeași ambiguitate
  deja documentată la v31 pentru toată gama Focus, deci **nicio regulă nouă aplicată**, rămân pe
  fallback generic ca restul gamei. Verificat cu teste (`test/focus_engines_test.dart`).
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
  cele ale unei generații). 26 mărci / **245 modele** (235 din export + cele 10 modele Ford
  adăugate manual la v29, vezi mai jos) / **791 motorizări** (756 din export + cele 7
  coduri reale Fiesta VI 1.6 TDCi de la v13 — HHJC/HHJD/HHJE/TZJA/TZJB/T1JA/UBJA — + cele 9
  motorizări VW Polo de la v32 — ASY/BME/BNM/BTS/CFW/CAYC/CTHE/CHYA/CHYB — + M2DA (Ford Focus) de
  la v33 — toate re-adăugate manual la finalul secțiunilor `motoare`/`intervale_mentenanta`
  fiindcă **lipsesc din exportul consolidat**; nu le șterge la o portare viitoare fără să verifici
  că noul export le conține) /
  1075+14 reguli specifice (doar distribuție, componentele 5/6 — restul componentelor vin din
  regulile generice per combustibil, prin view). Coloana `modele.generatie` rămâne în schemă
  (query-urile o referă) dar e NULL peste tot. Exportul v15 a fost verificat la portare pentru
  bug-ul H/L de mai jos — zero perechi formulaice. `componente`/`intervale_generice`/`marci` sunt
  identice byte-cu-byte cu v7–v14, deci `componenta_id`-urile și `marca_id`-urile rămân valide.
  Test de regresie: `test/ford_fiesta_test.dart` (rulează pe macOS cu sqflite FFI; limitarea FFI
  din nota de mai jos era specifică mediului Windows vechi — `widget_test.dart` însă tot pică,
  fiindcă nu-și inițializează singur factory-ul FFI).
  **Verificare acuratețe intervale (v16):** la cererea utilizatorului, am eșantionat 111 motorizări
  reale (15 modele comune, de la Dacia la BMW/Toyota hibrid) și am confirmat că fallback-ul generic
  pentru "Ulei motor + filtru ulei" (`intervale_generice`, singurul folosit vreodată pentru ulei —
  `intervale_mentenanta` avea reguli specifice per motor DOAR pentru distribuție, niciodată pentru
  ulei, înainte de v16) era **identic (15000 km/12 luni) pe toate cele trei combustibili**
  (Benzina/Diesel/Hibrid), deci deloc diferențiat per motor — confirmă disclaimer-ul din comentariul
  de mai sus („orientative, nu preluate 1:1"). Am verificat prin căutare web (surse: Dacia
  user-manual.dacia.com, BMW/VW forumuri oficiale) câteva cazuri: Dacia 1.5 dCi are interval oficial
  **10.000 km/12 luni** (catalogul arăta 15.000 — greșit în direcția periculoasă, încuraja
  sub-întreținere), BMW N20/N47 cu ulei Longlife-04 poate ajunge la ~30.000 km/24 luni (catalogul
  conservator, sigur), VW TDI cu ulei 507 00 variază 15-30k după modul de service ales (catalogul
  se potrivește cu modul „Fixed", conservator). Fix aplicat: (1) fallback-ul generic Diesel coborât
  de la 15000 la 12000 km/12 luni (compromis mai realist pentru diesel fără ulei longlife, rămâne
  conservator pentru cele cu longlife); (2) reguli specifice noi în `intervale_mentenanta` pentru
  cele 6 motorizări Dacia K9K (dCi) — motor id 131/133 (Duster), 137/138 (Logan), 141/143
  (Sandero) — suprascriu fallback-ul cu intervalul oficial verificat de 10.000 km/12 luni (view-ul
  `mentenanta_completa` face deja COALESCE pe regula specifică înaintea celei generice, exact
  mecanismul folosit pentru distribuție). Restul catalogului (peste 750 de motorizări) **rămâne
  neverificat individual** — o verificare exhaustivă per motor față de manualele oficiale ale
  fiecărui producător nu e fezabilă într-o singură trecere; eșantionul de mai sus e un sondaj de
  încredere, nu o garanție completă. Teste de regresie: `test/get_engine_for_code_test.dart`.
  **Continuare verificare + v17:** utilizatorul a cerut extinderea eșantionării la mai multe
  branduri (Renault/Hyundai/Kia — ambigue, surse EU insuficient de clare, NU s-a aplicat niciun
  fix; Ford/Peugeot/Citroen/Opel/Mercedes/Toyota/Fiat/Seat/Volvo/Mazda/Nissan/Land Rover/Škoda —
  confirmate conservatoare, deci fără fix; Honda/Mitsubishi — vezi mai jos). Apoi utilizatorul a
  cerut explicit ca fix-urile să se aplice **chiar și când fallback-ul generic era deja
  conservator** (nu doar în direcția periculoasă ca la Dacia), ceea ce a dus la v17: reguli
  specifice noi pentru Honda 2.2 i-CTDi/i-DTEC (motor id 202/204/207/209/215 → 20000 km/12 luni,
  sursă AUTODOC) și 1.6 i-DTEC (motor id 217/219 → 15000 km/12 luni, sursă forum civinfo.com Civic
  FK3), plus Mitsubishi DI-D 1.8/2.2 (motor id 414/421/424/426 → 20000 km/24 luni, surse forumuri
  ASX/Outlander). **Încredere moderată** pe toate cele 3 (surse secundare/forumuri, nu manualul
  oficial al producătorului ca la Dacia) — asumat explicit de utilizator. Motoarele Mitsubishi 4D68
  (2.0 DI-D, Lancer vechi) și 4N15 (2.4 DI-D, L200 pickup) NU au regulă specifică — generații/motoare
  diferite de cele acoperite de sursă, rămân pe fallback-ul generic. Verificat cu un test scratch
  (șters după confirmare, nu există permanent în `test/`) că toate cele 11 rânduri noi se rezolvă
  corect prin view-ul `mentenanta_completa`.
  **v18 (alt lot):** Fiat/Jeep MultiJet 1.6 (motor id 155/157/159/161/169/280) și 2.0 (270) →
  35000 km/24 luni (sursă: forumuri Fiat citând schema oficială — excepția „12 luni dacă uz urban
  <10000 km/an" nu e modelată, doar valoarea standard); Suzuki 1.9 DDiS (617 RHZ Grand Vitara, 622
  9HZ SX4 — extins de la RHZ) → 15000 km/12 luni (sursă auto-abc.eu). Ambele conservatoare
  (catalogul era deja sub valoarea reală), încredere moderată. **Porsche V6 TDI Cayenne/Panamera**
  (516/518/520/524, motor M55.01/CTBA/SCR-231/CKUA — aceeași platformă VW/Audi/Porsche) →
  **7500 km/12 luni**, sursă documentație oficială Porsche citată pe 6speedonline/rennlist — **a
  doua descoperire (după Dacia) de fallback prea permisiv**: catalogul avea 12000 km, deci mașinile
  cu acest motor riscau să fie întreținute mai rar decât recomandarea reală a producătorului. NU
  s-a extins la 1.3 DDiS Suzuki (Swift, D13A) sau la CRD 2.8/3.0 Jeep (Cherokee/Grand Cherokee,
  familie de motor diferită, Iveco/VM) — fără sursă specifică pentru acestea. Verificat cu test
  scratch (șters după confirmare) că toate cele 13 rânduri noi se rezolvă corect.
  **v19 (alt lot):** Nissan M9R/R9M (X-Trail/Qashqai) și Jeep 3.0 CRD (Grand Cherokee, VM
  Motori/Mercedes OM642) au fost cercetate dar au dat surse conflictuale — Nissan menționează
  „12 luni/18k mile" ÎNTR-UN loc și „10.000 km" în alt manual (Australia); Jeep menționează
  „Schedule A: 20.000 km" vs. „Schedule B: 10.000 km" după condiții de condus — la fel ca la
  Renault/Hyundai-Kia mai devreme, nu există un singur număr de încredere, deci **nu s-a aplicat
  nicio regulă**, catalogul rămâne pe fallback-ul generic. În schimb, Land Rover a dat numere clare:
  **TDV6 3.0** (Discovery TDV6/2009 id 324, Range Rover Sport TDV6 id 336 — același motor) →
  26.000 km/12 luni (sursă forum aulro.com); **TD4 2.0** (Discovery Sport 326, Freelander TD4 330,
  Range Rover Evoque 334 — același motor TD4/Ingenium) → 34.000 km/24 luni (sursă
  landroveranaheimhills.com). Ambele conservatoare, încredere moderată (surse secundare). NU extins
  la Defender Td5 (319), Discovery TDV6/2004 (322, motor 2.7 mai vechi), Freelander L-Series (328),
  Range Rover TDV8 (332) sau Range Rover Sport SDV6 (338) — generații/motoare diferite, fără sursă
  specifică. Verificat cu test scratch (șters după confirmare) că toate cele 5 rânduri noi se
  rezolvă corect.
  **v20 (alt lot):** Fiat 1.3 MultiJet (Panda 163, Punto 167 — surse boards.ie/fiatforum.com) →
  20.000 km/24 luni; Mitsubishi L200 4N15, generația KJ/KK/KL 2015+ (416, sursă auto-abc.eu/AUTODOC)
  → 15.000 km/12 luni (generațiile mai vechi de L200, 2.5 DI-D/4D56, aveau 10.000 km, dar nu există
  ca motor separat în catalog); Land Rover **Td5** (Defender, 319, sursă manual/twinwoods4x4.com) →
  20.000 km/12 luni, **TDV8** (Range Rover, 332, sursă landyzone.co.uk, ~16.000 mile rotunjit) →
  26.000 km/12 luni, **SDV6** (Range Rover Sport, 338, sursă roverparts.eu) → 15.000 km/12 luni.
  Toate conservatoare, încredere moderată (surse secundare). NU extins la Discovery TDV6/2004 (322,
  motor 2.7 mai vechi) sau Freelander L-Series 2.0 Di (328, altă familie de motor) — fără sursă
  specifică. Verificat cu test scratch (șters după confirmare) că toate cele 6 rânduri noi se
  rezolvă corect.
  **v21 (lot final — continuare autonomă la cererea utilizatorului):** am trecut prin TOT restul
  catalogului rămas neverificat, brand cu brand. Rezultat:
  - **Toyota D-4D** (Auris 635, Avensis 639/640, Corolla 651/652, RAV4 659/661/663, Yaris 667) →
    **15.000 km/12 luni**, sursă directă manual oficial Toyota Europa (manuals.plus, Yaris) +
    confirmări forum. Încredere mai mare decât restul lotului (sursă primară găsită).
  - **PSA HDi** (non-Blue, generație mai veche — toate motoarele Peugeot/Citroën codate DV4TD/DV6C/
    DV6TED4/DW10TD/DW10BTED4/DW10FC fără „Blue" în denumire) → **20.000 km/12 luni**.
  - **PSA BlueHDi** (generație Euro6+, denumire conține explicit „BlueHDi") → **26.000 km/12 luni**
    (rotunjit din 16.000 mile; unele surse menționează până la 40.000 km/2 ani pe schemă flexibilă,
    dar 26.000 km e valoarea „standard" mai des citată).
  - **Volvo 2.4D/D5** (5 cilindri) — **generație veche** (S60 727 2000-2009, S80 732 2000-2006,
    V70 742 2000-2007) → 20.000 km/12 luni; **generație nouă** (S80 734 2006-2016, V70 743
    2007-2016, XC60 D5244T 750 2010-2017, XC90 754/756) → 30.000 km/12 luni. NU extins la motoarele
    D4204T (platforma Drive-E, 2010+, complet diferită) — fără sursă specifică pentru acelea.
  - **Rămase fără regulă** (cercetate dar surse conflictuale/insuficiente, la fel ca Renault/
    Hyundai-Kia/Nissan/Jeep mai devreme): VW/Audi/Seat/Skoda 2.0 TDI CR (Longlife variabil,
    9.000-30.000 mile după configurare), BMW (Condition Based Service, variază 10.000-18.000 mile),
    Mercedes OM6xx (ASSYST PLUS variabil, Service A ~25.000 km/12 luni vs. Service B ~40.000 km/24
    luni — prea diferite pentru un singur număr), Opel CDTI (surse contradictorii: 30.000 km vs.
    16.000 km pentru aceleași coduri de motor Z-prefix), Mazda Skyactiv-D (nicio sursă diesel-
    specifică găsită, doar date generice de manual american pentru benzină). Acestea rămân pe
    fallback-ul generic Diesel (12.000 km/12 luni din v16) — **catalogul e considerat complet
    verificat** la acest nivel de efort (eșantion + cercetare pe familii de motor, nu 1-la-1 pe
    toate cele 763 de motorizări individuale — vezi disclaimer-ul de la v16).
  Verificat cu test scratch (șters după confirmare) că toate cele 45 de rânduri noi (9 Toyota + 17
  PSA HDi + 11 PSA BlueHDi + 8 Volvo) se rezolvă corect prin `mentenanta_completa`.
  **v22 (reverificare Hyundai/Kia, la cerere explicită):** runda v19 (Renault/Hyundai-Kia
  împreună) folosise căutări generice care amestecau piața US cu UK/EU, dând rezultate
  contradictorii — de-aici decizia de a NU aplica niciun fix atunci. Reverificat separat, cu căutări
  restrânse explicit la surse UK/hyundai-forums.com/i30ownersclub.com: **15.000 km/12 luni** apare
  consistent și repetat pentru CRDi pe mai multe generații și modele (i30, Tucson, Santa Fe) —
  suficient de solid pentru un fix, spre deosebire de v19. Există variații marginale citate (10.000
  mile/~16.000 km pentru generația veche 2006-2009, ex. Santa Fe 2.2 CRDi D4EB; 20.000 mile/~32.000
  km pentru modele UK mai noi), dar 15.000 km e valoarea de mijloc cea mai des confirmată, aplicată
  uniform fără a separa pe generații (spre deosebire de PSA HDi/BlueHDi sau Volvo mai sus, unde
  distincția generațională era suficient de clară). Aplicat pe **toate** motoarele CRDi Hyundai
  ȘI Kia (D3EA/D4EA/D4EB/D4HA/D4HB/D4FA/D4FB/D4CB/D4FD/U2) — Hyundai și Kia partajează literalmente
  aceleași motoare în grup (coduri identice D4FB/D4EA/D4FA/D4HA apar la ambele mărci în catalog).
  25 de rânduri noi, verificate cu test scratch (șters după confirmare) că se rezolvă corect.
  **v23 (reverificare Renault, la cerere explicită):** la fel ca la Hyundai, runda v19 amesteca
  surse mai generice; reverificat cu surse UK specifice (daciaforum.co.uk, renaultforums.co.uk,
  meganeownersclub.co.uk). Rezultat:
  - **K9K** (Clio/Captur/Megane/Scenic, plus echivalentul Nissan Micra/Note/Qashqai) — sursă
    oficială Renault UK (sistem OCS, citat pe daciaforum.co.uk): **12.000 km/12 luni** — coincide
    EXACT cu fallback-ul generic Diesel (v16), deci **nu s-a adăugat nicio regulă nouă**, K9K e
    confirmat corect așa cum e deja.
  - **F9Q** (1.9 dCi, generație mai veche, FĂRĂ FAP/DPF de bază — Megane 552, Scenic 558) →
    **29.000 km/12 luni** (sursă: 18.000 mile, renaultforums.co.uk).
  - **M9R** (2.0/1.9 dCi, generație mai nouă, CU FAP/DPF de serie — Espace 545, Laguna 548/550) →
    **14.500 km/12 luni** (sursă: 9.000 mile pentru motoarele cu filtru de particule, aceeași
    sursă) — interval mai scurt din cauza diluării uleiului cu funingine la motoarele cu FAP.
  - **F8Q** (Clio, 1.9 dCi vechi, indirect injection) — fără sursă specifică, rămâne pe fallback.
  5 rânduri noi (2 F9Q + 3 M9R), verificate cu test scratch (șters după confirmare) — inclusiv
  confirmarea explicită că K9K rămâne pe 12.000 km prin fallback, nu prin regulă redundantă.
  **v24 (reverificare Nissan M9R/R9M + Jeep CRD, la cerere explicită):**
  - **Nissan M9R/R9M — TOT fără regulă, dar de data asta e un conflict real, nu zgomot de
    căutare.** Sursă UK Nissan (x-trail-uk.co.uk, X-Trail 2.0 dCi M9R 2012): 18.000 mile/12 luni
    (~29.000 km). Problema: M9R e **literalmente același motor fizic** ca Renault M9R (alianța
    Renault-Nissan), pentru care sursa UK Renault (v23) a dat 9.000 mile/~14.500 km (variantă cu
    FAP). Două surse UK, pentru același motor, diferă de peste 2×— o contradicție reală între
    branduri (poate un artefact al unor scheme de service diferite alese de fiecare producător
    pentru același hardware), nu ambiguitate rezolvabilă prin căutare mai bună. Rămâne pe
    fallback-ul generic (12.000 km). R9M (Qashqai 1.6 dCi) — nicio cifră găsită, fără sursă.
  - **Jeep CRD (2.0/2.8/3.0, Compass/Patriot/Cherokee/Grand Cherokee)** → **20.000 km/12 luni**,
    sursă site oficial Jeep UK (citată pe jeepgarage.org) — de data asta consistentă în interiorul
    pieței UK (conflictul găsit anterior era între piața UK și cea Australia/SUA, nu un conflict
    intern UK). Aplicat pe toate cele 6 motoare CRD din catalog (sursa nu diferențiază după
    capacitate).
  6 rânduri noi (toate Jeep CRD), verificate cu test scratch (șters după confirmare) — inclusiv
  confirmarea explicită că Nissan M9R rămâne pe 12.000 km prin fallback.
  **v25 (reverificare BMW, la cerere explicită):** runda anterioară descrisese doar „Condition
  Based Service, variază 10.000-18.000 mile" fără o cifră unică de încredere. Reverificat cu surse
  UK specifice (pistonheads.com, bimmerforums.co.uk, bmwccgbforum.co.uk) — **de data asta două
  surse UK independente converg pe aceeași cifră oficială**: schema de service BMW UK e **18.000
  mile/24 luni** (~29.000 km/24 luni), cifra la care se aprinde de regulă lumina CBS. Mențiuni de
  „10-16k mile" sau „9-10k mile" apărute în aceleași căutări sunt practică independentă a
  mecanicilor/proprietarilor îngrijorați de longevitatea turbinei (schimbări mai dese decât oficial
  recomandat), NU cifra oficială BMW — nu au fost folosite pentru fix. Aplicat pe toate cele 26 de
  motoare diesel BMW din catalog (M47/N47/B47/M57/N57/B57 — schema CBS/18k se aplică generic pe
  toată gama diesel UK, nu doar 320d). 26 de rânduri noi, verificate cu test scratch (șters după
  confirmare).
  **v26 (reverificare VW/Audi/Seat/Skoda TDI CR, la cerere explicită):** rundele anterioare
  descriau doar schema Longlife/Variable (9.000-30.000 mile după configurare), prea largă pentru
  un număr unic de încredere. Reverificat cu surse UK specifice (honestjohn.co.uk, elginvw.com,
  sunset-derby.co.uk, rwcmotorsport.com) — de data asta sursele converg pe schema **Fixed** ca
  fiind cea mai des documentată/„standard": 10.000 mile (~16.000 km, o sursă) / 15.000 km (altă
  sursă, honestjohn.co.uk, citând handbook-ul), 12 luni — suficient de consistente pentru un fix
  (**15.000 km/12 luni**). Schema Variable/Longlife (până la 30.000 km) rămâne opțiunea implicită
  din fabrică pentru mașinile noi din UK, dar Fixed e alegerea recomandată pentru uz redus și e cea
  documentată explicit — aleasă aici ca fiind mai sigură (interval mai scurt), la fel ca la
  celelalte fix-uri din acest catalog. Aplicat pe toate cele **64 de motoare TDI CR** rămase din
  cele 4 branduri VAG (20 Audi + 11 Seat + 11 Skoda + 22 Volkswagen — codurile BKD/CRBC/DTVA/BRE/
  CAGA/DETA/CAHA/CGLC/BMC/DIGB/DFHA/CASA/DCUA/AMF/ASY/CFWA/ASV/CBDB/CLHA/AVF/CFGB/DFGA/ALH/DFSA/
  DGEA/BKC/CUPA/AVB/BMP/CFFB/DEZA/CFHC). 64 de rânduri noi, verificate cu test scratch (șters după
  confirmare).
  **v27 (reverificare Nissan M9R/R9M + Mercedes + Opel + Mazda, la cerere explicită):**
  - **Nissan M9R/R9M — TOT fără regulă**, dar situația e mai clară acum: sursa UK cea mai nouă
    (x-trail-uk.co.uk) dă „12.500 mile/12 luni", dar și „18.000 mile, confirmat de Nissan Customer
    Service pentru anumiți ani de model" — conflict chiar și în interiorul surselor Nissan UK
    proprii, peste conflictul deja cunoscut cu Renault M9R (același motor fizic, 9.000 mile, v23).
    Rămâne pe fallback (12.000 km) — nu există un număr unic de încredere.
  - **Mercedes OM651/OM654** (4 cilindri moderne — NU și OM656 V6/clasă diferită, nici motoarele
    vechi OM613/OM612/OM640/OM642/OM646/OM608) → **24.000 km/12 luni** (sursă: 15.000 mile,
    pistonheads.com/mbclub.co.uk, E220d) — de data asta o cifră unică și consistentă, spre
    deosebire de runda anterioară (Service A ~25.000 km vs. Service B ~40.000 km).
  - **Opel/Vauxhall CDTI** — distincție clară pe mărime/generație: modele mici/vechi (Astra
    Z19DTH/A17DTJ/B16DTH, Corsa Z13DTH/A17DTC, Zafira Z19DTH) → **16.000 km/12 luni** (10.000
    mile); Insignia (A20DTH/B16DTH) → **32.000 km/12 luni** (20.000 mile). DV6FD (Astra/Grandland,
    motor PSA BlueHDi post-Stellantis, cod identic cu cel de la Peugeot/Citroën) → **26.000 km/12
    luni**, extins pentru consistență cu fixul din v21. Motoarele Y-prefix (Y17DT/Y20DTH,
    generația cea mai veche, pre-CDTI) rămân fără sursă.
  - **Mazda Skyactiv-D** (NU și motoarele vechi MZ-CD/MZR-CD) → **20.000 km/12 luni** (12.000-
    12.500 mile, consistent între mai multe citări UK/EU de data asta).
  26 de rânduri noi, verificate cu test scratch (șters după confirmare) — inclusiv confirmarea că
  Nissan M9R rămâne pe fallback.
  **v28 (Nissan, reverificare finală):** am găsit explicația reală a conflictului M9R —
  intervalul X-Trail s-a schimbat la o actualizare de model de la sfârșitul lui 2010 (12.500 mile
  înainte → 18.000 mile după), iar motorul M9R din catalog acoperă exact 2007-2014, traversând acel
  prag — deci nu poate primi un număr unic fără să știm anul exact al mașinii (catalogul nu ține
  evidența anului per vehicul individual, doar intervalul motorului). **Rămâne pe fallback**,
  documentat acum cu motivul precis, nu doar ca „ambiguu". În schimb, **R9M** (Qashqai 1.6 dCi,
  2014+, motorul mai nou care l-a înlocuit pe M9R) are o sursă curată — interval european
  ~30.000 km/12 luni citat explicit — **fix aplicat** (motor id 450, singura intrare R9M din
  catalog, pe X-Trail). Verificat cu test scratch (șters după confirmare) că R9M primește regula
  nouă și M9R rămâne corect pe fallback.
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
- `lib/theme/app_theme.dart` — `buildAppTheme(Brightness)`, folosit din `main.dart` pentru light/
  dark. **Aspect „3D" (umbre elevate, stil Material clasic) cerut explicit de utilizator**:
  `cardTheme` are elevație (4 light/6 dark) + `shadowColor`, fără `side`/border (umbra singură dă
  adâncimea — un contur peste umbră arăta aglomerat). `filledButtonTheme`/`elevatedButtonTheme`
  folosesc `ButtonStyle` cu `elevation: WidgetStateProperty` (`_pressedElevation`, funcție
  top-level din același fișier) — 4 implicit, 6 la hover/focus, **1 la apăsare** (efectul vizual
  de „se lasă în jos" cerut explicit) — nu doar simplul `elevation: 0` fix de dinainte.
  `floatingActionButtonTheme` (butonul „+ mașină" din `garage_screen.dart`) avea `elevation: 1` fix,
  fără nicio stare separată de apăsare — abia se vedea vreo umbră și nu se schimba deloc la
  apăsare; acum `elevation: 6`, `hoverElevation`/`focusElevation: 8`, **`highlightElevation: 2`**
  (mai mică = butonul "se lasă în jos" vizibil la apăsare).
  **Extins la TOATE butoanele, cerut explicit imediat după** ("fă același efect de apăsare pe
  toate butoanele din aplicație"): `OutlinedButton`/`TextButton` NU au `elevation` prin
  constructorii convenabili (`.styleFrom`), dar `ButtonStyle` brut (aceeași bază,
  `ButtonStyleButton`, pe care se construiesc și `FilledButton`/`ElevatedButton`) TOT îl acceptă —
  corectat greșeala inițială (credeam că Flutter nu suportă elevație pe ele deloc). Adăugat
  `_pressedElevationSubtle` (0 la apăsare/2 implicit/3 la hover — mai discretă decât
  `_pressedElevation` a butoanelor primare, ca să respecte ierarhia vizuală Material: text < outlined
  < filled). **Fond adăugat explicit pe amândouă** (`OutlinedButton`: `surfaceContainerLow` opac;
  `TextButton`: același, dar la 50% alpha) — fără el, umbra plutea sub un fundal complet
  transparent, arăta ca o pată desprinsă de text/contur, nu ca un buton "3D".
  **`IconButton` NU a primit acest tratament** — decizie conștientă, nu omisă din neatenție: multe
  din cele 14 apariții din cod sunt butoane compacte 28×28 (`visualDensity: compact`,
  `padding: zero`), adesea 2-3 la rând (ex. `document_tile.dart`) — o umbră pe fiecare, la o
  mărime atât de mică, risca să arate ca o pată neclară în loc de relief, mai ales înghesuite unul
  lângă altul. Dacă se cere explicit și pentru acestea, testează vizual pe un singur ecran înainte
  de a aplica global prin `iconButtonTheme` (nu există în temă momentan).
  **Efect de apăsare cerut explicit, imediat după, pe elemente pe care doar elevația nu era
  suficient de vizibilă** (cardul mașinii, „+ mașină", „Scanare talon", „Cameră"/„Galerie"):
  adăugat `lib/widgets/pressable.dart` (`Pressable`, widget generic) — folosește `Listener`
  (evenimente brute de pointer), NU `GestureDetector`, tocmai ca să NU intre în conflict cu
  `onTap`/`InkWell`-ul propriu al widget-ului înfășurat (`Listener` nu participă la arena de
  gesturi) — poate fi pus în jurul oricărui buton/card/ListTile existent, fără să-i schimbe deloc
  comportamentul de tap. Micșorează vizibil (scale 0.94) la apăsare, revine la ridicare — același
  mecanism ca `AppBottomNavBar`, extras într-un widget reutilizabil. Aplicat pe: `VehicleCard`
  (+ culoare distinctă, `kAccentColor` la alpha redus — utilizatorul raportase că nu observa
  deloc efectul 3D pe fondul neutru anterior), toate cele 3 `FloatingActionButton` din aplicație
  (garage + cele 2 din `vehicle_detail_screen.dart`), butonul „Scanare talon"
  (`add_edit_vehicle_screen.dart`), opțiunile „Cameră"/„Galerie" din bottom sheet-ul aceluiași
  ecran, și `_AttachButton` din `photo_picker_field.dart` (Cameră/Galerie/PDF — folosit din toate
  ecranele care atașează o poză: mașină, documente, revizii). Nu s-a atins `IconButton`-urile mici
  (motivul de mai sus rămâne valabil — `Pressable` ar funcționa tehnic și pe ele, dar riscul
  vizual în rânduri înghesuite nu s-a schimbat).
  **Butonul „Adaugă asigurare locuință" din `house_screen.dart` mutat ca FAB fix jos** (cerut
  explicit) — era un `OutlinedButton.icon` inline, la finalul listei de documente, care scrolla cu
  conținutul (deci dispărea din ecran dacă existau destule documente). Mutat în
  `floatingActionButton` al `Scaffold`-ului, `Pressable`-wrapped ca restul FAB-urilor, `heroTag:
  'houseFab'` (unic — `main_shell.dart` ține toate tab-urile montate simultan într-un
  `IndexedStack`, deci FAB-urile de pe ecrane diferite pot coexista în arbore în același timp;
  fiecare are deja propriul `heroTag` unic, la fel ca `garageFab`/`serviceRecordFab`/
  `vehicleDocumentsFab`).
  **„Mai user friendly", cerut explicit imediat după:** eticheta lungă a FAB-ului
  („Adaugă asigurare, impozit, verificări sau alt document") era greu de citit înghesuită
  într-un buton plutitor. Scurtată la `S.addHomeDocumentShort` („Document nou"), iar textul lung
  s-a mutat pe un mesaj de ecran gol nou (`S.houseEmptyState`) — înainte, cu zero documente,
  ecranul nu arăta ABSOLUT NIMIC în afară de FAB (spre deosebire de toate celelalte ecrane goale
  din aplicație — `noCarsYet`, `noHouseWarnings`... — care au mereu un mesaj explicativ). FAB-ul
  are acum și `backgroundColor: kNavHouseColor` (verde, aceeași culoare cu tabul Casă din bara de
  jos) în loc de `colorScheme.primary` implicit — consistență vizuală cu restul paletei colorate
  cerute mai devreme pentru navigare.
  **Bara de navigare de jos NU mai e `NavigationBar`-ul din Material** (era înainte, cu elevație
  prin `navigationBarTheme`) — testat pe device real, umbra dată de elevația temei nu se vedea
  vizibil, iar `NavigationDestination` n-are nicio stare de apăsare separată (doar ripple).
  Înlocuită cu `AppBottomNavBar` (`lib/widgets/app_bottom_nav_bar.dart`, widget propriu): umbră
  desenată explicit (`BoxShadow`, garantat vizibilă, nu depinde de randarea internă a lui
  Material) + efect de apăsare implementat manual (`GestureDetector.onTapDown/onTapUp` +
  `AnimatedScale`, se micșorează vizibil la apăsare). Folosită identic în `main_shell.dart` (5
  taburi) și `vehicle_detail_screen.dart` (4 taburi per mașină) — `navigationBarTheme` a fost
  eliminat din `app_theme.dart` ca fiind acum complet nefolosit (nicio referință la
  `NavigationBar`/`NavigationDestination` din Material mai rămâne în cod).
  **Mărime dublă + colorat, cerut explicit imediat după prima variantă** (care era neutră,
  `onSurface`/`onSurfaceVariant`, înălțime 68/iconițe 24/etichetă 12): `AppBottomNavBar` are acum
  `_barHeight = 136`, `_iconSize = 48`, `_labelFontSize = 15` (dublate față de valorile inițiale —
  eticheta nu literal dublată la 24, ar fi ieșit disproporționat sub o iconiță de 48, dar tot
  vizibil mai mare ca înainte). `AppNavDestination` are acum un câmp `color` OBLIGATORIU (nu mai e
  opțional cu fallback neutru) — fiecare tab din `main_shell.dart`/`vehicle_detail_screen.dart`
  primește propria culoare din paleta nouă din `app_theme.dart`
  (`kNavGarageColor`/`kNavHouseColor`/`kNavCostsColor`/`kNavSettingsColor` pentru taburile
  principale, `kNavServiceColor`/`kNavDocumentsColor`/`kNavComponentsColor` pentru taburile per
  mașină — Info de pe ambele reia `kAccentColor`, identitatea vizuală a aplicației). Tabul
  neselectat păstrează culoarea proprie, doar estompată (`withValues(alpha: 0.55)`) — nu redevine
  gri neutru, tot „colorat", doar mai discret decât cel activ. Cardurile
  reale din UI care foloseau `ListTile` gol, direct în listă, fără `Card` în jur, au fost
  înfășurate explicit ca să beneficieze de tema nouă: `DocumentTile` (widget separat, folosit din
  4 ecrane — house/garage/vehicle_detail/home), plus alertele și reminder-urile personale din
  `home_screen.dart`. `VehicleCard` era deja pe `Card`, a beneficiat automat doar din tema nouă.
  **Nu extins** la alte `ListTile`-uri din aplicație (tracker-ul de componente din
  `vehicle_detail_screen.dart`, rândurile din formulare, calendarul de costuri, Setări) — cererea
  utilizatorului a fost specific despre mașini/documente/atenționări/taburi, nu despre tot ce
  arată ca o listă.
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
  găsește nimic, la fel ca la orice alt câmp. Extrage și anul (câmpul B, data primei
  înmatriculări — cel mai apropiat proxy pentru anul de fabricație, talonul RO nu are un câmp
  dedicat separat) și puterea (câmpul P.2, **mereu în kW** — convertită în CP prin `kw * 1,35962`
  și rotunjită; folosită la filtrarea listei de motoare candidate din dialogul de decodare VIN,
  vezi `_scannedPowerCp`/`pdfScansData` în `add_edit_vehicle_screen.dart`).
  **Bug real găsit pe o poză reală de talon (Hyundai Tucson, trimisă de utilizator) — reconstrucție
  geometrică a rândurilor, nu doar text brut:** talonul RO e un layout pe două coloane (etichetă
  îngustă în stânga: A/J/D.1/D.2/D.3/E/K..., valoare mai lată în dreapta: IS-49-KRP/AUTOTURISM M1/
  HYUNDAI/TLE F5D14/TUCSON/VIN...). ML Kit grupează des cele două coloane în blocuri de text
  SEPARATE, deci `RecognizedText.text` (stringul brut, concatenat block cu block) înșiruia toate
  etichetele, apoi toate valorile — nu alternativ, rând cu rând. Orice extracție ancorată pe
  "eticheta e pe aceeași linie sau pe linia următoare" (D.3 pentru model, B pentru an, P.2 pentru
  putere) nimerea complet greșit: D.3 ajungea urmat de "E" (eticheta VIN-ului, tot din blocul de
  etichete) în loc de valoarea reală "TUCSON". Fix: `reconstructRowsByPosition` (funcție top-level,
  testabilă separat de OCR real prin tipul `PositionedTextLine` — un record simplu
  `{text, top, left, height}`) ia toate liniile din toate blocurile ML Kit, le grupează pe rânduri
  vizuale după suprapunerea centrului vertical (toleranță = un sfert din înălțimea combinată a
  celor două linii comparate), apoi sortează fiecare rând stânga→dreapta — reface efectiv ordinea
  de citire corectă indiferent cum a grupat ML Kit blocurile. `scanTalon` rulează asta ÎNAINTE de
  `parseTalonText` (care rămâne neschimbată — tot restul logicii de extracție presupune deja
  "etichetă + valoare pe același rând reconstruit", exact ce oferă acum reconstrucția). Aplicat
  DOAR la `scanTalon` (talon), nu și la `scanRcaPdf` (RCA e text de tip paragraf, nu tabel
  etichetă/valoare pe două coloane — riscul de amestecare a coloanelor e mult mai mic acolo, nu
  s-a cerut și nu a fost testat). Teste de regresie cu date geometrice simulate (bounding box-uri
  derivate din poza reală) în `test/document_scanner_service_test.dart`, grupul
  `reconstructRowsByPosition (real two-column talon layout)`.
  **Bug real raportat pe o poză reală de talon (Ford Fiesta cu anexă, trimisă de utilizator):
  marca (D.1) nu se completa deloc**, deși extracția de marcă folosea o scanare oarbă a întregii
  pagini după un nume din `_knownMakes` (nu ancorată de eticheta D.1, spre deosebire de model/D.3,
  VIN/E, an/B, putere/P.2 — toate ancorate explicit de mult, exact din cauza acestui gen de bug).
  Cauza exactă n-a putut fi reprodusă 1:1 (fără print de debug de pe device ca la Hyundai/Ford
  Focus de mai sus), dar scanarea oarbă e vulnerabilă la exact aceleași clase de bug deja
  documentate aici: rând grupat greșit prin `reconstructRowsByPosition`, sau etichetă+valoare
  citite de OCR fără spațiu între ele ("D.1FORD"). Fix: adăugată o ancoră explicită pe eticheta
  D.1 (`_makeFieldCode`, la fel ca `_modelFieldCode`), încercată ÎNTÂI — ia valoarea de pe același
  rând sau de pe rândul următor și o verifică față de `_knownMakes`; scanarea oarbă rămâne ca
  fallback dacă ancora nu găsește nimic (talon fără etichetă D.1 recognoscibilă, sau valoare
  negăsită în listă). Teste de regresie (geometrie aproximativă, nu exactă — vezi comentariul din
  cod) în `test/document_scanner_service_test.dart`, grupul `D.1 (make) extraction — real Ford
  Fiesta talon`, plus un test adăugat retroactiv pentru marca (Hyundai) pe geometria reală deja
  existentă de la bug-ul anterior (grupul Hyundai Tucson), care nu verifica deloc `result.make`
  până acum.
  **Bug real găsit imediat după, pe iOS — prima diferență confirmată între ML Kit
  Android vs. iOS pe acest proiect:** utilizatorul a raportat că VIN-ul (câmpul E) nu se completa
  pe iPhone, deși pe Android (aceeași poză, Ford Focus-CNG cu anexă, deja folosită ca test la
  bug-urile de mai sus) funcționa corect. Diagnosticat cu un print de debug TEMPORAR în
  `scanTalon` (eliminat după — geometria capturată a rămas ca test permanent), rulat live pe un
  iPhone conectat prin USB (`flutter run --debug -d <device-id>`; conexiunea WIRELESS a eșuat
  repetat cu „Dart VM Service was not discovered” — pentru debug live cu print-uri pe iOS,
  preferă USB, wireless funcționează OK doar pentru `flutter install`/build simplu, nu pentru
  atașarea VM-ului). Cauza: modelul ML Kit de pe iOS a citit eticheta câmpului **F.1 ca „E1”**
  (confuzie F↔E, specifică modelului iOS — pe Android aceeași poză citea corect „F1”/„F.1”).
  Vechiul regex al etichetei VIN (`_vinFieldCode = RegExp(r'^E(?![A-Za-z])')`) exclude explicit
  doar o LITERĂ după „E”, deci accepta orice altceva, inclusiv o cifră — „E1 1825” se potrivea la
  fel de bine ca eticheta reală „E”, bucla de căutare (care se oprește necondiționat la primul
  rând găsit, ca la toate celelalte câmpuri ancorate din acest fișier) se bloca acolo și nu mai
  ajungea niciodată la rândul real „E WFOKXXGCBKDJ42375”, mult mai jos pe pagină. Fix: regex
  restrâns la o listă explicită de separatori acceptați după „E” (spațiu/`)`/`:`/`.`/`-`/capăt de
  linie) — exclude implicit orice cifră, la fel ca o literă. Test de regresie cu geometria EXACTĂ
  capturată de pe iPhone în `test/document_scanner_service_test.dart`, grupul „reconstructRowsBy
  Position (three-column talon with anexă)”, testul „reproduces the real iOS Ford Focus scan”.
  **Îmbunătățire cerută explicit imediat după (fără reproducere 1:1 cu date reale — vezi mai
  jos):** utilizatorul a cerut ca data ITP extrasă să fie mereu cea mai recentă din caseta de
  ștampile succesive a anexei (ex. 3 inspecții: 05.12.2023/CL494683, 29.11.2024/CR677728,
  10.12.2026/CY787274), nu prima găsită. Design-ul deja documentat mai sus la [_itpKeyword]
  spunea că trebuie luată „cea mai târzie dată”, dar implementarea avea două limitări reale: (1)
  fereastra de căutare pornea DOAR de la prima apariție a cuvântului-cheie și se întindea DOAR
  înainte (300 de caractere), niciodată înapoi — o ștampilă mai recentă putea ajunge, prin
  reordonarea pe rânduri a `reconstructRowsByPosition`, înaintea cuvântului-cheie în textul
  reconstruit și rămânea complet neluată în calcul; (2) fereastra se calcula o singură dată, de la
  prima apariție — dacă alte câmpuri ale paginii se intercalau între ștampile în textul
  reconstruit, o ștampilă mai îndepărtată ieșea din raza de 300 de caractere. Fix: acum se
  folosesc TOATE aparițiile cuvântului-cheie din pagină (`_itpKeyword.allMatches`, nu doar
  `firstMatch`), fiecare cu o fereastră ±500 de caractere (înainte ȘI după), iar toate datele
  găsite în oricare din aceste ferestre sunt puse laolaltă înainte de a alege maximul. **Nu s-a
  putut confirma 1:1 cu geometrie reală capturată pe device** — poza de test disponibilă în
  sesiunea de debug (talon Ford Fiesta, IS-23-DUK) nu a acoperit caseta cu cele 3 ștampile (doar
  primul rând, 05.12.2023, plus un artefact separat: textul OCR conținea și „Retake”/„Use Photo”,
  butoanele ecranului de confirmare foto — **rezolvat, nu era bug de cod**: utilizatorul a
  confirmat că a ales „Galerie” și a selectat un screenshot vechi — pe care mi-l trimisese chiar
  mie, în chat, ca dovadă — în loc să facă o poză nouă cu „Cameră”; `image_picker` funcționează
  corect când fluxul e folosit cum trebuie).
  Teste de regresie cu text SINTETIC (nu geometrie reală) în `test/document_scanner_service_test.dart`:
  „picks the latest ITP stamp even when other reconstructed rows push it past the old 300-char
  window” și „picks up an ITP stamp that ends up reconstructed before the keyword occurrence”.
  **Fallback best-effort pentru ștampile ITP scrise de mână, cerut explicit de utilizator (imediat
  după, cu riscul asumat de fals-pozitive):** cu o poză curată (nu screenshot) a aceluiași talon
  Ford Fiesta, VIN-ul s-a extras corect, dar ITP-ul tot nu — de data asta cauza a fost alta:
  captura de debug pe geometria reală a arătat că cele 2 ștampile scrise de mână (29.11.2024,
  10.12.2026) ies din OCR ca fragmente numerice IZOLATE, fără punctuație care să le lege
  (`_datePattern` cere explicit un singur token „zi.lună.an”) — și, mai grav, luna („11”) lipsea
  complet din text pe acea poză, înghițită de o mâzgălitură nedescifrabilă de pe același rând cu
  cifra zilei ("29 S2 cLA94683" → ziua 29 amestecată cu restul ștampilei). Adăugat
  `_looseHandwrittenDates`: caută, în apropierea (±20 rânduri) fiecărei apariții a
  cuvântului-cheie ITP, cele mai apropiate 3 linii STRICT numerice (fără alt caracter — o
  mâzgălitură pe același rând cu o cifră o exclude automat) și încearcă să le combine într-o dată
  zi/lună/an (an de 2 cifre interpretat ca 20xx), validând componentele (zi 1-31, lună 1-12, an în
  ±5/+15 ani față de anul curent) ca să nu inventeze o dată absurdă dintr-o coincidență de cifre.
  **Confirmat explicit că NU rezolvă exemplul real** (luna lipsește complet din text pe acea poză
  — fallback-ul nu poate reconstitui date care n-au fost niciodată recunoscute de OCR), dar poate
  ajuta pe scanări mai curate/ștampile mai lizibile decât acel exemplu — utilizatorul a ales
  explicit să încerce euristica știind asta, în locul variantei mai sigure (fallback manual, fără
  nicio încercare automată). Teste de regresie (text sintetic, inclusiv cazul „curat” care
  funcționează ȘI reproducerea exactă a cazului real unde nu funcționează) în
  `test/document_scanner_service_test.dart`.
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
  **`getEngineForCode` mai încearcă și o potrivire pe `denumire_comerciala`** (ex. "420d") dacă
  `cod_motor_key` nu a găsit nimic ȘI `make` e completat (bug real raportat de utilizator: BMW
  420d nu primea intervalul specific — cauza era că userul completase câmpul „Cod motor” cu
  denumirea comercială „420d”, nu cu codul intern real N47D20/B47D20, iar `getEngineForCode`
  potrivea STRICT pe `cod_motor_key`; catalogul în sine avea deja regula specifică BMW diesel din
  v25, 29000 km/24 luni, verificat corect pe toate cele 26 de motoare diesel — problema era doar
  în lookup, nu în date). Restrâns obligatoriu la `make` (nu doar `model`, care lipsește des din
  acest flux) ca să evite coliziuni cu denumiri comerciale generice de la alte mărci (ex. cifre de
  capacitate/putere repetate pe mai multe mărci) — la fel ca precedentul deja existent din
  `getCandidateEnginesForVin` (potrivire pe `denumire_comerciala` pentru câmpul model, de la
  fix-ul „Completare motorizare!”/BMW 420d anterior). Dacă nu are rânduri nici așa,
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
    termină în `.pdf`. La atașare pe un document de tip `rca`,
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
    rând). **Doar RCA, nu și CASCO** — utilizatorul a observat corect că scanarea „nu e
    implementată" pentru CASCO: codul (`scanRcaPdf`/`parseRcaText`) tehnic rulează pentru orice
    `_isPolicyType`, dar regexurile au fost reglate/testate DOAR pe polițe RCA reale (formatul
    A.S.F. standardizat de mai sus e specific RCA-ului; CASCO variază mult mai mult între
    asigurători și n-a fost testat pe niciun document real) — deci în practică nu extrăgea nimic
    util pentru CASCO. Fix: `add_edit_document_screen.dart` are acum un getter separat
    `_pdfScansData` (doar `DocumentType.rca`), distinct de `_isPolicyType` (rca + casco, folosit
    doar pentru eticheta generică „Poză sau PDF" — atașarea simplă a PDF-ului rămâne disponibilă la
    CASCO, doar extragerea automată nu). `PhotoPickerField` primește acest flag ca
    `pdfScansData` — controlează dacă butonul PDF apare ca „Scanează date din PDF" (roșu, sare în
    ochi) sau ca simplu „Atașează PDF" (stil normal) pentru orice alt tip de document (CASCO
    inclus). Dacă se cere vreodată extinderea scanării reale la CASCO, trebuie reglată/testată
    separat pe o poliță CASCO reală, la fel cum s-a procedat pentru RCA — nu presupune că
    regexurile RCA se potrivesc. Best-effort ca la codul de motor din VIN: nu blochează niciodată
    atașarea PDF-ului dacă
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
15. Secțiune „Feedback” + „Trimite jurnal erori” + „Politica de confidențialitate” în Setări,
    pregătite pentru testare externă (prieteni/Play Store closed testing). Secțiunea „Contact”
    (placeholder „în curând”) a fost eliminată — redundantă cu Feedback-ul funcțional. Textul
    politicii e disponibil în două locuri sincronizate manual: `PRIVACY_POLICY.md` (pentru URL-ul
    public cerut de Play Console) și `S.privacyPolicyBody` din `lib/l10n/strings.dart` (afișat
    direct în aplicație, din `lib/screens/privacy_policy_screen.dart`, deschis din Setări) — dacă
    actualizezi unul, actualizează-l și pe celălalt. Feedback-ul deschide un `mailto:`
    (`url_launcher`) către `crdo0809@gmail.com` (adresa dezvoltatorului pentru testare externă —
    diferită de adresa personală din restul proiectului), cu subiect predefinit — nu există niciun
    formular/backend propriu.
    Monitorizarea erorilor a fost cerută inițial ca Firebase Crashlytics, dar **respinsă explicit
    de utilizator** fiindcă încalcă principiul „fără backend/cloud” de mai sus (Crashlytics
    trimite stack trace-uri și date de device către serverele Google) — soluția aleasă e
    `lib/services/error_log_service.dart`: un jurnal text 100% local (ultimele 100 intrări,
    rotativ), populat din `FlutterError.onError` + `PlatformDispatcher.instance.onError` +
    `runZonedGuarded` în `main.dart`. Nu se trimite NICIODATĂ automat — doar dacă utilizatorul
    apasă explicit „Trimite jurnal erori”, caz în care fișierul e oferit prin share sheet-ul
    nativ (`share_plus`), la fel ca orice alt fișier din aplicație (nu prin `url_launcher`/mailto,
    ca la feedback, fiindcă un jurnal poate depăși lungimea practică a unui body de `mailto:`).
    **Dacă se cere vreodată integrarea unui serviciu extern de crash reporting pe viitor, tratează
    asta ca pe o schimbare de arhitectură care necesită reconfirmare explicită**, nu doar o
    adăugare de dependință — decizia „fără cloud” a fost reafirmată conștient aici, nu omisă din
    neatenție.
16. Backup manual (export/import) — `lib/services/backup_service.dart`, secțiune „Backup” în
    Setări. Cerut explicit de utilizator: ștergerea aplicației șterge automat containerul ei de
    date pe iOS/Android (fără cloud, nu există „păstrare automată” — vezi principiul „fără
    backend/cloud” de mai sus, reafirmat aici la fel ca la punctul 15/Crashlytics). „Exportă
    backup” scrie un fișier JSON (nu o copie brută a `.db` — evită o dependință nouă de zip, vezi
    mai jos) cu toate rândurile din tabelele de date ale utilizatorului (`vehicles`,
    `service_records`, `car_documents`, `reminders`, `component_records`,
    `vehicle_extra_components` — NU tabelele de catalog static, regenerate oricum la fiecare bump
    de versiune DB) + pozele/PDF-urile atașate (`photoPath`) encodate base64 direct în același
    fișier, apoi îl oferă prin share sheet-ul nativ (`share_plus`, la fel ca jurnalul de erori de
    la punctul 15) — utilizatorul alege unde-l salvează (Files/iCloud Drive/email/AirDrop etc.).
    „Importă backup” (`file_picker`) cere confirmare explicită (dialog roșu, acțiune ireversibilă)
    apoi ȘTERGE toate datele curente și le înlocuiește cu cele din fișier — nu există merge,
    fiindcă scenariul țintă e reinstalare pe aplicație goală, nu combinare cu date existente.
    `photoPath`-urile absolute din backup (care indică spre directorul Documents al INSTALĂRII
    VECHI, cu alt path) sunt rescrise spre noul director Documents după restaurarea fișierelor
    acolo cu același nume; dacă un fișier referit lipsește din backup (nu exista pe disc la
    momentul exportului), `photoPath`-ul e setat `null` la import, NU lăsat cu path-ul vechi
    invalid — consistent cu restul aplicației, care tratează deja `photoPath == null` ca „fără
    poză”. Logica de (de)serializare (`exportBackupJson`/`importBackupJson`) e separată de accesul
    la `path_provider` (`exportBackup`/`importBackup`), la fel ca separarea
    `parseTalonText`/`scanTalon` din `document_scanner_service.dart` — testabilă direct, cu un
    `Directory` temporar oarecare (`test/backup_service_test.dart`, sqflite FFI, același pattern ca
    `test/ford_fiesta_test.dart`), fără să depindă de path_provider real.
    **Reminder de backup, cerut explicit imediat după („reamintește la ștergerea aplicației”):**
    **tehnic imposibil ca atare** — nici Android, nici iOS nu oferă unei aplicații obișnuite (fără
    entitlements speciale) niciun hook care s-o anunțe ÎNAINTE de a fi dezinstalată. Implementat
    cel mai apropiat echivalent practic: `NotificationService.scheduleBackupReminder()`, un
    reminder local recurent (o dată pe lună, ziua 1 la ora 10, `matchDateTimeComponents:
    dayOfMonthAndTime` — exact același mecanism ca `scheduleMileageReminder`) care încurajează un
    export periodic, ca să nu treacă mult timp de la ultimul backup dacă utilizatorul chiar șterge
    aplicația între timp. Id fix (`_idFor('backup_reminder', 0)`, cheie de string constantă, nu
    per-mașină/document — pattern deja existent pentru remindere generice). Programat/anulat din
    `HomeScreen._load`, condiționat de `vehicles.isNotEmpty` (fără sens pe o aplicație goală, abia
    instalată). De asemenea, ecranul de scanare talon (`add_edit_vehicle_screen.dart`,
    `_scanTalon`) anunță acum explicit (SnackBar) dacă OCR-ul NU găsește o dată ITP pe poză, în
    loc să lase tăcut câmpul necompletat. **Prima variantă** (dialog cu `showDatePicker` inline,
    imediat după scanare) a fost înlocuită la cererea explicită a utilizatorului cu acest simplu
    anunț — preferă să salveze întâi datele mașinii, apoi să adauge ITP-ul separat din ecranul de
    documente, nu vrea fluxul de salvare a mașinii întrerupt de un date picker în plus.

## Roadmap — NU implementat, doar documentat (nu construi fără cerere explicită)

- Interogare **complet automată** RAR/AIDA/CNAIR (fără interacțiune din partea utilizatorului) —
  imposibilă fără un API plătit de la un broker care rezolvă el CAPTCHA pe partea lui; vezi nota
  despre `document_verification_utils.dart` de mai sus pentru ce există în schimb.
- Cumpărare RCA/Rovinietă in-app via broker + Apple/Google Pay (premium). **Atenție**: a existat o
  încercare anterioară de a pregăti terenul adăugând doar permisiunea
  `com.android.vending.BILLING` în `AndroidManifest.xml`, fără nicio integrare reală de billing —
  Play Console a respins upload-ul cerând migrarea la Play Billing Library 6.0.1+ (permisiunea
  singură e semnalul vechi de API AIDL de billing, pe care Google îl detectează static). Permisiunea
  a fost eliminată. **Nu re-adăuga doar permisiunea „de rezervă”** la o viitoare cerere de
  monetizare — implementează efectiv `in_app_purchase` (sau echivalent) în același pas, altfel
  blochezi din nou orice upload către Play Store.
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
  cod): `adb -s <device> exec-out run-as com.autocalendar cat databases/car_planner.db >
  local.db`, apoi interoghează cu `sqlite3` local (disponibil la `C:\platform-tools\sqlite3` pe
  mașina asta). Funcționează fiindcă build-ul debug e `run-as`-abil implicit. Șterge fișierul local
  după — poate conține date personale ale userului (plăcuțe, VIN etc. din mașinile lui reale, nu
  doar din cele de test).

## Pregătire build Google Play Store

- **Application ID**: `com.autocalendar` (namespace + applicationId în `android/app/build.gradle.kts`,
  pachetul Kotlin la `android/app/src/main/kotlin/com/autocalendar/MainActivity.kt`) — schimbat de
  la `com.dodea.car_planner` (id-ul original de dezvoltare) fiindcă fișa aplicației fusese deja
  creată în Play Console cu `com.autocalendar` rezervat; consola respinge orice upload cu alt
  package name. **Application ID-ul e imutabil odată ce primul upload reușește** — nu-l mai
  schimba fără să confirmi explicit, ar însemna o aplicație nouă din perspectiva Play Store (pierzi
  istoricul, recenziile, orice utilizatori existenți).
- **Semnare release**: `android/upload-keystore.jks` (cheie de upload, RSA 2048, valabilă 10000
  zile/~27 ani) generat local cu `keytool`, alias `upload`. Parolele sunt în
  `android/key.properties` (NU în git — `.gitignore` deja exclude `key.properties`, `*.jks`,
  `*.keystore`; există `android/key.properties.example` ca șablon fără parole reale, pentru
  portare pe altă mașină). `android/app/build.gradle.kts` citește `key.properties` la build time
  și cade automat pe semnarea cu cheia de debug dacă fișierul lipsește (ca `flutter run --release`
  să meargă și fără keystore configurat, ex. pe o mașină nouă de dezvoltare).
  **Acest keystore trebuie păstrat cu grijă și făcut backup manual (Drive/USB) — dacă se pierde,
  nu se mai pot publica actualizări pentru aceeași aplicație pe Play Store sub aceeași identitate.**
  Nu regenera keystore-ul „ca să repari o problemă" fără să confirmi explicit cu utilizatorul — e
  ireversibil odată ce aplicația a fost publicată prima dată cu cheia curentă.
- **Format upload**: Play Console cere `.aab` (App Bundle), nu `.apk` — `flutter build appbundle
  --release`, output la `build/app/outputs/bundle/release/app-release.aab`. `isMinifyEnabled` +
  `isShrinkResources` active pe `release` (R8/ProGuard, vezi `proguard-rules.pro` pentru regulile
  specifice ML Kit).
  Avertismentul „Release app bundle failed to strip debug symbols from native libraries" la build
  e cunoscut și non-blocant pe acest toolchain Windows (lipsă `strip` din NDK în path) — bundle-ul
  rezultat e valid pentru upload, doar puțin mai mare; nu e o eroare de semnare sau de build.
- **Politica de confidențialitate** pentru formularul Play Console: `PRIVACY_POLICY.md` din root —
  necesită un URL public (repo-ul trebuie să fie public, sau găzduit separat, ex. GitHub Pages);
  vezi și ecranul in-app din `lib/screens/privacy_policy_screen.dart` (text sincronizat manual, nu
  generat din același fișier — vezi punctul 15 din „Funcționalități implementate").
- Versiune curentă: `1.0.0+6` (`pubspec.yaml`) — Play Console respinge un upload cu același
  `versionCode` (partea de după `+`) ca unul existent. **Regulă cerută explicit de utilizator:
  incrementează `versionCode`-ul înainte de ORICE build** (`flutter build apk`/`appbundle`, inclusiv
  build-uri locale de test instalate pe telefon, nu doar upload-urile reale către Play Console) —
  nu doar la trimiterea pe un track. `versionName`-ul (partea `1.0.0` de dinainte de `+`) rămâne
  neschimbat până la o schimbare de funcționalitate suficient de mare cât să merite un bump semantic.

## Convenții

- Fără `flutter_localizations`/codegen ARB — orice string nou de UI merge în `lib/l10n/strings.dart`.
- Fără comentarii inutile în cod — doar acolo unde motivul din spate nu e evident din cod.
- Nu adăuga funcționalități din roadmap fără cerere explicită a utilizatorului.
