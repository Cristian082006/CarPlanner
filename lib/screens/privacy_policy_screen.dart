import 'package:flutter/material.dart';

import '../l10n/strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.privacyPolicyTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(S.privacyPolicyBody, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
