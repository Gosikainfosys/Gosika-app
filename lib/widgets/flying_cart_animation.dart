import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FlyingCartAnimation {
  static void animate({
    required BuildContext context,
    required GlobalKey productImageKey,
    required GlobalKey cartIconKey,
    String? imageUrl,
    VoidCallback? onComplete,
  }) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      onComplete?.call();
      return;
    }

    final productContext = productImageKey.currentContext;
    final cartContext = cartIconKey.currentContext;

    if (productContext == null || cartContext == null) {
      onComplete?.call();
      return;
    }

    final productBox = productContext.findRenderObject() as RenderBox?;
    final cartBox = cartContext.findRenderObject() as RenderBox?;

    if (productBox == null || !productBox.attached || cartBox == null || !cartBox.attached) {
      onComplete?.call();
      return;
    }

    final startOffset = productBox.localToGlobal(Offset.zero);
    final endOffset = cartBox.localToGlobal(Offset.zero);
    final size = productBox.size;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _FlyingCartItemWidget(
        startOffset: startOffset,
        endOffset: endOffset,
        size: size,
        imageUrl: imageUrl,
        onComplete: () {
          entry.remove();
          onComplete?.call();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _FlyingCartItemWidget extends StatefulWidget {
  final Offset startOffset;
  final Offset endOffset;
  final Size size;
  final String? imageUrl;
  final VoidCallback onComplete;

  const _FlyingCartItemWidget({
    required this.startOffset,
    required this.endOffset,
    required this.size,
    this.imageUrl,
    required this.onComplete,
  });

  @override
  State<_FlyingCartItemWidget> createState() => _FlyingCartItemWidgetState();
}

class _FlyingCartItemWidgetState extends State<_FlyingCartItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _positionAnimation = Tween<Offset>(
      begin: widget.startOffset,
      end: widget.endOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = _positionAnimation.value;
        final scale = _scaleAnimation.value;
        final opacity = _opacityAnimation.value;

        final itemWidth = widget.size.width.clamp(40.0, 100.0);
        final itemHeight = widget.size.height.clamp(40.0, 100.0);

        return Positioned(
          left: pos.dx,
          top: pos.dy,
          width: itemWidth,
          height: itemHeight,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFFF5500),
                            child: const Icon(Icons.shopping_bag, color: Colors.white),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFFF5500),
                          child: const Icon(Icons.shopping_bag, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
