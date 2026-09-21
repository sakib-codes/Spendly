import 'package:flutter/material.dart';
import 'package:spendly/shared/widgets/glass_card.dart';

class GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final Widget? icon;

  const GlassDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
    Widget? icon,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return GlassDialog(
          title: title,
          content: content,
          actions: actions,
          icon: icon,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Center(child: icon!),
                  const SizedBox(height: 16),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                content,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
