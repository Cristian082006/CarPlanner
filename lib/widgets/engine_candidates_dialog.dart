import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../utils/engine_lookup.dart';

/// Afișează lista de motoare candidate dintr-un [EngineCandidatesResult] și
/// întoarce rândul ales de utilizator (același format ca rândurile din
/// `motoare`, cu `model_nume`/`model_generatie`/`marca_nume` adăugate prin
/// JOIN) sau `null` dacă a anulat. Apelantul e responsabil să verifice
/// `result.candidates.isNotEmpty` înainte de a apela — dialogul presupune
/// că are cel puțin un candidat de arătat.
Future<Map<String, Object?>?> showEngineCandidatesDialog(
  BuildContext context,
  EngineCandidatesResult result,
) {
  final title = switch (result.tier) {
    EngineMatchTier.exact => S.vinCandidatesTitleExact,
    EngineMatchTier.model => S.vinCandidatesTitleModel,
    EngineMatchTier.make => S.vinCandidatesTitleMake,
  };

  return showDialog<Map<String, Object?>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!result.isExactMatch && result.modelYear != null) ...[
              Text(
                S.vinApproximateMatchHint(result.modelYear!),
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: result.candidates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final e = result.candidates[i];
                  final modelLabel = [e['model_nume'], e['model_generatie']]
                      .where((v) => v != null && v.toString().isNotEmpty)
                      .join(' ');
                  final engineLabel = e['denumire_comerciala'] ?? e['cod_motor'];
                  final anStart = e['an_start'];
                  final anStop = e['an_stop'];
                  final yearRange = anStart != null ? '$anStart–${anStop ?? S.present}' : null;
                  final specs = [
                    e['combustibil'],
                    if (e['capacitate_cm3'] != null) '${e['capacitate_cm3']} cm³',
                    if (e['putere_cp'] != null) '${e['putere_cp']} CP',
                    if (yearRange != null) yearRange,
                  ].where((v) => v != null && v.toString().isNotEmpty).join(', ');
                  return ListTile(
                    title: Text('$modelLabel — $engineLabel (${e['cod_motor']})'),
                    subtitle: Text(specs),
                    onTap: () => Navigator.pop(ctx, e),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.cancel)),
      ],
    ),
  );
}
