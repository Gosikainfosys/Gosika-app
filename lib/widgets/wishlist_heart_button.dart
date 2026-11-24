import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wishlist_provider.dart';

class WishlistHeartButton extends ConsumerStatefulWidget {
  final String productId;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showBackground;

  const WishlistHeartButton({
    super.key,
    required this.productId,
    this.size = 22.0,
    this.activeColor = const Color(0xFFEF4444),
    this.inactiveColor = const Color(0xFF64748B),
    this.showBackground = true,
  });

  @override
  ConsumerState<WishlistHeartButton> createState() => _WishlistHeartButtonState();
}

class _WishlistHeartButtonState extends ConsumerState<WishlistHeartButton>
    with TickerProviderStateMixin {
  late AnimationController _burstController;
  late AnimationController _breakController;
  bool _showBurst = false;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _breakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _burstController.dispose();
    _breakController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final currentlyWishlisted = ref.read(wishlistProvider.notifier).isWishlisted(widget.productId);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (!currentlyWishlisted) {
      // Adding to wishlist
      if (!disableAnimations) {
        setState(() => _showBurst = true);
        _burstController.forward(from: 0.0).then((_) {
          if (mounted) setState(() => _showBurst = false);
        });
      }
    } else {
      // Removing from wishlist
      if (!disableAnimations) {
        await _breakController.forward(from: 0.0);
        _breakController.reset();
      }
    }

    if (!mounted) return;
    final success = await ref.read(wishlistProvider.notifier).toggleWishlist(context, widget.productId);

    if (success && mounted) {
      final nowWishlisted = ref.read(wishlistProvider.notifier).isWishlisted(widget.productId);
      final message = nowWishlisted ? 'Added to wishlist ♥' : 'Removed from wishlist';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: nowWishlisted ? const Color(0xFFEF4444) : const Color(0xFF161D2B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWishlisted = ref.watch(wishlistProvider).isWishlisted(widget.productId);

    Widget iconWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: Icon(
        isWishlisted ? Icons.favorite : Icons.favorite_border,
        key: ValueKey<bool>(isWishlisted),
        color: isWishlisted ? widget.activeColor : widget.inactiveColor,
        size: widget.size,
      ),
    );

    if (_breakController.isAnimating) {
      iconWidget = AnimatedBuilder(
        animation: _breakController,
        builder: (context, child) {
          final t = _breakController.value; // 0.0 to 1.0
          double scale = 1.0;
          if (t < 0.4) {
            scale = 1.0 + (t / 0.4) * 0.3; // 1.0 -> 1.3
          } else {
            scale = 1.3 * (1.0 - ((t - 0.4) / 0.6)); // 1.3 -> 0.0
          }
          return Transform.scale(
            scale: scale.clamp(0.0, 1.5),
            child: Icon(
              Icons.favorite_border,
              color: widget.inactiveColor,
              size: widget.size,
            ),
          );
        },
      );
    }

    Widget content = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        if (_showBurst)
          AnimatedBuilder(
            animation: _burstController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size * 2, widget.size * 2),
                painter: _HeartBurstPainter(
                  progress: _burstController.value,
                  color: widget.activeColor,
                ),
              );
            },
          ),
      ],
    );

    if (widget.showBackground) {
      return InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(widget.size + 8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: content,
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: content,
      ),
    );
  }
}

class _HeartBurstPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  _HeartBurstPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final distance = progress * 28.0; // moves outward 28px
    final alpha = ((1.0 - progress) * 255).clamp(0, 255).toInt();
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.fill;

    // 6 angles: 0, 60, 120, 180, 240, 300 degrees
    for (int i = 0; i < 6; i++) {
      final angleRad = (i * 60) * math.pi / 180;
      final x = center.dx + distance * math.cos(angleRad);
      final y = center.dy + distance * math.sin(angleRad);

      _drawSmallHeart(canvas, Offset(x, y), 3.5 * (1.0 - progress * 0.4), paint);
    }
  }

  void _drawSmallHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.4);
    path.cubicTo(
      center.dx - size, center.dy - size * 0.6,
      center.dx - size * 0.6, center.dy - size * 1.2,
      center.dx, center.dy - size * 0.5,
    );
    path.cubicTo(
      center.dx + size * 0.6, center.dy - size * 1.2,
      center.dx + size, center.dy - size * 0.6,
      center.dx, center.dy + size * 0.4,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
