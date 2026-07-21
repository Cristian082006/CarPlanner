library;

import '../db/database_helper.dart';
import 'vin_decoder.dart';

/// Cât de restrânsă a fost căutarea care a produs [EngineCandidatesResult.candidates]
/// — determină titlul dialogului și dacă se arată avertismentul de
/// nepotrivire pe an (vezi `showEngineCandidatesDialog`).
enum EngineMatchTier {
  /// Marcă + model + an — potrivire exactă.
  exact,

  /// Marcă + model, orice an — modelul a fost completat dar anul VIN-ului nu
  /// se încadrează în nicio generație din catalog.
  model,

  /// Doar marcă — modelul nu a fost completat sau nu există deloc în catalog.
  make,
}

class EngineCandidatesResult {
  final List<Map<String, Object?>> candidates;
  final EngineMatchTier tier;
  final int? modelYear;
  final String? detectedMake;

  const EngineCandidatesResult({
    required this.candidates,
    required this.tier,
    this.modelYear,
    this.detectedMake,
  });

  bool get isExactMatch => tier == EngineMatchTier.exact;
}

/// Decodifică [vin] și caută motoare candidate în catalog pentru [make]/
/// [model], cu aceeași cascadă de restrângere folosită la decodarea VIN din
/// ecranul de adăugare/editare mașină: marcă+model+an → marcă+model (orice
/// an, doar dacă modelul a fost completat — nu lărgim la toată marca dacă
/// utilizatorul chiar a specificat un model care pur și simplu nu e în
/// catalog, ar arăta motoare de la alte modele care par corecte dar nu sunt)
/// → doar marcă (ultimă opțiune, doar când modelul lipsește).
Future<EngineCandidatesResult> resolveEngineCandidatesFromVin(
  DatabaseHelper db, {
  required String vin,
  required String make,
  required String model,
}) async {
  final decoded = decodeVin(vin);

  var candidates = await db.getCandidateEnginesForVin(
    marca: make,
    model: model,
    year: decoded.modelYear,
  );
  var tier = EngineMatchTier.exact;
  if (candidates.isEmpty && model.isNotEmpty) {
    candidates = await db.getCandidateEnginesForVin(marca: make, model: model, matchYear: false);
    tier = EngineMatchTier.model;
  } else if (candidates.isEmpty) {
    candidates = await db.getCandidateEnginesForVin(marca: make, matchModel: false, matchYear: false);
    tier = EngineMatchTier.make;
  }

  return EngineCandidatesResult(
    candidates: candidates,
    tier: tier,
    modelYear: decoded.modelYear,
    detectedMake: decoded.detectedMake,
  );
}
