import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../cubit/theme/theme_cubit.dart';

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final isDarkMode = themeState.themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.darkMode),
        Switch(
          value: isDarkMode,
          onChanged: (value) {
            context.read<ThemeCubit>().setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
          },
        ),
      ],
    );
  }
}
