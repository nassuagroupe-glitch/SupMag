import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum TagVariant { accent, accent2, neutral, outline }

/// Small pill/status chip — mirrors the prototype's `.tag` classes.
class StatusTag extends StatelessWidget {
  const StatusTag(this.label, {super.key, this.variant = TagVariant.neutral});

  final String label;
  final TagVariant variant;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;
    switch (variant) {
      case TagVariant.accent:
        bg = AppColors.accent100;
        fg = AppColors.accent700;
        border = null;
      case TagVariant.accent2:
        bg = AppColors.accent2_100;
        fg = AppColors.accent2_700;
        border = null;
      case TagVariant.neutral:
        bg = AppColors.neutral200;
        fg = AppColors.neutral700;
        border = null;
      case TagVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.neutral700;
        border = Border.all(color: AppColors.neutral400);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, border: border, borderRadius: AppRadius.md),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    late final ButtonStyle style;
    Widget child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
          );
    switch (variant) {
      case AppButtonVariant.primary:
        style = FilledButton.styleFrom(
          backgroundColor: AppColors.text,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        );
        return SizedBox(
          width: expand ? double.infinity : null,
          child: FilledButton(onPressed: onPressed, style: style, child: child),
        );
      case AppButtonVariant.secondary:
        style = OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.neutral100,
          side: BorderSide(color: AppColors.neutral300),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        );
        return SizedBox(
          width: expand ? double.infinity : null,
          child: OutlinedButton(onPressed: onPressed, style: style, child: child),
        );
      case AppButtonVariant.ghost:
        style = TextButton.styleFrom(
          foregroundColor: AppColors.neutral700,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        );
        return SizedBox(
          width: expand ? double.infinity : null,
          child: TextButton(onPressed: onPressed, style: style, child: child),
        );
    }
  }
}

/// Elevated content block — mirrors `.card`.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.sm,
      ),
      child: child,
    );
  }
}

/// Small uppercase eyebrow label, used above every screen's H1.
class SectionKicker extends StatelessWidget {
  const SectionKicker(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.accent700,
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.headlineLarge);
  }
}

/// Field wrapper: small uppercase label above an input — mirrors `.field`.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, letterSpacing: 1.4, color: AppColors.neutral600, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

/// Horizontally-scrollable wrapper so wide data tables never blow out the
/// page layout — the desktop screens embed several of these.
class HScrollTable extends StatelessWidget {
  const HScrollTable({super.key, required this.child, this.minWidth = 900});
  final Widget child;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth.clamp(0, double.infinity) < minWidth ? minWidth : constraints.maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

/// Segmented toggle — mirrors `.seg` / `.seg-opt` used for the Caisse
/// variant picker.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({super.key, required this.options, required this.value, required this.onChanged});

  final List<(T value, String label)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: AppRadius.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (v, label) in options)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => onChanged(v),
                borderRadius: AppRadius.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: v == value ? AppColors.accent200 : Colors.transparent,
                    borderRadius: AppRadius.md,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: v == value ? AppColors.accent900 : AppColors.text,
                      fontWeight: v == value ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thin progress bar with a label row above it, used for "top produits" and
/// payment-method breakdowns.
class LabeledBar extends StatelessWidget {
  const LabeledBar({super.key, required this.label, required this.valueLabel, required this.fraction, this.color});

  final String label;
  final String valueLabel;
  final double fraction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text(valueLabel, style: const TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: AppRadius.sm,
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1),
            minHeight: 7,
            backgroundColor: AppColors.neutral200,
            valueColor: AlwaysStoppedAnimation(color ?? AppColors.accent),
          ),
        ),
      ],
    );
  }
}
