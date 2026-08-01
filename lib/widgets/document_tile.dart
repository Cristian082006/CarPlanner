import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../utils/calendar_utils.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/document_verification_utils.dart';

class DocumentTile extends StatelessWidget {
  final CarDocument document;
  final String vehicleLabel;
  final String? subtitle;
  final String? plateNumber;
  final String? vin;
  final VoidCallback? onTap;

  const DocumentTile({
    super.key,
    required this.document,
    required this.vehicleLabel,
    this.subtitle,
    this.plateNumber,
    this.vin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pdfPath = document.photoPath?.toLowerCase().endsWith('.pdf') == true
        ? document.photoPath
        : null;
    final days = document.daysUntilExpiry;
    Color badgeColor;
    if (document.isExpired) {
      badgeColor = kDangerColor;
    } else if (document.isExpiringSoon) {
      badgeColor = kWarningColor;
    } else {
      badgeColor = kOkColor;
    }

    // Aspect 3D cerut explicit de utilizator, la fel ca `VehicleCard` —
    // înainte era un `ListTile` gol, plat, direct în listă.
    return Card(
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: 16,
        leading: CircleAvatar(
          backgroundColor: badgeColor.withValues(alpha: 0.15),
          child: Icon(document.type.icon, color: badgeColor),
        ),
        title: Text(document.title?.isNotEmpty == true
            ? document.title!
            : document.type.label),
        subtitle: Text(
          [
            if (subtitle != null) subtitle!,
            if (document.provider?.isNotEmpty == true) document.provider!,
            '${S.validUntil}${formatDate(document.expiryDate)}',
          ].join(' • '),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                daysUntilLabel(days),
                style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pdfPath != null)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      tooltip: S.openPdf,
                      onPressed: () async {
                        final result = await OpenFilex.open(pdfPath);
                        if (result.type != ResultType.done && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(S.openPdfFailed)));
                        }
                      },
                    ),
                  ),
                if (hasOfficialVerification(document.type))
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.travel_explore_outlined, size: 18),
                      tooltip: S.verifyOnOfficialSite,
                      onPressed: () => verifyDocumentOnOfficialSite(
                        context,
                        type: document.type,
                        plateNumber: plateNumber,
                        vin: vin,
                      ),
                    ),
                  ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    tooltip: S.saveToCalendar,
                    onPressed: () =>
                        addDocumentExpiryToCalendar(document, vehicleLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
