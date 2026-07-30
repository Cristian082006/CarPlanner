import 'package:flutter_test/flutter_test.dart';
import 'package:car_planner/services/document_scanner_service.dart';

void main() {
  final scanner = DocumentScannerService.instance;

  test('extracts VIN, plate, make and model from a typical talon layout', () {
    const sampleText = '''
CERTIFICAT DE INMATRICULARE
A) B123ABC
D.1) DACIA
D.3) LOGAN MCV
E) WV1ZZZ7HZ8H123456
''';

    final result = scanner.parseTalonText(sampleText);

    expect(result.plateNumber, 'B123ABC');
    expect(result.vin, 'WV1ZZZ7HZ8H123456');
    expect(result.make, 'Dacia');
    expect(result.model, 'LOGAN MCV');
  });

  test('falls back gracefully when no recognizable fields are present', () {
    final result = scanner.parseTalonText('random unrelated text with no vehicle data');

    expect(result.plateNumber, isNull);
    expect(result.vin, isNull);
    expect(result.make, isNull);
    expect(result.model, isNull);
    expect(result.year, isNull);
    expect(result.powerCp, isNull);
    expect(result.fieldsFound, 0);
  });

  test('extracts year from the B) field (first registration date) on the same line', () {
    final result = scanner.parseTalonText('''
CERTIFICAT DE INMATRICULARE
B) 15.03.2016
D.1) FORD
D.3) FOCUS
''');

    expect(result.year, 2016);
  });

  test('extracts year from the B) field when the date is on the line below', () {
    final result = scanner.parseTalonText('''
CERTIFICAT DE INMATRICULARE
B)
15/03/2016
D.1) FORD
''');

    expect(result.year, 2016);
  });

  test('ignores an out-of-range year from a malformed B) field', () {
    final result = scanner.parseTalonText('B) 15.03.1899');

    expect(result.year, isNull);
  });

  test('extracts power from P.2 and converts kW to CP, rounded', () {
    final result = scanner.parseTalonText('''
P.1) 1596
P.2) 88
P.3) Benzina
''');

    // 88 kW * 1.35962 ≈ 119.65 → 120 CP.
    expect(result.powerCp, 120);
  });

  test('P.2 is always treated as kW, even with a trailing parenthesized figure (e.g. rpm)', () {
    final result = scanner.parseTalonText('P.2) 88 (6300)');

    // The 88 is the kW figure; whatever is in parentheses (rpm on the real
    // EU-harmonized field) is ignored, never read as a CP value directly.
    expect(result.powerCp, 120);
  });

  test('extracts power from P.2 when the value is on the line below', () {
    final result = scanner.parseTalonText('''
P.2)
88
''');

    expect(result.powerCp, 120);
  });

  test('extracts ITP expiry date from the control tehnic stamp box, keyword "ITP"', () {
    final result = scanner.parseTalonText('''
CERTIFICAT DE INMATRICULARE
CONTROL TEHNIC ITP
10.05.2024
VALABIL PANA LA 10.05.2026
D.1) DACIA
''');

    expect(result.itpExpiryDate, DateTime(2026, 5, 10));
  });

  test('picks the latest date near the keyword when multiple ITP stamps are present', () {
    final result = scanner.parseTalonText('''
Inspectie tehnica periodica
12.01.2020
15.02.2022
20.03.2024
''');

    expect(result.itpExpiryDate, DateTime(2024, 3, 20));
  });

  test('does not confuse a distant date with the ITP expiry (outside the keyword window)', () {
    final result = scanner.parseTalonText('B) 15.03.2016');

    expect(result.itpExpiryDate, isNull);
  });

  test('recognizes the real label "Inspectii tehnice periodice" (plural, not "tehnica")', () {
    // Regresie: talonul real al utilizatorului are eticheta la plural
    // feminin ("tehnice"), nu la singular ("tehnică"/"tehnica") — varianta
    // inițială a regex-ului cerea explicit terminația de singular și nu se
    // potrivea niciodată pe acest text real.
    final result = scanner.parseTalonText('''
Inspectii tehnice periodice
10.05.2026
''');

    expect(result.itpExpiryDate, DateTime(2026, 5, 10));
  });

  test('itpExpiryDate counts towards fieldsFound', () {
    final result = scanner.parseTalonText('control tehnic 10.05.2026');

    expect(result.itpExpiryDate, DateTime(2026, 5, 10));
    expect(result.fieldsFound, 1);
  });

  group('reconstructRowsByPosition (real two-column talon layout)', () {
    // Reprodus pe o poză reală de talon (Hyundai Tucson) trimisă de
    // utilizator: ML Kit a grupat coloana îngustă de etichete (A, D.1, D.2,
    // D.3, E...) într-un bloc separat de coloana mai lată de valori
    // (HYUNDAI, TLE F5D14, TUCSON...) — flatten-ul naiv al blocurilor
    // înșiruia toate etichetele, apoi toate valorile, deci D.3 ajungea
    // urmat de "E" (eticheta următoare), nu de valoarea reală "TUCSON".
    const scrambledColumns = <PositionedTextLine>[
      // Blocul 1 (coloana de etichete) — vine primul în array, ca la ML Kit.
      (text: 'D.1', top: 100.0, left: 20.0, width: 25.0, height: 30.0),
      (text: 'D.2', top: 140.0, left: 20.0, width: 25.0, height: 30.0),
      (text: 'D.3', top: 180.0, left: 20.0, width: 25.0, height: 30.0),
      (text: 'E', top: 220.0, left: 20.0, width: 12.0, height: 30.0),
      // Blocul 2 (coloana de valori) — vine al doilea în array. Gol
      // orizontal mic (label→valoare ~ 105px, sub pragul de separare pe
      // coloane) — trebuie tot reasamblat pe același rând ca eticheta.
      (text: 'HYUNDAI', top: 102.0, left: 150.0, width: 90.0, height: 30.0),
      (text: 'TLE F5D14', top: 142.0, left: 150.0, width: 90.0, height: 30.0),
      (text: 'TUCSON', top: 182.0, left: 150.0, width: 90.0, height: 30.0),
      (text: 'TMAJ381ADHJ249268', top: 222.0, left: 150.0, width: 90.0, height: 30.0),
    ];

    test('pairs each label with its value by row position, not block order', () {
      final reconstructed = reconstructRowsByPosition(scrambledColumns);

      expect(reconstructed,
          'D.1 HYUNDAI\nD.2 TLE F5D14\nD.3 TUCSON\nE TMAJ381ADHJ249268');
    });

    test('parseTalonText extracts the correct model/make/VIN once reconstructed', () {
      final result = scanner.parseTalonText(reconstructRowsByPosition(scrambledColumns));

      expect(result.make, 'Hyundai');
      expect(result.model, 'TUCSON');
      expect(result.vin, 'TMAJ381ADHJ249268');
    });

    test('pairs P.2 with its kW value across columns and converts to CP', () {
      const powerLines = <PositionedTextLine>[
        (text: 'P.1', top: 200.0, left: 550.0, width: 25.0, height: 28.0),
        (text: 'P.2', top: 232.0, left: 550.0, width: 25.0, height: 28.0),
        (text: '1995', top: 201.0, left: 590.0, width: 35.0, height: 28.0),
        (text: '136', top: 233.0, left: 590.0, width: 35.0, height: 28.0),
      ];

      final result = scanner.parseTalonText(reconstructRowsByPosition(powerLines));

      // 136 kW * 1.35962 ≈ 184.9 → 185 CP (Hyundai Tucson 2.0 CRDi 185).
      expect(result.powerCp, 185);
    });

    test('does not merge adjacent rows that are close but distinct', () {
      final reconstructed = reconstructRowsByPosition(scrambledColumns);
      final rows = reconstructed.split('\n');

      expect(rows.length, 4);
    });
  });

  group('reconstructRowsByPosition (three-column talon with anexă)', () {
    // Reprodus pe o poză reală de talon cu anexă (Ford Focus) trimisă de
    // utilizator: pe lângă coloana de câmpuri A/D.1/D.3/E, talonul mai are
    // o a doua coloană INDEPENDENTĂ de câmpuri (B/P.1/P.2/P.3/R...) — nu o
    // pereche etichetă/valoare a aceluiași câmp, ci alt grup de câmpuri cu
    // altă densitate de rânduri. Rândurile D.3 și E ("FOCUS"/VIN, deja
    // complete pe propria linie ML Kit) ajung, întâmplător, la aceeași
    // înălțime cu rânduri din a doua coloană — dar fiindcă niciunul dintre
    // ele nu e un fragment "gol" de etichetă ([_looksLikeBareLabelFragment]
    // — raport lățime/înălțime peste prag), reconstructRowsByPosition nu le
    // amestecă, oricât de aproape ar fi pe verticală.
    const twoIndependentColumns = <PositionedTextLine>[
      // Coloana 1 — câmpuri A/D.3/E, gol mic etichetă→valoare (deja pe
      // aceeași linie, ca într-un scan curat).
      (text: 'D.3 FOCUS', top: 180.0, left: 20.0, width: 100.0, height: 30.0),
      (text: 'E WV1ZZZ7HZ8H123456', top: 220.0, left: 20.0, width: 220.0, height: 30.0),
      // Coloana 2 — câmpuri complet independente, la o distanță orizontală
      // mare (gol >> pragul de separare), dar la înălțimi apropiate de
      // rândurile din coloana 1.
      (text: 'P.3 BENZINA', top: 178.0, left: 400.0, width: 120.0, height: 30.0),
      (text: 'R ALB', top: 222.0, left: 400.0, width: 80.0, height: 30.0),
    ];

    test('keeps independent field-group columns separate instead of merging by row height', () {
      final reconstructed = reconstructRowsByPosition(twoIndependentColumns);
      final rows = reconstructed.split('\n');

      expect(rows, containsAll(<String>[
        'D.3 FOCUS',
        'E WV1ZZZ7HZ8H123456',
        'P.3 BENZINA',
        'R ALB',
      ]));
    });

    test('parseTalonText extracts the correct model/VIN unaffected by the second column', () {
      final result = scanner.parseTalonText(reconstructRowsByPosition(twoIndependentColumns));

      expect(result.model, 'FOCUS');
      expect(result.vin, 'WV1ZZZ7HZ8H123456');
    });

    // Geometria EXACTĂ raportată de ML Kit pe poza reală de talon (Ford
    // Focus-CNG Technik cu anexă) care a reprodus bug-ul — capturată direct
    // de pe device printr-un print de debug temporar, nu inventată. Fixează
    // regresia definitiv: fără acest test, o viitoare modificare a pragului
    // din [_looksLikeBareLabelFragment] ar putea din nou lăsa D.3/E să se
    // amestece cu coloana B/P.1/P.2/P.3/R, fără ca vreun test sintetic mai
    // simplu de mai sus să prindă asta.
    const realFordFocusTalon = <PositionedTextLine>[
      (text: 'D.3 FOCUS', top: 299.0, left: 243.0, width: 134.0, height: 36.0),
      (text: 'E WFOKXXGCBKDJ42375', top: 332.0, left: 244.0, width: 341.0, height: 38.0),
      (text: 'B 18.03.2013', top: 164.0, left: 807.0, width: 162.0, height: 30.0),
      (text: 'H', top: 174.0, left: 1072.0, width: 14.0, height: 16.0),
      (text: 'Pi 1596', top: 265.0, left: 809.0, width: 96.0, height: 30.0),
      (text: 'P2 88', top: 259.0, left: 1074.0, width: 67.0, height: 31.0),
      (text: 'Pa BENZINA+GPL', top: 292.0, left: 811.0, width: 225.0, height: 36.0),
      (text: 'R ALB', top: 328.0, left: 811.0, width: 88.0, height: 35.0),
    ];

    test('reproduces the real Ford Focus scan: model/VIN stay intact, P.1/P.2 pair up', () {
      final reconstructed = reconstructRowsByPosition(realFordFocusTalon);
      final result = scanner.parseTalonText(reconstructed);

      expect(result.model, 'FOCUS');
      expect(result.vin, 'WFOKXXGCBKDJ42375'.replaceAll('O', '0').replaceAll('I', '1'));
      expect(reconstructed, contains('B 18.03.2013 H'));
      expect(reconstructed, contains('Pi 1596 P2 88'));
    });
  });

  group('reconstructRowsByPosition (real Hyundai Tucson talon with anexă)', () {
    // Geometria EXACTĂ raportată de ML Kit pe o A DOUA poză reală de talon
    // (Hyundai Tucson, de data asta cu anexă — talonul original din
    // comentariile de mai sus era fotografiat fără anexă) care a reprodus
    // un bug DIFERIT: eticheta "D.2" (goală, fără valoare atașată — ML Kit
    // a rupt-o de restul rândului) a prins din greșeală data de la câmpul
    // I.1 ("28.02.2020", de pe altă coloană, DOAR puțin mai aproape pe
    // verticală) în loc de propria ei valoare "TLE F5D14" — o toleranță
    // verticală strictă alegea greșit "primul găsit", nu cel mai apropiat
    // candidat valid la o distanță orizontală rezonabilă. Capturat direct
    // de pe device printr-un print de debug temporar, nu inventat.
    const realHyundaiTucsonTalon = <PositionedTextLine>[
      (text: 'D.1', top: 192.0, left: 166.0, width: 33.0, height: 18.0),
      (text: 'D.2', top: 224.0, left: 163.0, width: 37.0, height: 19.0),
      (text: 'D.3', top: 257.0, left: 161.0, width: 37.0, height: 19.0),
      (text: 'K', top: 328.0, left: 157.0, width: 16.0, height: 18.0),
      (text: 'AUTOTURISM M1', top: 168.0, left: 227.0, width: 258.0, height: 42.0),
      (text: 'HYUNDAI', top: 201.0, left: 227.0, width: 152.0, height: 31.0),
      (text: 'TLE F5D14', top: 233.0, left: 223.0, width: 157.0, height: 33.0),
      (text: 'TUCSON', top: 266.0, left: 222.0, width: 134.0, height: 32.0),
      (text: 'TMAJ381ADHJ249268', top: 302.0, left: 218.0, width: 297.0, height: 43.0),
      (text: 'e11*2007/46*2724*00', top: 335.0, left: 218.0, width: 279.0, height: 42.0),
      (text: 'B', top: 191.0, left: 751.0, width: 11.0, height: 14.0),
      (text: '14.09.2016', top: 192.0, left: 791.0, width: 109.0, height: 24.0),
      (text: '28.02.2020', top: 222.0, left: 788.0, width: 116.0, height: 26.0),
      (text: 'P.1 1995', top: 276.0, left: 752.0, width: 91.0, height: 26.0),
      (text: 'P.3 MOTORINA', top: 306.0, left: 753.0, width: 192.0, height: 29.0),
      (text: 'H', top: 207.0, left: 994.0, width: 11.0, height: 13.0),
      (text: 'I.1 28.02.2020', top: 233.0, left: 993.0, width: 139.0, height: 37.0),
      (text: 'P.2 136', top: 292.0, left: 997.0, width: 70.0, height: 25.0),
      (text: 'NR.', top: 263.0, left: 1266.0, width: 24.0, height: 12.0),
      (text: 'LA CERTIFICATUL DE INMATAICULARE', top: 239.0, left: 1297.0, width: 262.0, height: 38.0),
    ];

    test('pairs D.2/D.3/B with their true values, not a nearer value from another column', () {
      final reconstructed = reconstructRowsByPosition(realHyundaiTucsonTalon);

      expect(reconstructed, contains('D.2 TLE F5D14'));
      expect(reconstructed, contains('D.3 TUCSON'));
      expect(reconstructed, contains('B 14.09.2016'));
    });

    test('parseTalonText extracts the correct model/year from the real Hyundai scan', () {
      final result = scanner.parseTalonText(reconstructRowsByPosition(realHyundaiTucsonTalon));

      expect(result.model, 'TUCSON');
      expect(result.year, 2016);
    });
  });

  test('recognizes plate numbers with a single-letter county code', () {
    final result = scanner.parseTalonText('Numar de inmatriculare: B 45 XYZ');

    expect(result.plateNumber, 'B45XYZ');
  });

  test('picks the model from the next line when the make line has no trailing text', () {
    const sampleText = '''
D.1
VOLKSWAGEN
GOLF
''';

    final result = scanner.parseTalonText(sampleText);

    expect(result.make, 'Volkswagen');
    expect(result.model, 'GOLF');
  });

  test('skips the D.3 label line itself and picks the real model value below it', () {
    // Regresie: pe un talon real scanat, marca și modelul apar pe linii
    // separate de propriile etichete (nu combinate ca "D.1) DACIA"), iar
    // eticheta D.3 conține cuvinte descriptive ("Denumire comercială
    // (Model)") care nu trebuie confundate cu valoarea reală a modelului.
    const sampleText = '''
CERTIFICAT DE INMATRICULARE
A) Numar de inmatriculare
B 123 ABC
D.1) Marca
DACIA
D.3) Denumire comerciala (Model)
SANDERO STEPWAY
E) Numar de identificare (VIN)
UU1SDDDR551234567
''';

    final result = scanner.parseTalonText(sampleText);

    expect(result.make, 'Dacia');
    expect(result.model, 'SANDERO STEPWAY');
    expect(result.plateNumber, 'B123ABC');
    expect(result.vin, 'UU1SDDDR551234567');
  });

  test('extracts engine code from an explicit "Cod motor" label on the same line', () {
    final result = scanner.parseTalonText('Cod motor: K9K');

    expect(result.engineCode, 'K9K');
  });

  test('extracts engine code when the value is on the line below the label', () {
    const sampleText = '''
Motor
CAYC
''';

    final result = scanner.parseTalonText(sampleText);

    expect(result.engineCode, 'CAYC');
  });

  test('does not confuse "motorina"/"motorizare" with the engine code label', () {
    const sampleText = '''
P.3) Motorina
Combustibil
''';

    final result = scanner.parseTalonText(sampleText);

    expect(result.engineCode, isNull);
  });

  test('extracts VIN from the E) field even when OCR misreads 0 as O', () {
    // Regresie: OCR confundă frecvent cifra 0 cu litera O (mai ales pe
    // fonturi stencil de pe talon), ceea ce rupea potrivirea regexului strict
    // de 17 caractere. Ancorarea pe eticheta E) permite corectarea sigură a
    // acestei confuzii, fiindcă știm cu certitudine că linia reprezintă VIN-ul.
    const sampleText = '''
E) Numar de identificare (VIN)
WVWZZZ9NZ8Y1234O6
''';

    final result = scanner.parseTalonText(sampleText);

    expect(result.vin, 'WVWZZZ9NZ8Y1234O6'.replaceAll('O', '0'));
  });

  test('extracts VIN placed directly on the E) label line', () {
    final result = scanner.parseTalonText('E) WVWZZZ9NZ8Y123456');

    expect(result.vin, 'WVWZZZ9NZ8Y123456');
  });

  test('falls back to the blind VIN scan when no E) label is present', () {
    const sampleText = '''
Some unlabeled scan text
WVWZZZ9NZ8Y123456
more text
''';

    final result = scanner.parseTalonText(sampleText);

    expect(result.vin, 'WVWZZZ9NZ8Y123456');
  });

  test('extracts make/model/VIN from a real RAR talon layout (label E, no punctuation)', () {
    // Regresie: pe un talon real (fotografiat de utilizator), eticheta E nu
    // are nicio punctuație după literă ("E   WVWZZZ..."), spre deosebire de
    // ce presupunea regexul inițial ("E)" sau "E."). Fără fix, VIN-ul nu era
    // deloc extras pe scanări reale, deși testele cu "E)" fabricat treceau.
    const sampleText = '''
A IS-15-CPI
J AUTOTURISM M1
D.1 VOLKSWAGEN
D.2 9N ABSBNMX01
D.3 POLO
E WVWZZZ9NZ9Y024262
''';

    final result = scanner.parseTalonText(sampleText);

    expect(result.make, 'Volkswagen');
    expect(result.model, 'POLO');
    expect(result.plateNumber, 'IS15CPI');
    expect(result.vin, 'WVWZZZ9NZ9Y024262');
  });

  group('parseRcaText', () {
    // Text extras (pdftotext -layout) de pe prima pagină a unei polițe RCA
    // reale, emisă de HD Insurance (Hellas Direct) — trimis de utilizator ca
    // să reglez extracția pe un document adevărat, nu doar pe presupuneri.
    const realRcaFirstPageText = '''
CONTRACT DE ASIGURARE DE RĂSPUNDERE CIVILĂ AUTO RCA                                                                                                                     Seria RO/32/V32/LM Nr. 1100737277
DENUMIRE ASIGURĂTOR: HD INSURANCE PLC NICOSIA – SUCURSALA BUCURESTI                                                                                                                     R.C. J40/13826/2022 C.U.I. 46500594
Sucursala / Agenția: BUCUREȘTI                                                                                                                                Denumire broker / agent: PINT.RO BROKER DE ASIGURARE SRL
Tel/Fax: +40376448858 /                                                                                                                                                                        Cod broker / agent: RBK - 569

Valabilitate Contract de la 07/04/2026 până la 06/04/2027 Contract emis în data de 06/04/2026, ora 14:16 Prima de asigurare 1.152,37 RON, Prima decontare
directă 0,00 RON, Prima totală 1.152,37 RON Nr. rate 1, după cum urmează: Rata 1: 1.152,37 RON, la 06/04/2026, Clasa Bonus-Malus B5 Încasată cu numerar în data de
06/04/2026
''';

    test('extracts provider, policy number and validity dates from a real RCA policy', () {
      final result = scanner.parseRcaText(realRcaFirstPageText);

      expect(result.provider, 'HD Insurance');
      expect(result.policyNumber, 'RO/32/V32/LM 1100737277');
      expect(result.startDate, DateTime(2026, 4, 7));
      expect(result.expiryDate, DateTime(2027, 4, 6));
    });

    test('extracts the expiry date even when OCR mangles the "până" diacritic', () {
      // Regresie: pe ML Kit OCR (device real, nu pdftotext), "până" a fost
      // recunoscut ca "pånă" (å în loc de â) — eticheta de expirare nu se
      // potrivea deloc și data rămânea necompletată, deși data de început și
      // restul câmpurilor se extrăgeau corect.
      final result = scanner.parseRcaText(
        'Valabilitate Contract de la 07/04/2026 pånă la 06/04/2027 Contract emis în data de 06/04/2026',
      );

      expect(result.startDate, DateTime(2026, 4, 7));
      expect(result.expiryDate, DateTime(2027, 4, 6));
    });

    test('infers the start date from the date right before "până la" when the start label is unreadable', () {
      // Regresie: pe o a doua poliță reală (Anytime/Interamerican Hellenic),
      // ML Kit nu a recunoscut deloc eticheta de început ("Valabilitate" e
      // un cuvânt lung, predispus la erori) — doar "până la" s-a potrivit,
      // deci fostul cod nu completa nicio dată de început. Simulăm aici
      // lipsa etichetei de început prin text fără cuvântul "Valabilitate".
      final result = scanner.parseRcaText(
        'Contract 02/07/2026 până la 01/07/2027 Contract emis în data de 01/07/2026',
      );

      expect(result.startDate, DateTime(2026, 7, 2));
      expect(result.expiryDate, DateTime(2027, 7, 1));
    });

    test('extracts the provider from the line after the contract header when no label is present', () {
      // Regresie: pe polița reală Anytime/Interamerican Hellenic nu există
      // deloc eticheta "DENUMIRE ASIGURĂTOR:" — numele apare direct pe
      // rândul de după antetul "CONTRACT DE ASIGURARE...".
      final result = scanner.parseRcaText('''
CONTRACT DE ASIGURARE DE RĂSPUNDERE CIVILĂ AUTO RCA                     Seria RO/34/D34/TL nr. 100302796
INTERAMERICAN HELLENIC INSURANCE COMPANY S.A. ATENA - SUCURSALA BUCUREŞTI     Tel.: 0374 50 2222     R.C. J2025033442009     C.U.I. 51767670
''');

      expect(result.provider, 'INTERAMERICAN HELLENIC INSURANCE COMPANY S.A. ATENA - SUCURSALA BUCUREŞTI');
    });

    test('falls back to the label-based provider extraction for an unlisted insurer', () {
      final result = scanner.parseRcaText(
        'DENUMIRE ASIGURĂTOR: SOME NEW INSURER SA                    R.C. J40/1/2020 C.U.I. 123',
      );

      expect(result.provider, 'SOME NEW INSURER SA');
    });

    test('falls back gracefully on unrelated text', () {
      final result = scanner.parseRcaText('random unrelated text with no policy data');

      expect(result.provider, isNull);
      expect(result.policyNumber, isNull);
      expect(result.startDate, isNull);
      expect(result.expiryDate, isNull);
      expect(result.fieldsFound, 0);
    });
  });

  group('parseRcaText (CASCO, document fictiv)', () {
    // CASCO reutilizează parseRcaText (vezi comentariul din
    // add_edit_document_screen.dart, _scansData) — dar spre deosebire de
    // RCA, nu există un exemplu real de poliță CASCO disponibil, deci acest
    // text e FICTIV/sintetic, scris ca să semene plauzibil cu o poliță
    // CASCO reală (fără formatul standardizat A.S.F. al RCA-ului — CASCO nu
    // e reglementat identic la toți asigurătorii), ca să verifice că
    // fallback-urile generice (etichetă provider, "de la"/"până la", serie
    // și număr) se aplică rezonabil și aici. Dacă un utilizator raportează
    // o extragere greșită pe o poliță CASCO reală, înlocuiește acest test
    // cu textul real, la fel cum s-a procedat pentru RCA.
    const fictionalCascoText = '''
POLIȚĂ DE ASIGURARE CASCO
DENUMIRE ASIGURĂTOR: Groupama Asigurări SA
Serie și număr: CASCO-2026-004521
Valabilitate de la 01/08/2026 până la 31/07/2027
''';

    test('extracts provider, policy number and validity dates from a fictional CASCO policy', () {
      final result = scanner.parseRcaText(fictionalCascoText);

      expect(result.provider, 'Groupama');
      expect(result.policyNumber, 'CASCO-2026-004521');
      expect(result.startDate, DateTime(2026, 8, 1));
      expect(result.expiryDate, DateTime(2027, 7, 31));
    });

    test('falls back to the positional/label provider extraction for an unlisted CASCO insurer', () {
      final result = scanner.parseRcaText('''
POLIȚĂ DE ASIGURARE CASCO
DENUMIRE ASIGURĂTOR: Fictional Insurance Co SRL
Serie și număr: CASCO-2026-999999
Valabilitate de la 15/09/2026 până la 14/09/2027
''');

      expect(result.provider, 'Fictional Insurance Co SRL');
      expect(result.policyNumber, 'CASCO-2026-999999');
      expect(result.startDate, DateTime(2026, 9, 15));
      expect(result.expiryDate, DateTime(2027, 9, 14));
    });
  });

  group('parseRovinietaText', () {
    test('extracts plate number and validity dates from a typical rovinieta confirmation', () {
      final result = scanner.parseRovinietaText('''
Confirmare achizitie rovinieta
Numar de inmatriculare: B123ABC
Valabilitate de la 10/05/2026 până la 09/06/2026
''');

      expect(result.plateNumber, 'B123ABC');
      expect(result.startDate, DateTime(2026, 5, 10));
      expect(result.expiryDate, DateTime(2026, 6, 9));
    });

    test('extracts data from a fictional CNAIR-style e-rovinieta confirmation email', () {
      // Document fictiv/sintetic (nu de la un utilizator real) — testează
      // un format de confirmare plauzibil pentru un e-mail CNAIR/
      // rovinieta.ro, diferit de textul de mai sus (fără eticheta explicită
      // "de la", ca la a doua poliță RCA reală din grupul parseRcaText).
      final result = scanner.parseRovinietaText('''
Stimate client,
Va confirmam achizitionarea rovinietei pentru vehiculul cu numarul B99FIC.
Rovinieta este valabila 20/10/2026 până la 19/11/2026.
Va multumim.
''');

      expect(result.plateNumber, 'B99FIC');
      expect(result.startDate, DateTime(2026, 10, 20));
      expect(result.expiryDate, DateTime(2026, 11, 19));
    });

    test('falls back to the two-dates heuristic when no label is recognized', () {
      final result = scanner.parseRovinietaText('B 45 XYZ 10.05.2026 09.06.2026');

      expect(result.plateNumber, 'B45XYZ');
      expect(result.startDate, DateTime(2026, 5, 10));
      expect(result.expiryDate, DateTime(2026, 6, 9));
    });

    test('falls back gracefully on unrelated text', () {
      final result = scanner.parseRovinietaText('random unrelated text with no toll data');

      expect(result.plateNumber, isNull);
      expect(result.startDate, isNull);
      expect(result.expiryDate, isNull);
      expect(result.fieldsFound, 0);
    });
  });
}
