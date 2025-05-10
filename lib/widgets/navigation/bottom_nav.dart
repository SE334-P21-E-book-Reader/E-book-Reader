import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final String activeItem;
  final Function(int) onItemSelected;

  const BottomNav({
    super.key,
    required this.activeItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home,
                  isActive: activeItem == 'home',
                  onTap: () => onItemSelected(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.bookmark,
                  isActive: activeItem == 'library',
                  onTap: () => onItemSelected(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.settings,
                  isActive: activeItem == 'settings',
                  onTap: () => onItemSelected(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = Theme.of(context)
        .colorScheme
        .secondary
        .withValues(alpha: 51); // 20% opacity
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32.0,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: 24,
            decoration: BoxDecoration(
              color: isActive ? indicatorColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
