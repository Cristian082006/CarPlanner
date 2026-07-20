import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import 'constants.dart';

/// RAR (ITP), AIDA/BAAR (RCA) și CNAIR (Rovinietă) au toate un CAPTCHA
/// obligatoriu pe formularul public de verificare — nu poate fi completat
/// automat de aplicație. În loc să scraping-uim, deschidem pagina oficială
/// corectă în browser și copiem în clipboard identificatorul cerut (nr.
/// înmatriculare sau VIN), astfel încât utilizatorul doar rezolvă CAPTCHA-ul
/// și lipește valoarea; data găsită se introduce manual înapoi în document.
bool hasOfficialVerification(DocumentType type) {
  return type == DocumentType.rca ||
      type == DocumentType.rovinieta ||
      type == DocumentType.itp;
}

class _VerificationTarget {
  final String url;
  final String? clipboardLabel;
  final String? clipboardValue;
  final String? extraNote;

  const _VerificationTarget({
    required this.url,
    this.clipboardLabel,
    this.clipboardValue,
    this.extraNote,
  });
}

_VerificationTarget? _targetFor(
  DocumentType type, {
  String? plateNumber,
  String? vin,
}) {
  final plate = plateNumber?.replaceAll(' ', '').toUpperCase();
  switch (type) {
    case DocumentType.rca:
      return _VerificationTarget(
        url: 'https://www.aida.info.ro/polite-rca',
        clipboardLabel: S.plateNumberLabel,
        clipboardValue: (plate?.isNotEmpty ?? false) ? plate : null,
      );
    case DocumentType.itp:
      return _VerificationTarget(
        url: 'https://prog.rarom.ro/rarpol/',
        clipboardLabel: S.vinLabel,
        clipboardValue: (vin?.isNotEmpty ?? false) ? vin : null,
      );
    case DocumentType.rovinieta:
      return _VerificationTarget(
        url: 'https://www.cnadnr.ro/ro/verificare-rovinieta',
        clipboardLabel: S.plateNumberLabel,
        clipboardValue: (plate?.isNotEmpty ?? false) ? plate : null,
        extraNote: (vin?.isNotEmpty ?? false) ? S.verificationAlsoNeedsVin(vin!) : null,
      );
    default:
      return null;
  }
}

/// Deschide pagina oficială de verificare pentru [type] și copiază în
/// clipboard identificatorul necesar, dacă e disponibil. Nu completează și
/// nu ocolește CAPTCHA-ul — utilizatorul finalizează verificarea manual.
Future<void> verifyDocumentOnOfficialSite(
  BuildContext context, {
  required DocumentType type,
  String? plateNumber,
  String? vin,
}) async {
  final target = _targetFor(type, plateNumber: plateNumber, vin: vin);
  if (target == null) return;
  final messenger = ScaffoldMessenger.of(context);

  String message;
  if (target.clipboardValue != null) {
    await Clipboard.setData(ClipboardData(text: target.clipboardValue!));
    message = S.verificationValueCopied(target.clipboardLabel!, target.clipboardValue!);
    if (target.extraNote != null) message = '$message ${target.extraNote}';
  } else {
    message = S.verificationValueMissing(target.clipboardLabel!);
  }

  final launched = await launchUrl(Uri.parse(target.url), mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  messenger.showSnackBar(SnackBar(content: Text(launched ? message : S.verificationLaunchFailed)));
}
