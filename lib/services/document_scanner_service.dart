import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Date extrase dintr-o poză a talonului (certificatul de înmatriculare).
/// Orice câmp poate lipsi dacă OCR-ul nu l-a putut recunoaște — utilizatorul
/// revede și corectează întotdeauna înainte de salvare.
class ScannedVehicleData {
  final String? make;
  final String? model;
  final String? vin;
  final String? plateNumber;
  final String? engineCode;
  final String rawText;

  ScannedVehicleData({
    this.make,
    this.model,
    this.vin,
    this.plateNumber,
    this.engineCode,
    required this.rawText,
  });

  int get fieldsFound =>
      [make, model, vin, plateNumber, engineCode].where((v) => v != null).length;
}

/// Recunoaște text de pe o poză a talonului folosind Google ML Kit (rulează
/// pe dispozitiv, gratuit) și extrage marca, modelul, VIN-ul și numărul de
/// înmatriculare printr-o potrivire euristică pe textul recunoscut.
class DocumentScannerService {
  DocumentScannerService._internal();
  static final DocumentScannerService instance = DocumentScannerService._internal();

  static const List<String> _knownMakes = [
    'Dacia', 'Renault', 'Volkswagen', 'Ford', 'Opel', 'BMW', 'Mercedes-Benz', 'Mercedes',
    'Audi', 'Toyota', 'Honda', 'Hyundai', 'Kia', 'Skoda', 'Peugeot', 'Citroen',
    'Fiat', 'Nissan', 'Mazda', 'Suzuki', 'Seat', 'Volvo', 'Chevrolet', 'Mitsubishi',
    'Mini', 'Jeep', 'Land Rover', 'Porsche', 'Lexus', 'Subaru', 'Alfa Romeo', 'Chrysler',
    'Dodge', 'Jaguar', 'Smart', 'SsangYong', 'Isuzu', 'Iveco', 'MAN', 'Scania', 'DAF', 'Tesla',
  ];

  static final RegExp _vinPattern = RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b');
  static final RegExp _platePattern =
      RegExp(r'\b([A-Z]{1,2})\s?-?\s?(\d{2,3})\s?-?\s?([A-Z]{3})\b');

  /// Etichetele de câmp de pe talon (ex: "D.1)", "D.3", "E.") — necesită
  /// explicit un punct urmat de o cifră, ca să nu confunde cuvinte normale
  /// (ex: "VOLKSWAGEN") cu o etichetă de 1-2 litere.
  static final RegExp _fieldLabel =
      RegExp(r'^[A-Z]{1,2}\.\d+\)?[:.\-]?\s*', caseSensitive: false);

  String _stripLabel(String line) => line.replaceFirst(_fieldLabel, '').trim();

  /// Cuvinte care apar în textul unei ETICHETE de câmp (nu al unei valori
  /// reale), ex. "D.3) Denumire comercială (Model)" — dacă o linie candidat
  /// pentru model conține unul dintre ele, e mai probabil o etichetă decât
  /// numele real al modelului, deci o sărim.
  static final RegExp _labelLikeWords =
      RegExp(r'model|comercial|denumire|marca|tip\b|combustibil', caseSensitive: false);

  /// Codul de câmp D.3 (denumire comercială / model) de pe talonul
  /// armonizat UE — căutat separat de marcă, ca să nu depindă de poziția
  /// relativă a liniilor (spre deosebire de etichetă, care poate fi pe
  /// propria linie, între linia mărcii și linia cu valoarea modelului).
  static final RegExp _modelFieldCode = RegExp(r'\bD\.?\s*3\b', caseSensitive: false);

  /// Eticheta pentru codul motor — spre deosebire de D.3 (model), talonul
  /// românesc NU are un câmp standardizat UE dedicat pentru asta, deci
  /// extragerea e best-effort: caută explicit cuvântul "motor" ca etichetă
  /// (nu ca parte din "motorină"/"motorizare") urmat de o valoare
  /// alfanumerică scurtă, gen "K9K", "CAYC", "1.5 DCI". Dacă talonul
  /// fotografiat nu conține un asemenea câmp — foarte posibil, formatul
  /// variază — rămâne null și utilizatorul completează manual, la fel ca la
  /// orice alt câmp OCR nerecunoscut.
  static final RegExp _engineCodeLabel =
      RegExp(r'\bcod\s*motor\b|\bmotor(?!in[aă]|izare)\b', caseSensitive: false);
  static final RegExp _engineCodeValue =
      RegExp(r'^[A-Z0-9][A-Z0-9.\-\/]{1,9}$', caseSensitive: false);
  static final RegExp _engineCodeExcludedWords = RegExp(
    r'^(diesel|benzin[aă]|motorin[aă]|electric|hibrid|cilindri|capacitate|putere|combustibil)$',
    caseSensitive: false,
  );

