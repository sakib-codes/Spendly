import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/app/router/route_names.dart';

class FloatingNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: colors.surfaceContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Center(child: _buildNavItem(context, 0, Icons.space_dashboard_outlined, Icons.space_dashboard_rounded))),
                  Expanded(child: Center(child: _buildNavItem(context, 1, Icons.receipt_outlined, Icons.receipt_rounded))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildFab(context),
                  ),
                  Expanded(child: Center(child: _buildNavItem(context, 2, Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded))),
                  Expanded(child: Center(child: _buildNavItem(context, 3, Icons.person_outline_rounded, Icons.person_rounded))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData outlinedIcon, IconData filledIcon) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.addTransaction),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: theme.colorScheme.onPrimary,
          size: 32,
        ),
      ),
    );
  }
}
