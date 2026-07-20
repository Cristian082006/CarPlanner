import '../l10n/strings.dart';

String formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String daysUntilLabel(int days) {
  if (days < 0) return S.expiredAgo(-days);
  if (days == 0) return S.expiresToday;
  return S.expiresIn(days);
}
