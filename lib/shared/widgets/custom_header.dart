import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onBackPressed;
  final EdgeInsetsGeometry padding;

  const CustomHeader({
    super.key,
    required this.title,
    this.icon = Icons.arrow_back_rounded,
    this.onBackPressed,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackPressed ?? () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: theme.colorScheme.onSurface),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
