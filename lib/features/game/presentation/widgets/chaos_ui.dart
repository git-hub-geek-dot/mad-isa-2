import 'package:flutter/material.dart';

class ChaosBackdropOrb extends StatelessWidget {
  const ChaosBackdropOrb({super.key, required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: size,
        width: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}

class ChaosStatusPill extends StatelessWidget {
  const ChaosStatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.iconSize = 16,
    this.textStyle,
    this.actionButton,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final TextStyle? textStyle;
  final Widget? actionButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = textStyle ?? theme.textTheme.bodyMedium;
    final resolvedStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: foregroundColor,
      fontWeight: baseStyle?.fontWeight ?? FontWeight.w700,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: foregroundColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: resolvedStyle),
            ),
            if (actionButton != null) ...[
              const SizedBox(width: 12),
              actionButton!,
            ]
          ],
        ),
      ),
    );
  }
}

class ChaosSectionHeader extends StatelessWidget {
  const ChaosSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.gap = 6,
  });

  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle ?? theme.textTheme.titleLarge),
        SizedBox(height: gap),
        Text(subtitle, style: subtitleStyle ?? theme.textTheme.bodyMedium),
      ],
    );
  }
}
