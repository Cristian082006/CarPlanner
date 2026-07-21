library;

/// Decodare best-effort a VIN-ului (serie șasiu), limitată la ce e cu
/// adevărat standardizat universal prin ISO 3779: WMI (poziții 1-3, →
/// producător) și codul anului de fabricație (poziția 10). Restul VIN-ului
/// (poziții 4-8, care ar codifica motorul/caroseria) e specific fiecărui
/// producător și nu avem tabelele lor proprietare — de aceea NU încercăm să
/// extragem un cod de motor direct din caractere. În schimb, WMI-ul (marca)
/// și anul decodat sunt folosite ca filtru pentru catalogul de motoare din
/// `vehicle_reference_data.dart` (`getCandidateEnginesForVin` în
/// `database_helper.dart`), iar utilizatorul alege motorul potrivit dintr-o
/// listă de candidați — nu ghicim.
class VinDecodeResult {
  final bool validFormat;
  final String? wmi;
  final String? detectedMake;
  final int? modelYear;

  const VinDecodeResult({
    required this.validFormat,
    this.wmi,
    this.detectedMake,
    this.modelYear,
  });
}

final RegExp _vinFormat = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

bool isValidVinFormat(String vin) => _vinFormat.hasMatch(vin.trim().toUpperCase());

/// Prefixe WMI cunoscute pentru mărcile prezente în catalogul static
/// (`vehicle_reference_data.dart`). Neexhaustiv — acoperă în principal
/// uzinele europene, relevante pentru piața din România; multe mărci au
/// zeci de coduri WMI regionale (SUA, Mexic, China etc.) neincluse aici.
const Map<String, String> _wmiToMake = {
  'UU1': 'Dacia',
  'VF1': 'Renault',
  'VF6': 'Renault',
  'VF3': 'Peugeot',
  'WVW': 'Volkswagen',
  'WV1': 'Volkswagen',
  'WV2': 'Volkswagen',
  '3VW': 'Volkswagen',
  'WAU': 'Audi',
  'TRU': 'Audi',
  'WBA': 'BMW',
  'WBS': 'BMW',
  'WBY': 'BMW',
  'WBX': 'BMW',
  'WDB': 'Mercedes-Benz',
  'WDD': 'Mercedes-Benz',
  'WDC': 'Mercedes-Benz',
  'TMB': 'Skoda',
  'WF0': 'Ford',
  'VS6': 'Ford',
  'W0L': 'Opel',
  'W0V': 'Opel',
  'JTD': 'Toyota',
  'JTE': 'Toyota',
  'JTG': 'Toyota',
  'JTN': 'Toyota',
  'SB1': 'Toyota',
  'VNK': 'Toyota',
  'JHM': 'Honda',
  'KMH': 'Hyundai',
  'TMA': 'Hyundai',
  'KNA': 'Kia',
  'U5Y': 'Kia',
  'YV1': 'Volvo',
  'ZFA': 'Fiat',
  'VSS': 'Seat',
  '5YJ': 'Tesla',
};

/// Ordinea codurilor de an ISO 3779, poziția 10 din VIN (fără I, O, Q, U, Z, 0).
const List<String> _yearCodeOrder = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'R',
  'S', 'T', 'V', 'W', 'X', 'Y', '1', '2', '3', '4', '5', '6', '7', '8', '9',
];

/// Codul se repetă la fiecare 30 de ani (ambiguitate cunoscută din standard),
/// deci alegem ciclul cel mai recent care nu depășește [referenceYear] + 1
/// (permite anul-model următor, uzual pentru mașini noi).
int? _decodeModelYear(String vin, {required int referenceYear}) {
  final code = vin[9].toUpperCase();
  final offset = _yearCodeOrder.indexOf(code);
  if (offset == -1) return null;
  final recentCycle = 2010 + offset;
  if (recentCycle <= referenceYear + 1) return recentCycle;
  return 1980 + offset;
}

VinDecodeResult decodeVin(String rawVin, {int? referenceYear}) {
  final vin = rawVin.trim().toUpperCase();
  if (!_vinFormat.hasMatch(vin)) {
    return const VinDecodeResult(validFormat: false);
  }
  final wmi = vin.substring(0, 3);
  return VinDecodeResult(
    validFormat: true,
    wmi: wmi,
    detectedMake: _wmiToMake[wmi],
    modelYear: _decodeModelYear(vin, referenceYear: referenceYear ?? DateTime.now().year),
  );
}
