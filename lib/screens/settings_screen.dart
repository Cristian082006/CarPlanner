import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/region_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _region = RegionService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.settingsTitle)),
      body: ValueListenableBuilder<String>(
        valueListenable: _region.countryCode,
        builder: (context, countryCode, _) {
          final isRomania = countryCode == 'RO';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(S.countryDescription, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              _CountryOption(
                flag: '🇷🇴',
                title: S.romaniaOptionTitle,
                subtitle: S.romaniaOptionSubtitle,
                selected: isRomania,
                onTap: () => _region.setCountryCode('RO'),
              ),
              const SizedBox(height: 12),
              _CountryOption(
                flag: '🌍',
                title: S.internationalOptionTitle,
                subtitle: S.internationalOptionSubtitle,
                selected: !isRomania,
                onTap: () => _region.setCountryCode('INTL'),
              ),
              const SizedBox(height: 20),
              Text(
                S.futureCountriesNote,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CountryOption extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _CountryOption({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? color : Theme.of(context).dividerColor, width: selected ? 2 : 1),
      ),
      leading: Text(flag, style: const TextStyle(fontSize: 28)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? color : Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
