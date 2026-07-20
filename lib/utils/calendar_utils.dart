import 'package:add_2_calendar/add_2_calendar.dart';

import '../l10n/strings.dart';
import '../models/car_document.dart';
import 'constants.dart';

/// Deschide ecranul nativ de calendar al telefonului, pre-completat cu un
/// eveniment de o zi la data expirării documentului. Utilizatorul confirmă
/// salvarea în calendarul lui — aplicația nu scrie direct în calendar.
void addDocumentExpiryToCalendar(CarDocument document, String vehicleLabel) {
  final label = document.title?.isNotEmpty == true ? document.title! : document.type.label;
  final start = DateTime(
    document.expiryDate.year,
    document.expiryDate.month,
    document.expiryDate.day,
    9,
  );

  final event = Event(
    title: S.calendarEventTitle(label, vehicleLabel),
    description: [
      if (document.provider?.isNotEmpty == true) '${S.calendarProviderPrefix}${document.provider}',
      if (document.policyNumber?.isNotEmpty == true)
        '${S.calendarPolicyPrefix}${document.policyNumber}',
    ].join('\n'),
    startDate: start,
    endDate: start.add(const Duration(hours: 1)),
    allDay: true,
    iosParams: const IOSParams(reminder: Duration(days: 3)),
    androidParams: const AndroidParams(),
  );

  Add2Calendar.addEvent2Cal(event);
}
