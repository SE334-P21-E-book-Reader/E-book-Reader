import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../bloc/theme/theme_cubit.dart';
import '../components/icon_switch.dart';

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
        IconSwitch(
          items: [
            IconSwitchItem(
              icon: Icons.light_mode,
              tooltip: l10n.theme,
              selected: !isDarkMode,
              onTap: () =>
                  context.read<ThemeCubit>().setThemeMode(ThemeMode.light),
              theme: Theme.of(context),
            ),
            IconSwitchItem(
              icon: Icons.dark_mode,
              tooltip: l10n.darkMode,
              selected: isDarkMode,
              onTap: () =>
                  context.read<ThemeCubit>().setThemeMode(ThemeMode.dark),
              theme: Theme.of(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;
  final ThemeData theme;

  const _ThemeModeButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: selected
                ? (theme.brightness == Brightness.dark
                    ? theme.colorScheme.primary.withOpacity(0.25)
                    : theme.colorScheme.primary.withOpacity(0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: RotationTransition(
                  turns: animation,
                  child: child,
                ),
              ),
              child: Icon(
                icon,
                key: ValueKey<bool>(selected),
                color: selected
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
