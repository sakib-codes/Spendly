import 'package:flutter/material.dart';
import 'package:spendly/shared/widgets/glass_card.dart';

class GlassToast {
  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Animation controller for the slide effect
    final controller = AnimationController(
      vsync: overlay,
      duration: const Duration(milliseconds: 300),
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    controller.forward();

    Future.delayed(duration, () async {
      if (overlayEntry.mounted) {
        await controller.reverse();
        overlayEntry.remove();
        controller.dispose();
      }
    });
  }
}
