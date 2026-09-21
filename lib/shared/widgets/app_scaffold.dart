import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'floating_nav_bar.dart';

class AppScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            if (notification.direction == ScrollDirection.reverse) {
              if (_isVisible) setState(() => _isVisible = false);
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_isVisible) setState(() => _isVisible = true);
            }
          }
          return false;
        },
        child: widget.navigationShell,
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: (_isVisible && MediaQuery.of(context).viewInsets.bottom == 0) ? Offset.zero : const Offset(0, 2.5),
        child: FloatingNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}
