/// Profiluri de mentenanță generale — intervale tipice orientative de schimb
/// ulei motor/filtru ulei, pe model (cu fallback pe marcă dacă modelul nu e
/// recunoscut).
///
/// **Nu sunt date oficiale de constructor per motorizare exactă** — pentru
/// multe modele din aceeași generație/marcă, intervalul real oficial e
/// identic (motoarele sunt împărțite între modele), așa că valorile de mai
/// jos sunt estimate mai ales pe segment (oraș/compact/SUV/premium) în
/// interiorul intervalului "10.000–20.000 km sau 1 an" folosit practic în
/// România, nu pe diferențe reale documentate per nume de model. Afișează
/// mereu disclaimer-ul din UI când sunt folosite — nu prezenta asta ca fiind
/// mai precis decât e.
class ModelMaintenanceProfile {
  final String displayName;
  final int? engineOilIntervalKm;
  final int? engineOilIntervalMonths;

  const ModelMaintenanceProfile({
    required this.displayName,
    this.engineOilIntervalKm,
    this.engineOilIntervalMonths,
  });
}

class MakeMaintenanceProfile {
  final String displayName;
  final int? engineOilIntervalKm;
  final int? engineOilIntervalMonths;

  const MakeMaintenanceProfile({
    required this.displayName,
    this.engineOilIntervalKm,
    this.engineOilIntervalMonths,
  });
}

class ResolvedMaintenanceProfile {
  final String displayName;
  final int? engineOilIntervalKm;
  final int? engineOilIntervalMonths;

  const ResolvedMaintenanceProfile({
    required this.displayName,
    this.engineOilIntervalKm,
    this.engineOilIntervalMonths,
  });
}

/// Componente adăugate mereu, indiferent de marcă, atunci când se aplică un
/// profil de mentenanță — sunt verificări comune lipsă din lista esențială
/// implicită, nu specifice unei mărci anume.
const List<String> universalExtraComponentIds = ['transmission_fluid', 'wiper_blades'];

/// Sub acest an considerăm mașina "veche" — fără ulei longlife pe scară
/// largă în Europa (conceptul a devenit uzual abia din ~2000) — și folosim un
/// interval conservator universal, indiferent de marcă/model găsit.
const int _oldVehicleYearThreshold = 2000;
const _oldVehicleProfile = ResolvedMaintenanceProfile(
  displayName: 'mașină veche (fără ulei longlife)',
  engineOilIntervalKm: 8000,
  engineOilIntervalMonths: 8,
);

// ---------- Profiluri pe marcă (fallback dacă modelul nu e recunoscut) ----------

const _dacia = MakeMaintenanceProfile(displayName: 'Dacia', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12);
const _renault = MakeMaintenanceProfile(displayName: 'Renault', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12);
const _vw = MakeMaintenanceProfile(displayName: 'Volkswagen', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12);
const _skoda = MakeMaintenanceProfile(displayName: 'Škoda', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12);
const _seat = MakeMaintenanceProfile(displayName: 'Seat', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12);
const _audi = MakeMaintenanceProfile(displayName: 'Audi', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12);
const _bmw = MakeMaintenanceProfile(displayName: 'BMW', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12);
const _mercedes = MakeMaintenanceProfile(displayName: 'Mercedes-Benz', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12);
const _toyota = MakeMaintenanceProfile(displayName: 'Toyota', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12);
const _hyundai = MakeMaintenanceProfile(displayName: 'Hyundai', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12);
const _kia = MakeMaintenanceProfile(displayName: 'Kia', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12);
const _ford = MakeMaintenanceProfile(displayName: 'Ford', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12);
const _opel = MakeMaintenanceProfile(displayName: 'Opel', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12);
const _peugeot = MakeMaintenanceProfile(displayName: 'Peugeot', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12);
const _citroen = MakeMaintenanceProfile(displayName: 'Citroën', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12);
const _fiat = MakeMaintenanceProfile(displayName: 'Fiat', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12);
const _honda = MakeMaintenanceProfile(displayName: 'Honda', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12);
const _nissan = MakeMaintenanceProfile(displayName: 'Nissan', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12);

