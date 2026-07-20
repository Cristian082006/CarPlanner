import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/service_record.dart';
import '../utils/date_utils.dart';

class ServiceRecordTile extends StatelessWidget {
  final ServiceRecord record;
  final VoidCallback? onTap;

  const ServiceRecordTile({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      formatDate(record.date),
      if (record.mileage != null) '${record.mileage} km',
      if (record.workshop?.isNotEmpty == true) record.workshop!,
    ];
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.build_outlined)),
      title: Text(record.title),
      subtitle: Text(subtitleParts.join(' • ')),
      trailing: record.cost != null
          ? Text('${record.cost!.toStringAsFixed(0)} ${S.costUnit}'.trim())
          : null,
      isThreeLine: false,
    );
  }
}
