import 'dart:math';
import 'package:flutter/material.dart';

class FlyingCartAnimation {
  /// Spawns a sequence of glowing orange bubbles flying sequentially from the clicked button into the cart icon.
  static void animate({
    required BuildContext context,
    GlobalKey? startKey,
    GlobalKey? productImageKey,
    GlobalKey? cartIconKey,
    String? imageUrl,
    int bubbleCount = 5,
    VoidCallback? onComplete,
  }) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      onComplete?.call();
      return;
    }

    // Always prefer startKey (the clicked button)
    final targetKey = startKey ?? productImageKey;
    final startContext = targetKey?.currentContext ?? context;
    final startBox = startContext.findRenderObject() as RenderBox?;

    if (startBox == null || !startBox.attached) {
      onComplete?.call();
      return;
    }

    final screenSize = MediaQuery.of(context).size;
    final startCenter = startBox.localToGlobal(Offset.zero) +
        Offset(startBox.size.width / 2, startBox.size.height / 2);

    Offset endCenter;
    final cartContext = cartIconKey?.currentContext;
    final cartBox = cartContext?.findRenderObject() as RenderBox?;

    if (cartBox != null && cartBox.attached) {
      endCenter = cartBox.localToGlobal(Offset.zero) +
          Offset(cartBox.size.width / 2, cartBox.size.height / 2);
    } else {
      // Default fallback: Target the bottom navbar cart tab position
      endCenter = Offset(screenSize.width * 0.70, screenSize.height - 45);
    }

    final overlay = Overlay.of(context);
    int completedCount = 0;

    for (int i = 0; i < bubbleCount; i++) {
      // Slow motion stream: staggered delay per bubble
      final delay = Duration(milliseconds: i * 140);

      // Decreasing size order (e.g. 32.0, 27.5, 23.0, 18.5, 14.0)
      final bubbleSize = max(12.0, 32.0 - (i * 4.5));

      // Decreasing glow intensity order (1.0, 0.85, 0.70, 0.55, 0.40)
      final glowFactor = (1.0 - (i * 0.15)).clamp(0.3, 1.0);

      Future.delayed(delay, () {
        if (!context.mounted) return;

        late OverlayEntry entry;

        entry = OverlayEntry(
          builder: (ctx) => _SingleOrangeBubbleWidget(
            index: i,
            bubbleSize: bubbleSize,
            glowFactor: glowFactor,
            startCenter: startCenter,
            endCenter: endCenter,
            onComplete: () {
              entry.remove();
              completedCount++;
              if (completedCount == bubbleCount) {
                onComplete?.call();
              }
            },
          ),
        );

        overlay.insert(entry);
      });
    }
  }
}

class _SingleOrangeBubbleWidget extends StatefulWidget {
  final int index;
  final double bubbleSize;
  final double glowFactor;
  final Offset startCenter;
  final Offset endCenter;
  final VoidCallback onComplete;

  const _SingleOrangeBubbleWidget({
    required this.index,
    required this.bubbleSize,
    required this.glowFactor,
    required this.startCenter,
    required this.endCenter,
    required this.onComplete,
  });

  @override
  State<_SingleOrangeBubbleWidget> createState() => _SingleOrangeBubbleWidgetState();
}

class _SingleOrangeBubbleWidgetState extends State<_SingleOrangeBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Offset _startOffset;
  late Offset _endOffset;
  late Offset _controlPoint;

  @override
  void initState() {
    super.initState();

    final halfSize = widget.bubbleSize / 2;
    _startOffset = widget.startCenter - Offset(halfSize, halfSize);
    _endOffset = widget.endCenter - Offset(halfSize, halfSize);

    final p0 = _startOffset;
    final p2 = _endOffset;

    // Single smooth arch path for the entire sequence
    final midX = (p0.dx + p2.dx) / 2;
    final minY = min(p0.dy, p2.dy);
    final arcHeight = max(90.0, (p0.dy - p2.dy).abs() * 0.35);

    _controlPoint = Offset(midX, minY - arcHeight);

    // Slow motion animation duration (1200ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _getQuadraticBezierPosition(double t) {
    final p0 = _startOffset;
    final p1 = _controlPoint;
    final p2 = _endOffset;

    final oneMinusT = 1.0 - t;
    final x = oneMinusT * oneMinusT * p0.dx + 2 * oneMinusT * t * p1.dx + t * t * p2.dx;
    final y = oneMinusT * oneMinusT * p0.dy + 2 * oneMinusT * t * p1.dy + t * t * p2.dy;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        final pos = _getQuadraticBezierPosition(t);

        // Scale shrinks gently as bubble arrives at cart
        final scale = 1.0 - (0.45 * t);

        // Opacity fades out smoothly at the very end of flight (last 10%)
        final opacity = t > 0.90 ? ((1.0 - t) / 0.10).clamp(0.0, 1.0) : 1.0;

        return Positioned(
          left: pos.dx,
          top: pos.dy,
          width: widget.bubbleSize,
          height: widget.bubbleSize,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFF176), // Bright glowing center core
                        Color(0xFFFF7043), // Vivid orange body
                        Color(0xFFF57C00), // Deep orange edge
                      ],
                      stops: [0.15, 0.65, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.75 * widget.glowFactor),
                        blurRadius: 14 * widget.glowFactor,
                        spreadRadius: 3 * widget.glowFactor,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.5 * widget.glowFactor),
                        blurRadius: 8 * widget.glowFactor,
                        spreadRadius: 1 * widget.glowFactor,
                      ),
                    ],
                  ),
                  child: _buildIcon(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    if (widget.bubbleSize < 16) {
      return const SizedBox.shrink();
    }
    final iconSize = max(9.0, widget.bubbleSize * 0.48);
    return Center(
      child: Icon(
        Icons.shopping_bag_rounded,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
