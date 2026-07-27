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
          final isRomanian = countryCode == 'RO';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(S.languageSectionHeader),
              Text(S.languageDescription, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              _LanguageOption(
                flag: '🇷🇴',
                title: S.romanianLanguageTitle,
                subtitle: S.romanianLanguageSubtitle,
                selected: isRomanian,
                onTap: () => _region.setCountryCode('RO'),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                flag: '🌍',
                title: S.englishLanguageTitle,
                subtitle: S.englishLanguageSubtitle,
                selected: !isRomanian,
                onTap: () => _region.setCountryCode('INTL'),
              ),
              const SizedBox(height: 20),
              Text(
                S.moreLanguagesNote,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 32),
              _SectionHeader(S.contactSectionHeader),
              Text(
                S.contactComingSoon,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
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
