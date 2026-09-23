import 'package:flutter/material.dart';

class AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer> {
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _lastIndex = oldWidget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForward = widget.currentIndex >= _lastIndex;

    return Stack(
      children: List.generate(widget.children.length, (index) {
        final isActive = index == widget.currentIndex;
        return _Branch(
          isActive: isActive,
          isForward: isForward,
          child: widget.children[index],
        );
      }),
    );
  }
}

class _Branch extends StatefulWidget {
  final bool isActive;
  final bool isForward;
  final Widget child;

  const _Branch({
    required this.isActive,
    required this.isForward,
    required this.child,
  });

  @override
  State<_Branch> createState() => _BranchState();
}

class _BranchState extends State<_Branch> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isOffstage = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Initial state
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn));

    if (widget.isActive) {
      _isOffstage = false;
      _controller.value = 1.0;
    } else {
      _isOffstage = true;
      _controller.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(covariant _Branch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      final curve = Curves.fastOutSlowIn;
      const slideDistance = 0.15;

      if (widget.isActive) {
        // Entering
        final offset = widget.isForward
            ? const Offset(slideDistance, 0)
            : const Offset(-slideDistance, 0);
        _slideAnimation = Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: curve));
        _fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _controller, curve: curve));

        setState(() => _isOffstage = false);
        _controller.forward(from: 0.0);
      } else {
        // Exiting
        final offset = widget.isForward
            ? const Offset(-slideDistance, 0)
            : const Offset(slideDistance, 0);
        _slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: offset,
        ).animate(CurvedAnimation(parent: _controller, curve: curve));
        _fadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(parent: _controller, curve: curve));

        _controller.forward(from: 0.0).then((_) {
          if (mounted && !widget.isActive) {
            setState(() => _isOffstage = true);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: _isOffstage,
      child: TickerMode(
        enabled: widget.isActive,
        child: IgnorePointer(
          ignoring: !widget.isActive,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: RepaintBoundary(
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
