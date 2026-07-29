import 'dart:io';
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

/// Date extrase dintr-o poză a talonului (certificatul de înmatriculare).
/// Orice câmp poate lipsi dacă OCR-ul nu l-a putut recunoaște — utilizatorul
/// revede și corectează întotdeauna înainte de salvare.
class ScannedVehicleData {
  final String? make;
  final String? model;
  final String? vin;
  final String? plateNumber;
  final String? engineCode;
  final int? year;
  final int? powerCp;
  final String rawText;

  ScannedVehicleData({
    this.make,
    this.model,
    this.vin,
    this.plateNumber,
    this.engineCode,
    this.year,
    this.powerCp,
    required this.rawText,
  });

  int get fieldsFound =>
      [make, model, vin, plateNumber, engineCode, year, powerCp].where((v) => v != null).length;
}

/// Date extrase din prima pagină a unui PDF de poliță RCA/CASCO. La fel ca
/// [ScannedVehicleData], orice câmp poate lipsi — formatul diferă mult între
/// asigurători, deci extracția e best-effort; utilizatorul revede și
/// corectează întotdeauna înainte de salvare.
class ScannedRcaData {
  final String? provider;
  final String? policyNumber;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final String rawText;

  ScannedRcaData({
    this.provider,
    this.policyNumber,
    this.startDate,
    this.expiryDate,
    required this.rawText,
  });

  int get fieldsFound =>
      [provider, policyNumber, startDate, expiryDate].where((v) => v != null).length;
}

/// O linie de text recunoscută de ML Kit, cu poziția ei geometrică pe
/// imagine (colțul stânga-sus + lățime + înălțime) — suficient pentru
/// gruparea pe coloane/rânduri vizuale din [reconstructRowsByPosition].
/// Extras separat de tipul concret al ML Kit (`TextLine`) ca funcția de
/// reconstrucție să poată fi testată direct, cu date simulate, fără să
/// depindă de OCR real.
typedef PositionedTextLine = ({String text, double top, double left, double width, double height});

/// O linie e considerată un fragment "gol" (doar etichetă, fără valoare
/// atașată, ex. "E", "D.3", "B") dacă raportul lățime/înălțime e mic — un
/// cod scurt de 1-3 caractere e aproximativ la fel de lat cât de înalt,
/// spre deosebire de un rând deja complet ("D.3 FOCUS", "E WV1ZZZ...") care
/// e mult mai lat decât înalt. Pragul (2.2) a fost calibrat pe date reale
/// (talon Ford Focus cu anexă): valori scurte de 2 cifre ca "P.2 88" ies
/// tot sub prag (deci tot caută pereche), dar valori de 3+ caractere ca
/// "R ALB" ies clar peste — vezi comentariul de la [reconstructRowsByPosition].
bool _looksLikeBareLabelFragment(PositionedTextLine line) =>
    line.height > 0 && (line.width / line.height) < 2.2;

