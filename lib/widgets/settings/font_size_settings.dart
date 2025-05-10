import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../cubit/theme/theme_cubit.dart';

class FontSizeSettings extends StatelessWidget {
  const FontSizeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.small,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              l10n.medium,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              l10n.large,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        Slider(
          value: themeState.fontSize,
          min: 0,
          max: 2,
          divisions: 2,
          label: _getFontSizeLabel(themeState.fontSize, l10n),
          onChanged: (double value) {
            context.read<ThemeCubit>().setFontSize(value);
          },
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  String _getFontSizeLabel(double size, AppLocalizations l10n) {
    switch (size) {
      case 0:
        return '${l10n.small} (1x)';
      case 1:
        return '${l10n.medium} (1.5x)';
      case 2:
        return '${l10n.large} (2x)';
      default:
        return '${l10n.medium} (1.5x)';
    }
  }
}
