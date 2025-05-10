import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flag/flag.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/language/language_cubit.dart';

class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final languageState = context.watch<LanguageCubit>().state;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.languageDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Flag.fromString('US', height: 32, width: 48),
              title: Text(l10n.english),
              trailing: Radio<String>(
                value: 'en',
                groupValue: languageState.locale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<LanguageCubit>().setLanguage(value);
                  }
                },
              ),
            ),
            ListTile(
              leading: const Flag.fromString('VN', height: 32, width: 48),
              title: Text(l10n.vietnamese),
              trailing: Radio<String>(
                value: 'vi',
                groupValue: languageState.locale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<LanguageCubit>().setLanguage(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
