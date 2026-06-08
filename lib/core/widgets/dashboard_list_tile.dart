import 'package:flutter/material.dart';

/// Compact 70px dashboard-style list row (primaryContainer, 12px radius).
class DashboardListTile extends StatelessWidget {
  const DashboardListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.backgroundColor,
    this.onTap,
    this.showChevron = true,
    this.padding = const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 0),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showChevron;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final fill = backgroundColor ?? Theme.of(context).colorScheme.primaryContainer;
    return Padding(
      padding: padding,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                  if (showChevron)
                    IconButton(
                      onPressed: onTap,
                      icon: const Icon(Icons.chevron_right),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width tonal button for dashboard tab navigation (distinct from [DashboardListTile]).
class DashboardNavigationButton extends StatelessWidget {
  const DashboardNavigationButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
    this.padding = const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 0),
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool emphasized;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      alignment: Alignment.centerLeft,
      backgroundColor: emphasized ? scheme.primary : null,
      foregroundColor: emphasized ? scheme.onPrimary : null,
    );

    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: emphasized
            ? FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
                style: style,
              )
            : FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
                style: style,
              ),
      ),
    );
  }
}

/// Bold section heading aligned with the Dashboard layout.
class DashboardSectionHeading extends StatelessWidget {
  const DashboardSectionHeading({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottomSpacing = 5,
  });

  final String title;
  final List<Widget> actions;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ...actions,
            const SizedBox(width: 12),
          ],
        ),
        SizedBox(height: bottomSpacing),
      ],
    );
  }
}
