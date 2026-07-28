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
  (versiune curentă: 28 — v2 a adăugat tabela `component_records`, v3 a adăugat coloana
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
  neschimbată pe tot parcursul, mai puțin faptul că `modele.generatie` e NULL peste tot din v15).
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

## Pregătire build Google Play Store

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
- Versiune curentă: `1.0.0+1` (`pubspec.yaml`) — potrivită ca prim upload; incrementează
  `versionCode`-ul (partea de după `+`) la fiecare build nou trimis pe orice track (inclusiv
  closed testing), Play Console respinge un upload cu același `versionCode` ca unul existent.

## Convenții

- Fără `flutter_localizations`/codegen ARB — orice string nou de UI merge în `lib/l10n/strings.dart`.
- Fără comentarii inutile în cod — doar acolo unde motivul din spate nu e evident din cod.
- Nu adăuga funcționalități din roadmap fără cerere explicită a utilizatorului.
