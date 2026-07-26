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
    expect(result.fieldsFound, 0);
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
}
