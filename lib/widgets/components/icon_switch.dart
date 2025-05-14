import 'package:flutter/material.dart';

class IconSwitchItem {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  IconSwitchItem({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    required this.theme,
  });
}

class IconSwitch extends StatelessWidget {
  final List<IconSwitchItem> items;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const IconSwitch({
    Key? key,
    required this.items,
    this.borderRadius = 24,
    this.borderColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border:
            Border.all(color: borderColor ?? Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: item.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: item.selected
                      ? (item.theme.brightness == Brightness.dark
                          ? item.theme.colorScheme.primary.withOpacity(0.25)
                          : item.theme.colorScheme.primary.withOpacity(0.12))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(borderRadius),
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
                      item.icon,
                      key: ValueKey<bool>(item.selected),
                      color: item.selected
                          ? item.theme.colorScheme.primary
                          : item.theme.iconTheme.color,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
