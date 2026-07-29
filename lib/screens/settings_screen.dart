import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../services/error_log_service.dart';
import '../services/region_service.dart';
import 'privacy_policy_screen.dart';

const _feedbackEmail = 'crdo0809@gmail.com';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _region = RegionService.instance;

  // Citit din `pubspec.yaml` la runtime (via `package_info_plus`), nu mai e
  // hardcodat — un string fix ("Versiune 1.0") rămânea mereu în urmă, de
  // fiecare dată când `versionCode`-ul era incrementat înainte de un build
  // (regulă cerută explicit de utilizator, vezi CLAUDE.md).
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _versionLabel = '${info.version} (${info.buildNumber})');
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: _feedbackEmail,
      query: 'subject=${Uri.encodeComponent(S.feedbackEmailSubject)}',
    );
    final launched = await launchUrl(uri);
    if (!context.mounted || launched) return;
    messenger.showSnackBar(SnackBar(content: Text(S.feedbackLaunchFailed)));
  }

  Future<void> _sendErrorLog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await ErrorLogService.instance.hasEntries()) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(S.noErrorLogEntries)));
      return;
    }
    final file = await ErrorLogService.instance.exportFile();
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

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
              _SectionHeader(S.feedbackSectionHeader),
              Text(
                S.feedbackDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _sendFeedback(context),
                icon: const Icon(Icons.email_outlined),
                label: Text(S.sendFeedbackButton),
              ),
              const SizedBox(height: 12),
              Text(
                S.errorLogDescription,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _sendErrorLog(context),
                icon: const Icon(Icons.bug_report_outlined),
                label: Text(S.sendErrorLogButton),
              ),
              const SizedBox(height: 32),
              _SectionHeader(S.versionSectionHeader),
              Text(
                S.appVersionLabel(_versionLabel),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
                icon: const Icon(Icons.privacy_tip_outlined),
                label: Text(S.privacyPolicyButton),
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
