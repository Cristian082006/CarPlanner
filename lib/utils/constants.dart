import 'package:flutter/material.dart';

import '../services/region_service.dart';

enum DocumentType {
  rca,
  casco,
  rovinieta,
  itp,
  homeInsurance,
  propertyTax,
  heatingInspection,
  gasCheck,
  other,
}

/// Tipuri de document care nu țin de o mașină anume (secțiunea „Casă” de pe
/// ecranul principal) — folosit de `requiresVehicle` mai jos.
const Set<DocumentType> _nonVehicleDocumentTypes = {
  DocumentType.homeInsurance,
  DocumentType.propertyTax,
  DocumentType.heatingInspection,
  DocumentType.gasCheck,
};

extension DocumentTypeX on DocumentType {
  /// România păstrează denumirile locale (RCA/CASCO/ITP/Rovinietă); orice
  /// altă țară selectată în Setări primește denumiri generice, în engleză.
  String get label {
    final isRomania = RegionService.instance.isRomania;
    switch (this) {
      case DocumentType.rca:
        return isRomania ? 'RCA' : 'Liability Insurance';
      case DocumentType.casco:
        return isRomania ? 'CASCO' : 'Comprehensive Insurance';
      case DocumentType.rovinieta:
        return isRomania ? 'Rovinietă' : 'Road Toll';
      case DocumentType.itp:
        return isRomania ? 'ITP' : 'Technical Inspection';
      case DocumentType.homeInsurance:
        return isRomania ? 'Asigurare locuință' : 'Home Insurance';
      case DocumentType.propertyTax:
        return isRomania ? 'Impozit clădire/teren' : 'Property Tax';
      case DocumentType.heatingInspection:
        return isRomania
            ? 'Revizie centrală termică / coș de fum'
            : 'Heating System / Chimney Inspection';
      case DocumentType.gasCheck:
        return isRomania ? 'Verificare instalație gaz' : 'Gas Installation Check';
      case DocumentType.other:
        return isRomania ? 'Alt document' : 'Other Document';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.rca:
      case DocumentType.casco:
        return Icons.shield_outlined;
      case DocumentType.rovinieta:
        return Icons.route_outlined;
      case DocumentType.itp:
        return Icons.fact_check_outlined;
      case DocumentType.homeInsurance:
        return Icons.home_outlined;
      case DocumentType.propertyTax:
        return Icons.account_balance_outlined;
      case DocumentType.heatingInspection:
        return Icons.local_fire_department_outlined;
      case DocumentType.gasCheck:
        return Icons.gas_meter_outlined;
      case DocumentType.other:
        return Icons.description_outlined;
    }
  }

  bool get requiresVehicle => !_nonVehicleDocumentTypes.contains(this);

  static DocumentType fromName(String name) {
    return DocumentType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => DocumentType.other,
    );
  }
}

/// Zile înainte de expirare la care se trimite o notificare de atenționare.
const List<int> reminderLeadDays = [14, 3];

const Color kDangerColor = Color(0xFFD62828);
const Color kWarningColor = Color(0xFFF77F00);
const Color kOkColor = Color(0xFF2D6A4F);
