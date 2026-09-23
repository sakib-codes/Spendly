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
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: colors.surfaceContainer,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // FAB width = 48, plus 8px padding on each side = 64
                  final eWidth = (constraints.maxWidth - 64) / 4;
                  double xCenter = 0;
                  if (currentIndex == 0) {
                    xCenter = eWidth / 2;
                  } else if (currentIndex == 1)
                    xCenter = eWidth * 1.5;
                  else if (currentIndex == 2)
                    xCenter = eWidth * 2.5 + 64;
                  else if (currentIndex == 3)
                    xCenter = eWidth * 3.5 + 64;

                  return Stack(
                    children: [
                      // Sliding background bubble
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        left: xCenter - 22,
                        top:
                            (60 - 44) /
                            2, // 60 is navbar height, 44 is bubble size
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Navigation items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Center(
                              child: _buildNavItem(
                                context,
                                0,
                                Icons.space_dashboard_outlined,
                                Icons.space_dashboard_rounded,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: _buildNavItem(
                                context,
                                1,
                                Icons.receipt_outlined,
                                Icons.receipt_rounded,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: _FloatingFab(
                              onTap: () =>
                                  context.pushNamed(RouteNames.addTransaction),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: _buildNavItem(
                                context,
                                2,
                                Icons.pie_chart_outline_rounded,
                                Icons.pie_chart_rounded,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: _buildNavItem(
                                context,
                                3,
                                Icons.person_outline_rounded,
                                Icons.person_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
  ) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors
              .transparent, // Background is now handled by the sliding bubble
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Icon(
            isSelected ? filledIcon : outlinedIcon,
            key: ValueKey<bool>(isSelected),
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _FloatingFab extends StatefulWidget {
  final VoidCallback onTap;

  const _FloatingFab({required this.onTap});

  @override
  State<_FloatingFab> createState() => _FloatingFabState();
}

class _FloatingFabState extends State<_FloatingFab> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOutBack,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(
                  alpha: _isPressed ? 0.1 : 0.3,
                ),
                blurRadius: _isPressed ? 6 : 12,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: Icon(
            Icons.add_rounded,
            color: theme.colorScheme.onPrimary,
            size: 32,
          ),
        ),
      ),
    );
  }
}
