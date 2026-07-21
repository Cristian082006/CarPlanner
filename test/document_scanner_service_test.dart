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
}