/// Reconstruiește ordinea "vizuală" (rând cu rând, stânga→dreapta) a
/// liniilor de text recunoscute, pe baza poziției geometrice — nu a ordinii
/// brute întoarse de blocurile ML Kit.
///
/// Talonul românesc poate avea o etichetă îngustă lângă valoarea ei
/// (același câmp, ex. "D.3" + "TUCSON") — ML Kit grupează des astea în
/// blocuri SEPARATE, deci trebuie reasamblate pe același rând (bug
/// reprodus pe o poză reală: D.3 ajungea urmat de "E", eticheta următoare,
/// nu de valoarea reală). Dar talonul cu anexă are și mai multe GRUPURI de
/// câmpuri complet independente unul lângă altul (ex. coloana A/D.1/D.3/E,
/// apoi o a doua coloană B/P.1/P.2, apoi ANEXA) — dacă aceste grupuri au
/// densități diferite de rânduri, la un moment dat rândurile lor ajung la
/// aceeași înălțime pe verticală (goluri orizontale între grupuri prea mici
/// și de mărime comparabilă cu golul etichetă→valoare ca să le distingem
/// după poziție) — bug reprodus pe o poză reală de Ford Focus cu anexă:
/// modelul a ieșit ca fragment din rândul VIN al altei coloane.
///
/// Soluție: nu ne mai bazăm pe o singură trecere de sus în jos care
/// asamblează rândurile pe măsură ce le întâlnește — o etichetă procesată
/// mai devreme poate "fura" din greșeală o valoare apropiată dar greșită,
/// doar pentru că valoarea ei REALĂ (puțin mai departe pe verticală) încă
/// nu fusese "văzută" în acel moment al trecerii (bug reprodus pe o poză
/// reală de talon Hyundai: eticheta "D.2" ajungea perechea cu data de la
/// câmpul I.1, de pe altă coloană, disponibilă mai devreme în ordine, în
/// loc de propria ei valoare reală "TLE F5D14" — care exista, dar mai
/// târziu în listă). În schimb: generăm ÎNTÂI toate perechile candidate
/// posibile (etichetă goală + valoare) din toată pagina, condiționat de
/// (1) exact una dintre cele două linii să fie un fragment "gol" de
/// etichetă ([_looksLikeBareLabelFragment]) — două etichete goale nu se
/// leagă niciodată una de alta, și nici două rânduri deja complete; (2)
/// distanța orizontală dintre ele să nu depășească un prag generos
/// (multiplu din înălțimea mediană a liniilor) — separă o pereche
/// etichetă/valoare de pe ACEEAȘI coloană (gol mic) de o valoare de pe altă
/// coloană (gol mult mai mare, de obicei un salt pe toată lățimea
/// paginii). Apoi le asignăm LACOM, sortate global după apropierea pe
/// verticală (cea mai bună pereche întâi), fiecare linie fiind folosită
/// o singură dată — indiferent de ordinea în care apar pe pagină.
String reconstructRowsByPosition(List<PositionedTextLine> lines) {
  if (lines.isEmpty) return '';
  final heights = [for (final l in lines) l.height]..sort();
  final medianHeight = heights[heights.length ~/ 2];
  final maxHorizontalGap = medianHeight * 6;

  final candidates = <(int, int, double)>[];
  for (var i = 0; i < lines.length; i++) {
    for (var j = i + 1; j < lines.length; j++) {
      final a = lines[i];
      final b = lines[j];
      if (_looksLikeBareLabelFragment(a) == _looksLikeBareLabelFragment(b)) continue;
      final yDiff = ((a.top + a.height / 2) - (b.top + b.height / 2)).abs();
      final yTolerance = (a.height + b.height) * 0.7;
      if (yDiff > yTolerance) continue;
      if (_horizontalGap(a, b) > maxHorizontalGap) continue;
      candidates.add((i, j, yDiff));
    }
  }
  candidates.sort((x, y) => x.$3.compareTo(y.$3));

  final partner = List<int?>.filled(lines.length, null);
  for (final (i, j, _) in candidates) {
    if (partner[i] != null || partner[j] != null) continue;
    partner[i] = j;
    partner[j] = i;
  }

  final rows = <List<PositionedTextLine>>[];
  final consumed = List<bool>.filled(lines.length, false);
  for (var i = 0; i < lines.length; i++) {
    if (consumed[i]) continue;
    consumed[i] = true;
    final j = partner[i];
    if (j != null) {
      consumed[j] = true;
      rows.add([lines[i], lines[j]]);
    } else {
      rows.add([lines[i]]);
    }
  }
  rows.sort((a, b) => a.map((l) => l.top).reduce((x, y) => x < y ? x : y).compareTo(
      b.map((l) => l.top).reduce((x, y) => x < y ? x : y)));

  return rows.map((row) {
    final sortedRow = [...row]..sort((a, b) => a.left.compareTo(b.left));
    return sortedRow.map((l) => l.text).join(' ');
  }).join('\n');
}