/// Cheile sunt normalizate: minuscule, fără spații/liniuțe.
const Map<String, MakeMaintenanceProfile> makeMaintenanceProfiles = {
  'dacia': _dacia,
  'renault': _renault,
  'volkswagen': _vw,
  'vw': _vw,
  'skoda': _skoda,
  'seat': _seat,
  'audi': _audi,
  'bmw': _bmw,
  'mercedes': _mercedes,
  'mercedesbenz': _mercedes,
  'toyota': _toyota,
  'lexus': _toyota,
  'hyundai': _hyundai,
  'kia': _kia,
  'ford': _ford,
  'opel': _opel,
  'vauxhall': _opel,
  'peugeot': _peugeot,
  'citroen': _citroen,
  'citroën': _citroen,
  'fiat': _fiat,
  'honda': _honda,
  'nissan': _nissan,
};

// ---------- Profiluri pe model (cheia exterioară = cheia mărcii de mai sus) ----------

const _daciaModels = {
  'logan': ModelMaintenanceProfile(displayName: 'Dacia Logan', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'sandero': ModelMaintenanceProfile(displayName: 'Dacia Sandero', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'duster': ModelMaintenanceProfile(displayName: 'Dacia Duster', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'jogger': ModelMaintenanceProfile(displayName: 'Dacia Jogger', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'dokker': ModelMaintenanceProfile(displayName: 'Dacia Dokker', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
};
const _renaultModels = {
  'clio': ModelMaintenanceProfile(displayName: 'Renault Clio', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'megane': ModelMaintenanceProfile(displayName: 'Renault Megane', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'captur': ModelMaintenanceProfile(displayName: 'Renault Captur', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'scenic': ModelMaintenanceProfile(displayName: 'Renault Scenic', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'kadjar': ModelMaintenanceProfile(displayName: 'Renault Kadjar', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
};
const _vwModels = {
  'polo': ModelMaintenanceProfile(displayName: 'Volkswagen Polo', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'golf': ModelMaintenanceProfile(displayName: 'Volkswagen Golf', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'passat': ModelMaintenanceProfile(displayName: 'Volkswagen Passat', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'tiguan': ModelMaintenanceProfile(displayName: 'Volkswagen Tiguan', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'touran': ModelMaintenanceProfile(displayName: 'Volkswagen Touran', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
};
const _skodaModels = {
  'fabia': ModelMaintenanceProfile(displayName: 'Škoda Fabia', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'octavia': ModelMaintenanceProfile(displayName: 'Škoda Octavia', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'superb': ModelMaintenanceProfile(displayName: 'Škoda Superb', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'kodiaq': ModelMaintenanceProfile(displayName: 'Škoda Kodiaq', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'kamiq': ModelMaintenanceProfile(displayName: 'Škoda Kamiq', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
};
const _seatModels = {
  'ibiza': ModelMaintenanceProfile(displayName: 'Seat Ibiza', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'leon': ModelMaintenanceProfile(displayName: 'Seat Leon', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'ateca': ModelMaintenanceProfile(displayName: 'Seat Ateca', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
};
const _audiModels = {
  'a1': ModelMaintenanceProfile(displayName: 'Audi A1', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'a3': ModelMaintenanceProfile(displayName: 'Audi A3', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'a4': ModelMaintenanceProfile(displayName: 'Audi A4', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'a6': ModelMaintenanceProfile(displayName: 'Audi A6', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'q3': ModelMaintenanceProfile(displayName: 'Audi Q3', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'q5': ModelMaintenanceProfile(displayName: 'Audi Q5', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
};
const _bmwModels = {
  'seria1': ModelMaintenanceProfile(displayName: 'BMW Seria 1', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'seria3': ModelMaintenanceProfile(displayName: 'BMW Seria 3', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'seria5': ModelMaintenanceProfile(displayName: 'BMW Seria 5', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'x1': ModelMaintenanceProfile(displayName: 'BMW X1', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'x3': ModelMaintenanceProfile(displayName: 'BMW X3', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'x5': ModelMaintenanceProfile(displayName: 'BMW X5', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
};
const _mercedesModels = {
  'clasaa': ModelMaintenanceProfile(displayName: 'Mercedes-Benz Clasa A', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'clasac': ModelMaintenanceProfile(displayName: 'Mercedes-Benz Clasa C', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'clasae': ModelMaintenanceProfile(displayName: 'Mercedes-Benz Clasa E', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'glc': ModelMaintenanceProfile(displayName: 'Mercedes-Benz GLC', engineOilIntervalKm: 20000, engineOilIntervalMonths: 12),
  'gla': ModelMaintenanceProfile(displayName: 'Mercedes-Benz GLA', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
};
const _toyotaModels = {
  'aygo': ModelMaintenanceProfile(displayName: 'Toyota Aygo', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'yaris': ModelMaintenanceProfile(displayName: 'Toyota Yaris', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'corolla': ModelMaintenanceProfile(displayName: 'Toyota Corolla', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'chr': ModelMaintenanceProfile(displayName: 'Toyota C-HR', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'rav4': ModelMaintenanceProfile(displayName: 'Toyota RAV4', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
};
const _hyundaiModels = {
  'i10': ModelMaintenanceProfile(displayName: 'Hyundai i10', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'i20': ModelMaintenanceProfile(displayName: 'Hyundai i20', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'i30': ModelMaintenanceProfile(displayName: 'Hyundai i30', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'kona': ModelMaintenanceProfile(displayName: 'Hyundai Kona', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
  'tucson': ModelMaintenanceProfile(displayName: 'Hyundai Tucson', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
};
const _kiaModels = {
  'picanto': ModelMaintenanceProfile(displayName: 'Kia Picanto', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'rio': ModelMaintenanceProfile(displayName: 'Kia Rio', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'ceed': ModelMaintenanceProfile(displayName: 'Kia Ceed', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'sportage': ModelMaintenanceProfile(displayName: 'Kia Sportage', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
};
const _fordModels = {
  'ka': ModelMaintenanceProfile(displayName: 'Ford Ka', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
  'fiesta': ModelMaintenanceProfile(displayName: 'Ford Fiesta', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
  'focus': ModelMaintenanceProfile(displayName: 'Ford Focus', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'puma': ModelMaintenanceProfile(displayName: 'Ford Puma', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'kuga': ModelMaintenanceProfile(displayName: 'Ford Kuga', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
};
const _opelModels = {
  'corsa': ModelMaintenanceProfile(displayName: 'Opel Corsa', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'astra': ModelMaintenanceProfile(displayName: 'Opel Astra', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'insignia': ModelMaintenanceProfile(displayName: 'Opel Insignia', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'mokka': ModelMaintenanceProfile(displayName: 'Opel Mokka', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
  'crossland': ModelMaintenanceProfile(displayName: 'Opel Crossland', engineOilIntervalKm: 18000, engineOilIntervalMonths: 12),
};
const _peugeotModels = {
  '208': ModelMaintenanceProfile(displayName: 'Peugeot 208', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  '308': ModelMaintenanceProfile(displayName: 'Peugeot 308', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  '2008': ModelMaintenanceProfile(displayName: 'Peugeot 2008', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  '3008': ModelMaintenanceProfile(displayName: 'Peugeot 3008', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
};
const _citroenModels = {
  'c3': ModelMaintenanceProfile(displayName: 'Citroën C3', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'c4': ModelMaintenanceProfile(displayName: 'Citroën C4', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'berlingo': ModelMaintenanceProfile(displayName: 'Citroën Berlingo', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
};
const _fiatModels = {
  'panda': ModelMaintenanceProfile(displayName: 'Fiat Panda', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
  '500': ModelMaintenanceProfile(displayName: 'Fiat 500', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
  'tipo': ModelMaintenanceProfile(displayName: 'Fiat Tipo', engineOilIntervalKm: 15000, engineOilIntervalMonths: 12),
  'punto': ModelMaintenanceProfile(displayName: 'Fiat Punto', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
};
const _hondaModels = {
  'jazz': ModelMaintenanceProfile(displayName: 'Honda Jazz', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'civic': ModelMaintenanceProfile(displayName: 'Honda Civic', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
  'crv': ModelMaintenanceProfile(displayName: 'Honda CR-V', engineOilIntervalKm: 10000, engineOilIntervalMonths: 12),
};
const _nissanModels = {
  'micra': ModelMaintenanceProfile(displayName: 'Nissan Micra', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
  'qashqai': ModelMaintenanceProfile(displayName: 'Nissan Qashqai', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
  'juke': ModelMaintenanceProfile(displayName: 'Nissan Juke', engineOilIntervalKm: 12000, engineOilIntervalMonths: 12),
};

/// Cheia exterioară trebuie să fie una dintre cheile din
/// [makeMaintenanceProfiles] (aceeași normalizare: minuscule, fără
/// spații/liniuțe). Modelele nelistate aici pică pe profilul mărcii.
const Map<String, Map<String, ModelMaintenanceProfile>> makeModelProfiles = {
  'dacia': _daciaModels,
  'renault': _renaultModels,
  'volkswagen': _vwModels,
  'vw': _vwModels,
  'skoda': _skodaModels,
  'seat': _seatModels,
  'audi': _audiModels,
  'bmw': _bmwModels,
  'mercedes': _mercedesModels,
  'mercedesbenz': _mercedesModels,
  'toyota': _toyotaModels,
  'hyundai': _hyundaiModels,
  'kia': _kiaModels,
  'ford': _fordModels,
  'opel': _opelModels,
  'vauxhall': _opelModels,
  'peugeot': _peugeotModels,
  'citroen': _citroenModels,
  'citroën': _citroenModels,
  'fiat': _fiatModels,
  'honda': _hondaModels,
  'nissan': _nissanModels,
};

String _normalize(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');

/// Rezolvă profilul de mentenanță pe **model/marcă** — folosit doar ca
/// fallback când codul de motor nu e completat sau nu are rânduri în
/// `maintenance_intervals` (tabelă seedată din `vehicle_reference_data.dart`,
/// interogată separat, înainte de asta, în `vehicle_detail_screen.dart`).
/// Mașinile de dinainte de anul 2000 primesc profilul conservator pentru
/// mașini vechi, indiferent de ce urmează → potrivire pe model (în
/// interiorul mărcii găsite) → fallback pe marcă → null dacă nimic nu se
/// potrivește.
ResolvedMaintenanceProfile? resolveMaintenanceProfile({
  required String make,
  required String model,
  int? year,
}) {
  if (year != null && year < _oldVehicleYearThreshold) return _oldVehicleProfile;

  final normalizedMake = _normalize(make);
  if (normalizedMake.isEmpty) return null;

  String? matchedMakeKey = makeMaintenanceProfiles.containsKey(normalizedMake) ? normalizedMake : null;
  matchedMakeKey ??= makeMaintenanceProfiles.keys
      .cast<String?>()
      .firstWhere((key) => normalizedMake.contains(key!), orElse: () => null);
  if (matchedMakeKey == null) return null;
  final makeProfile = makeMaintenanceProfiles[matchedMakeKey]!;

  final normalizedModel = _normalize(model);
  final modelsForMake = makeModelProfiles[matchedMakeKey];
  if (normalizedModel.isNotEmpty && modelsForMake != null) {
    final exactModel = modelsForMake[normalizedModel];
    if (exactModel != null) {
      return ResolvedMaintenanceProfile(
        displayName: exactModel.displayName,
        engineOilIntervalKm: exactModel.engineOilIntervalKm,
        engineOilIntervalMonths: exactModel.engineOilIntervalMonths,
      );
    }
    for (final entry in modelsForMake.entries) {
      if (normalizedModel.contains(entry.key)) {
        return ResolvedMaintenanceProfile(
          displayName: entry.value.displayName,
          engineOilIntervalKm: entry.value.engineOilIntervalKm,
          engineOilIntervalMonths: entry.value.engineOilIntervalMonths,
        );
      }
    }
  }

  return ResolvedMaintenanceProfile(
    displayName: makeProfile.displayName,
    engineOilIntervalKm: makeProfile.engineOilIntervalKm,
    engineOilIntervalMonths: makeProfile.engineOilIntervalMonths,
  );
}