  /// Fotografiază → recunoaște textul → extrage câmpurile. Aruncă orice
  /// eroare a ML Kit mai departe către apelant.
  Future<ScannedVehicleData> scanTalon(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      return parseTalonText(result.text);
    } finally {
      await recognizer.close();
    }
  }

  /// Funcție pură de parsare, separată de captura foto/ML Kit ca să poată
  /// fi testată direct cu text simulat.
  ScannedVehicleData parseTalonText(String rawText) {
    final upper = rawText.toUpperCase();

    final vinMatch = _vinPattern.firstMatch(upper);
    final plateMatch = _platePattern.firstMatch(upper);
    final plateNumber = plateMatch != null
        ? '${plateMatch.group(1)}${plateMatch.group(2)}${plateMatch.group(3)}'
        : null;

    String? make;
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    outer:
    for (var i = 0; i < lines.length; i++) {
      final cleanLine = _stripLabel(lines[i]);
      for (final candidate in _knownMakes) {
        final regex = RegExp(r'\b' + RegExp.escape(candidate) + r'\b', caseSensitive: false);
        if (!regex.hasMatch(cleanLine)) continue;
        make = candidate;
        break outer;
      }
    }

    // Modelul e căutat separat, ancorat de codul de câmp D.3 dacă apare pe
    // talon — mai robust decât "linia de după marcă", care poate nimeri
    // peste eticheta următorului câmp în loc de valoarea reală.
    String? model;
    for (var i = 0; i < lines.length; i++) {
      if (!_modelFieldCode.hasMatch(lines[i])) continue;

      final sameLine = _stripLabel(lines[i]);
      if (sameLine.isNotEmpty && !_labelLikeWords.hasMatch(sameLine) && sameLine.length <= 40) {
        model = sameLine;
      } else if (i + 1 < lines.length) {
        final next = _stripLabel(lines[i + 1]);
        if (next.isNotEmpty && !_labelLikeWords.hasMatch(next) && next.length <= 40) {
          model = next;
        }
      }
      break;
    }

    // Fără cod D.3 pe talon: încercăm linia de după marcă, ca fallback.
    if (model == null && make != null) {
      for (var i = 0; i < lines.length; i++) {
        final cleanLine = _stripLabel(lines[i]);
        final regex = RegExp(r'\b' + RegExp.escape(make) + r'\b', caseSensitive: false);
        if (!regex.hasMatch(cleanLine)) continue;

        final after = cleanLine.replaceFirst(regex, '').trim();
        if (after.isNotEmpty && !_labelLikeWords.hasMatch(after) && after.length <= 40) {
          model = after;
        } else if (i + 1 < lines.length) {
          final next = _stripLabel(lines[i + 1]);
          if (next.isNotEmpty && !_labelLikeWords.hasMatch(next) && next.length <= 40) {
            model = next;
          }
        }
        break;
      }
    }

    String? engineCode;
    for (var i = 0; i < lines.length; i++) {
      final labelMatch = _engineCodeLabel.firstMatch(lines[i]);
      if (labelMatch == null) continue;

      final sameLine = lines[i]
          .substring(labelMatch.end)
          .replaceFirst(RegExp(r'^[:\-\)]\s*'), '')
          .trim();
      if (_engineCodeValue.hasMatch(sameLine) && !_engineCodeExcludedWords.hasMatch(sameLine)) {
        engineCode = sameLine.toUpperCase();
      } else if (i + 1 < lines.length) {
        final next = _stripLabel(lines[i + 1]);
        if (_engineCodeValue.hasMatch(next) && !_engineCodeExcludedWords.hasMatch(next)) {
          engineCode = next.toUpperCase();
        }
      }
      break;
    }

    return ScannedVehicleData(
      make: make,
      model: model,
      vin: vinMatch?.group(0),
      plateNumber: plateNumber,
      engineCode: engineCode,
      rawText: rawText,
    );
  }
}