double _horizontalGap(PositionedTextLine a, PositionedTextLine b) {
  final aRight = a.left + a.width;
  final bRight = b.left + b.width;
  if (a.left > bRight) return a.left - bRight;
  if (b.left > aRight) return b.left - aRight;
  return 0;
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

  /// Eticheta câmpului E (VIN) de pe talonul armonizat UE — la fel ca D.3
  /// pentru model, căutăm explicit eticheta în loc să presupunem că VIN-ul
  /// e undeva pe text: câmpul E nu are subnumerotare ("E)", nu "E.1)"), deci
  /// nu se potrivește cu `_fieldLabel`. Pe talonul românesc real eticheta
  /// apare adesea ca simplu "E" urmat direct de spațiu și valoare, fără
  /// punctuație — `(?![A-Za-z])` acceptă orice separator (sau capătul
  /// liniei) după "E", dar nu confundă cuvinte care încep cu E ("Euro...").
  static final RegExp _vinFieldCode = RegExp(r'^E(?![A-Za-z])', caseSensitive: false);

  /// Eticheta câmpului B (data primei înmatriculări) de pe talonul
  /// armonizat UE — confirmat de utilizator că funcționează pe talonul lui
  /// real ca proxy pentru anul de fabricație (talonul românesc nu are un
  /// câmp separat, standardizat, dedicat exclusiv anului de fabricație).
  static final RegExp _yearFieldCode = RegExp(r'^B(?![A-Za-z])', caseSensitive: false);

  /// Literele I, O, Q nu apar niciodată într-un VIN real (excluse explicit
  /// din standard ca să nu se confunde cu 1/0). OCR-ul le scrie totuși
  /// uneori în locul cifrei corespunzătoare, mai ales pe fonturi stencil de
  /// pe talon — corectăm asta DOAR pe o linie deja ancorată de eticheta E),
  /// unde suntem siguri că textul chiar reprezintă VIN-ul (nu are sens să
  /// aplicăm corecția pe un scan orb al întregii pagini, ar da fals-pozitive).
  static String _fixVinOcrConfusables(String value) =>
      value.replaceAll('O', '0').replaceAll('Q', '0').replaceAll('I', '1');

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

  /// Codul de câmp P.2 (puterea maximă netă) de pe talonul armonizat UE —
  /// mereu în kW (confirmat de utilizator pe talonul lui real; o încercare
  /// anterioară de a citi și o valoare CP direct dintr-o paranteză de pe
  /// același rând s-a dovedit greșită — paranteza e de fapt turația
  /// motorului (min⁻¹), nu CP, și putea fi confundată cu CP la valori mici).
  /// Convertim noi kW→CP (1 kW ≈ 1,35962 CP) și rotunjim — asta e valoarea
  /// folosită la filtrarea motoarelor candidate mai jos.
  static final RegExp _powerFieldCode = RegExp(r'\bP\.?\s*2\b', caseSensitive: false);
  static final RegExp _powerValueSinglePattern = RegExp(r'(\d{2,3})');

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
      final positioned = <PositionedTextLine>[
        for (final block in result.blocks)
          for (final line in block.lines)
            (
              text: line.text,
              top: line.boundingBox.top,
              left: line.boundingBox.left,
              width: line.boundingBox.width,
              height: line.boundingBox.height,
            ),
      ];
      final reconstructed = reconstructRowsByPosition(positioned);
      return parseTalonText(reconstructed.isEmpty ? result.text : reconstructed);
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

    // VIN ancorat de eticheta E — mai robust decât scanarea oarbă de mai
    // sus, care ratează VIN-ul dacă OCR-ul citește greșit o singură literă
    // (mai ales O/Q/I în locul lui 0/0/1, frecvent pe fonturile stencil de
    // pe talon). Corecția de confuzii se aplică doar aici, unde eticheta ne
    // dă certitudinea că textul chiar reprezintă VIN-ul.
    String? labeledVin;
    for (var i = 0; i < lines.length; i++) {
      if (!_vinFieldCode.hasMatch(lines[i])) continue;
      final sameLineValue = lines[i].replaceFirst(_vinFieldCode, '').trim();
      final candidates = [sameLineValue, if (i + 1 < lines.length) lines[i + 1]];
      for (final raw in candidates) {
        final compact = _fixVinOcrConfusables(raw.toUpperCase()).replaceAll(RegExp(r'[\s-]'), '');
        if (RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(compact)) {
          labeledVin = compact;
          break;
        }
      }
      break;
    }

    // Anul, ancorat de câmpul B (data primei înmatriculări) — vezi
    // comentariul de la [_yearFieldCode].
    int? year;
    for (var i = 0; i < lines.length; i++) {
      if (!_yearFieldCode.hasMatch(lines[i])) continue;
      final sameLineValue = lines[i].replaceFirst(_yearFieldCode, '').trim();
      final candidates = [sameLineValue, if (i + 1 < lines.length) lines[i + 1]];
      for (final raw in candidates) {
        final dateMatch = _datePattern.firstMatch(raw);
        if (dateMatch == null) continue;
        final parsedYear = int.tryParse(dateMatch.group(3)!);
        final currentYear = DateTime.now().year;
        if (parsedYear != null && parsedYear >= 1950 && parsedYear <= currentYear + 1) {
          year = parsedYear;
          break;
        }
      }
      break;
    }

    // Puterea, ancorată de câmpul P.2 — mereu kW, convertit în CP (vezi
    // comentariul de la [_powerFieldCode]).
    int? powerCp;
    for (var i = 0; i < lines.length; i++) {
      final labelMatch = _powerFieldCode.firstMatch(lines[i]);
      if (labelMatch == null) continue;
      final sameLineValue = lines[i].substring(labelMatch.end);
      final candidates = [sameLineValue, if (i + 1 < lines.length) lines[i + 1]];
      for (final raw in candidates) {
        final match = _powerValueSinglePattern.firstMatch(raw);
        if (match == null) continue;
        final kw = int.tryParse(match.group(1)!);
        if (kw != null && kw >= 15 && kw <= 500) {
          powerCp = (kw * 1.35962).round();
          break;
        }
      }
      break;
    }

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
      vin: labeledVin ?? vinMatch?.group(0),
      plateNumber: plateNumber,
      engineCode: engineCode,
      year: year,
      powerCp: powerCp,
      rawText: rawText,
    );
  }

  // ---------- Scanare PDF poliță RCA/CASCO ----------

  static const List<String> _knownInsurers = [
    'Allianz-Țiriac', 'Allianz Tiriac', 'Allianz', 'Groupama', 'OMNIASIG VIG', 'Omniasig',
    'Euroins', 'City Insurance', 'Grawe', 'Generali', 'Asirom', 'Uniqa', 'NN Asigurări',
    'NN Asigurari', 'Axeria', 'Certasig', 'Gothaer', 'Hellas Direct', 'HD Insurance',
  ];

  /// Eticheta standardizată de pe contractele RCA din România (șablon impus
  /// de A.S.F., verificat pe o poliță reală Hellas Direct/HD Insurance):
  /// "DENUMIRE ASIGURĂTOR: {nume}" urmat, pe același rând, de alte câmpuri
  /// (R.C., C.U.I. etc.) — folosit ca fallback dacă numele nu e pe lista
  /// [_knownInsurers] (asigurători noi/mai puțin cunoscuți).
  static final RegExp _providerLabel = RegExp(r'denumire\s*asigur[aă]tor\s*:?', caseSensitive: false);
  // NU include "Sucursală/Sucursala" — pare un separator de câmp potrivit,
  // dar unii asigurători (verificat pe o poliță reală Anytime/Interamerican
  // Hellenic) au chiar "SUCURSALA BUCUREȘTI" ca parte a numelui legal
  // propriu-zis, nu ca eticheta unui câmp următor — tăierea pe acel cuvânt
  // trunchia numele asigurătorului la jumătate.
  static final RegExp _providerCutMarker = RegExp(
    r'\bR\.?\s*C\.?\b|\bC\.?\s*U\.?\s*I\.?\b|\bAgen[țt]i[ae]\b|\bTel\b|\bCod\s+broker\b',
    caseSensitive: false,
  );

  /// Formatul standard al identificatorului de poliță RCA din România:
  /// "Seria RO/32/V32/LM Nr. 1100737277" — verificat pe o poliță reală,
  /// prioritar față de etichetele generice de mai jos.
  static final RegExp _policyNumberSeriaNr = RegExp(
    r'\bseria\s+([A-Z]{1,4}(?:\/[A-Za-z0-9]{1,6}){1,4})\s+nr\.?\s*(\d{4,15})\b',
    caseSensitive: false,
  );
  static final RegExp _policyNumberLabel = RegExp(
    r'\bserie\s*(?:și|si)?\s*num[aă]r\b|\bnr\.?\s*poli[țt][aă]\b|\bseria\s*/?\s*num[aă]rul?\s*poli[țt]ei\b',
    caseSensitive: false,
  );
  static final RegExp _policyNumberValue = RegExp(r'^[A-Z0-9][A-Z0-9\-\/]{3,20}$', caseSensitive: false);

  /// "Valabilitate Contract de la {dată} până la {dată}" — fraza standard de
  /// pe contractele RCA (verificat pe o poliță reală); "de la"/"până la" pot
  /// apărea pe același rând, deci data e căutată DUPĂ poziția etichetei, nu
  /// doar prima dată găsită pe rând (altfel eticheta de expirare ar prelua
  /// greșit data de început).
  static final RegExp _startDateLabel = RegExp(
    r'valabil\w*\s*(?:contract\s*)?de\s*la\b|data\s*(?:de\s*)?(?:început|inceput)ii?\b|inceput\s*valabilitate',
    caseSensitive: false,
  );
  // Clasele de caractere de mai jos includ â/å/ã/ä (nu doar â) fiindcă OCR-ul
  // confundă des diacriticele — verificat pe o poliță reală, unde "până" a
  // fost recunoscut ca "pånă" (å în loc de â); fără toleranța asta eticheta
  // de expirare nu se potrivea deloc și data rămânea necompletată.
  static final RegExp _expiryDateLabel = RegExp(
    r'p[aàáâãäå]n[aàáâãäåă]\s*la\b|data\s*expir[aă]rii\b|sf[aâ]r[șs]it\s*valabilitate',
    caseSensitive: false,
  );
  static final RegExp _datePattern = RegExp(r'\b(\d{1,2})[.\/](\d{1,2})[.\/](\d{4})\b');

  /// Fallback pentru Cartea Verde (formatul internațional standardizat
  /// BAAR, prezent pe toate polițele RCA din România): data e tipărită pe
  /// coloane separate Ziua/Luna/Anul de două ori la rând (început, apoi
  /// expirare), nu ca text compact "dd.mm.yyyy" — caută 6 numere apropiate
  /// lângă cuvântul "valabil" ca ultimă soluție, dacă etichetele de mai sus
  /// n-au găsit nimic.
  static final RegExp _greenCardDatesPattern = RegExp(
    r'\b(\d{1,2})\D{1,4}(\d{1,2})\D{1,4}(\d{4})\D{1,15}(\d{1,2})\D{1,4}(\d{1,2})\D{1,4}(\d{4})\b',
  );

  DateTime? _parseDate(String raw) {
    final m = _datePattern.firstMatch(raw);
    if (m == null) return null;
    final day = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    final year = int.tryParse(m.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  /// Funcție pură de parsare a textului recunoscut pe prima pagină a unei
  /// polițe RCA/CASCO — separată de OCR ca să poată fi testată cu text
  /// simulat, la fel ca [parseTalonText].
  ScannedRcaData parseRcaText(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    String? provider;
    for (final candidate in _knownInsurers) {
      final regex = RegExp(RegExp.escape(candidate), caseSensitive: false);
      if (regex.hasMatch(rawText)) {
        provider = candidate;
        break;
      }
    }
    if (provider == null) {
      for (var i = 0; i < lines.length; i++) {
        final m = _providerLabel.firstMatch(lines[i]);
        if (m == null) continue;
        var rest = lines[i].substring(m.end).trim();
        if (rest.isEmpty && i + 1 < lines.length) rest = lines[i + 1].trim();
        final cutMatch = _providerCutMarker.firstMatch(rest);
        if (cutMatch != null) rest = rest.substring(0, cutMatch.start).trim();
        if (rest.isNotEmpty && rest.length <= 80) provider = rest;
        break;
      }
    }
    // Fallback pozițional: unii asigurători (verificat pe o poliță reală
    // Anytime/Interamerican Hellenic) nu au deloc eticheta „DENUMIRE
    // ASIGURĂTOR:" — numele apare direct pe rândul de după antetul
    // "CONTRACT DE ASIGURARE DE RĂSPUNDERE CIVILĂ AUTO RCA".
    if (provider == null) {
      final headerIdx =
          lines.indexWhere((l) => RegExp(r'contract\s+de\s+asigurare', caseSensitive: false).hasMatch(l));
      if (headerIdx != -1 && headerIdx + 1 < lines.length) {
        var candidate = lines[headerIdx + 1];
        final labelMatch = _providerLabel.firstMatch(candidate);
        if (labelMatch != null) candidate = candidate.substring(labelMatch.end);
        final cutMatch = _providerCutMarker.firstMatch(candidate);
        if (cutMatch != null) candidate = candidate.substring(0, cutMatch.start);
        candidate = candidate.trim();
        if (candidate.isNotEmpty && candidate.length <= 80) provider = candidate;
      }
    }

    String? policyNumber;
    final seriaNrMatch = _policyNumberSeriaNr.firstMatch(rawText);
    if (seriaNrMatch != null) {
      policyNumber = '${seriaNrMatch.group(1)} ${seriaNrMatch.group(2)}'.toUpperCase();
    } else {
      for (var i = 0; i < lines.length; i++) {
        if (!_policyNumberLabel.hasMatch(lines[i])) continue;
        final sameLine = lines[i].replaceFirst(_policyNumberLabel, '').replaceFirst(RegExp(r'^[:\-\s]+'), '').trim();
        if (_policyNumberValue.hasMatch(sameLine)) {
          policyNumber = sameLine.toUpperCase();
        } else if (i + 1 < lines.length && _policyNumberValue.hasMatch(lines[i + 1])) {
          policyNumber = lines[i + 1].toUpperCase();
        }
        break;
      }
    }

    DateTime? startDate;
    DateTime? expiryDate;
    int? expiryLineIndex;
    int? expiryLabelStart;
    for (var i = 0; i < lines.length; i++) {
      final startMatch = _startDateLabel.firstMatch(lines[i]);
      if (startDate == null && startMatch != null) {
        startDate = _parseDate(lines[i].substring(startMatch.end)) ??
            (i + 1 < lines.length ? _parseDate(lines[i + 1]) : null);
      }
      final expiryMatch = _expiryDateLabel.firstMatch(lines[i]);
      if (expiryDate == null && expiryMatch != null) {
        expiryDate = _parseDate(lines[i].substring(expiryMatch.end)) ??
            (i + 1 < lines.length ? _parseDate(lines[i + 1]) : null);
        if (expiryDate != null) {
          expiryLineIndex = i;
          expiryLabelStart = expiryMatch.start;
        }
      }
    }

    // "{dată} până la {dată}" — dacă eticheta de început ("Valabilitate...de
    // la") nu s-a potrivit (cuvânt lung, predispus la erori OCR — verificat
    // pe o a doua poliță reală, unde doar eticheta de expirare a fost
    // recunoscută), ultima dată găsită ÎNAINTE de eticheta "până la" pe
    // același rând e aproape sigur data de început, indiferent dacă "de la"
    // a supraviețuit OCR-ului sau nu.
    if (startDate == null && expiryLineIndex != null && expiryLabelStart != null) {
      final before = lines[expiryLineIndex].substring(0, expiryLabelStart);
      final beforeMatches = _datePattern.allMatches(before);
      if (beforeMatches.isNotEmpty) {
        startDate = _parseDate(beforeMatches.last.group(0)!);
      }
    }

    // Fallback Cartea Verde: 6 numere apropiate (ziua/luna/anul repetat de
    // două ori) lângă cuvântul "valabil" — vezi comentariul de la
    // [_greenCardDatesPattern].
    if (startDate == null && expiryDate == null) {
      final keywordIdx = RegExp(r'valabil', caseSensitive: false).firstMatch(rawText)?.start;
      if (keywordIdx != null) {
        final windowEnd = keywordIdx + 600 > rawText.length ? rawText.length : keywordIdx + 600;
        final window = rawText.substring(keywordIdx, windowEnd);
        final m = _greenCardDatesPattern.firstMatch(window);
        if (m != null) {
          final d1 = int.tryParse(m.group(1)!);
          final mo1 = int.tryParse(m.group(2)!);
          final y1 = int.tryParse(m.group(3)!);
          final d2 = int.tryParse(m.group(4)!);
          final mo2 = int.tryParse(m.group(5)!);
          final y2 = int.tryParse(m.group(6)!);
          if (d1 != null && mo1 != null && y1 != null && d2 != null && mo2 != null && y2 != null &&
              mo1 >= 1 && mo1 <= 12 && mo2 >= 1 && mo2 <= 12 && d1 >= 1 && d1 <= 31 && d2 >= 1 && d2 <= 31) {
            startDate = DateTime(y1, mo1, d1);
            expiryDate = DateTime(y2, mo2, d2);
          }
        }
      }
    }

    // Fără etichete recunoscute: dacă apar exact 2 date în tot textul,
    // presupunem că sunt începutul/sfârșitul valabilității (cea mai mică →
    // start, cea mai mare → expiry) — fallback slab, dar mai bun decât nimic.
    if (startDate == null && expiryDate == null) {
      final allDates = _datePattern.allMatches(rawText).map((m) => _parseDate(m.group(0)!)).whereType<DateTime>().toSet().toList();
      if (allDates.length == 2) {
        allDates.sort();
        startDate = allDates.first;
        expiryDate = allDates.last;
      }
    }

    return ScannedRcaData(
      provider: provider,
      policyNumber: policyNumber,
      startDate: startDate,
      expiryDate: expiryDate,
      rawText: rawText,
    );
  }

  /// Randează prima pagină a PDF-ului ca imagine și rulează același OCR
  /// folosit pentru talon. Doar pagina 0 e citită — polițele RCA/CASCO pun
  /// asigurătorul, seria poliței și valabilitatea pe prima pagină, deci e un
  /// compromis rezonabil, nu o limitare care blochează funcționalitatea.
  /// Best-effort: orice eroare (PDF corupt, randare eșuată, OCR indisponibil)
  /// întoarce `null` în loc să propage excepția — atașarea PDF-ului rămâne
  /// validă indiferent de rezultatul extracției.
  Future<ScannedRcaData?> scanRcaPdf(String pdfPath) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      final page = await Printing.raster(bytes, pages: const [0], dpi: 150).first;

      // Printing.raster returns RGBA pixels with a TRANSPARENT background
      // (the PDF page itself has no opaque white fill) — passed as-is to
      // ML Kit, the transparent background decodes as black, making dark
      // text on it unreadable and OCR returns 0 characters (verified on a
      // real device). Flatten onto an opaque white canvas first so it looks
      // like a normal scanned page.
      final rawImage = await page.toImage();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final size = ui.Size(rawImage.width.toDouble(), rawImage.height.toDouble());
      canvas.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
      canvas.drawImage(rawImage, ui.Offset.zero, ui.Paint());
      final flattened = await recorder.endRecording().toImage(rawImage.width, rawImage.height);
      final byteData = await flattened.toByteData(format: ui.ImageByteFormat.png);
      final png = byteData!.buffer.asUint8List();

      final tmpDir = await getTemporaryDirectory();
      final tmpPath = '${tmpDir.path}/rca_ocr_${DateTime.now().microsecondsSinceEpoch}.png';
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(png);

      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final inputImage = InputImage.fromFilePath(tmpPath);
        final result = await recognizer.processImage(inputImage);
        return parseRcaText(result.text);
      } finally {
        await recognizer.close();
        if (await tmpFile.exists()) await tmpFile.delete();
      }
    } catch (_) {
      return null;
    }
  }
}
