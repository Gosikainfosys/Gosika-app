import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants.dart';

class AnimatedOrderTrackerLine extends StatefulWidget {
  final String status;
  final String? cancelReason;

  const AnimatedOrderTrackerLine({
    super.key,
    required this.status,
    this.cancelReason,
  });

  @override
  State<AnimatedOrderTrackerLine> createState() => _AnimatedOrderTrackerLineState();
}

class _AirParticle {
  double x;
  double y;
  double radius;
  double opacity;
  final double vx;
  final double vy;

  _AirParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.vx,
    required this.vy,
  });

  bool update() {
    x += vx;
    y += vy;
    radius += 0.3;
    opacity -= 0.028;
    return opacity > 0;
  }
}

class _AnimatedOrderTrackerLineState extends State<AnimatedOrderTrackerLine>
    with TickerProviderStateMixin {
  late AnimationController _driveController;
  late AnimationController _idleController;
  late Animation<double> _driveAnimation;

  final List<_AirParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _driveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _driveAnimation = CurvedAnimation(
      parent: _driveController,
      curve: Curves.easeOutCubic,
    );

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _idleController.addListener(_updateParticles);

    _driveController.forward();
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      // Spawn new air particles from the back of the moving truck
      if (_particles.length < 25) {
        _particles.add(
          _AirParticle(
            x: 0,
            y: 0,
            radius: 2.5 + _random.nextDouble() * 2.0,
            opacity: 0.75 + _random.nextDouble() * 0.2,
            vx: -(1.4 + _random.nextDouble() * 1.2), // Drift backwards from truck
            vy: -(0.5 + _random.nextDouble() * 0.6), // Drift upwards
          ),
        );
      }

      // Update position of all air smoke particles
      _particles.removeWhere((p) => !p.update());
    });
  }

  @override
  void dispose() {
    _idleController.removeListener(_updateParticles);
    _driveController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getSteps() {
    final s = widget.status.toLowerCase();

    final List<Map<String, dynamic>> allSteps = [
      {'key': 'payment_pending', 'label': 'Payment Pending', 'aliases': <String>['unpaid']},
      {'key': 'pending', 'label': 'Pending', 'aliases': <String>[]},
      {'key': 'confirmed', 'label': 'Confirmed', 'aliases': <String>['accepted']},
      {'key': 'processing', 'label': 'Processing', 'aliases': <String>['preparing']},
      {'key': 'ready_for_pickup', 'label': 'Ready for Pickup', 'aliases': <String>[]},
      {'key': 'picked_up', 'label': 'Picked Up', 'aliases': <String>[]},
      {'key': 'out_for_delivery', 'label': 'Out for Delivery', 'aliases': <String>[]},
      {'key': 'delivered', 'label': 'Delivered', 'aliases': <String>[]},
      {'key': 'completed', 'label': 'Completed', 'aliases': <String>[]},
    ];

    if (s == 'payment_pending') return allSteps;
    return allSteps.where((step) => step['key'] != 'payment_pending').toList();
  }

  int _getCurrentIndex(List<Map<String, dynamic>> steps) {
    final s = widget.status.toLowerCase();
    for (int i = 0; i < steps.length; i++) {
      final key = steps[i]['key'] as String;
      final aliases = List<String>.from(steps[i]['aliases'] as List);
      if (s == key || aliases.contains(s)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status.toLowerCase();
    final isCancelled = s == 'cancelled' || s == 'rejected' || s == 'failed';

    if (isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Order Cancelled / Failed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade800),
                ),
              ],
            ),
            if (widget.cancelReason != null && widget.cancelReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${widget.cancelReason}',
                style: TextStyle(fontSize: 13, color: Colors.red.shade900),
              ),
            ],
          ],
        ),
      );
    }

    final steps = _getSteps();
    final currentIndex = _getCurrentIndex(steps);
    final targetProgressRatio = steps.length > 1 ? currentIndex / (steps.length - 1) : 1.0;

    const double stepWidth = 92.0;
    final totalWidth = steps.length * stepWidth;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: AnimatedBuilder(
            animation: Listenable.merge([_driveAnimation, _idleController]),
            builder: (context, child) {
              final progress = _driveAnimation.value * targetProgressRatio;

              // Truck position along tracker progress line
              final startX = stepWidth / 2;
              final endX = totalWidth - (stepWidth / 2);
              final lineLength = endX - startX;
              final truckX = startX + (progress * lineLength);

              // Driving bounce animation (road motion vibration)
              final bounceY = sin(_idleController.value * 2 * pi * 3) * 1.5;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Line and Step Nodes Layer
                  Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(steps.length, (index) {
                        final isCompleted = index <= currentIndex;
                        final isLast = index == steps.length - 1;
                        final label = steps[index]['label'] as String;

                        return SizedBox(
                          width: stepWidth,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: index == 0
                                            ? Colors.transparent
                                            : (index <= currentIndex ? AppColors.primaryOrange : Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted ? AppColors.primaryOrange : Colors.white,
                                      border: Border.all(
                                        color: isCompleted ? AppColors.primaryOrange : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                      boxShadow: isCompleted && index == currentIndex
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primaryOrange.withValues(alpha: 0.45),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                          : Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isLast
                                            ? Colors.transparent
                                            : (index < currentIndex ? AppColors.primaryOrange : Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                                  color: isCompleted ? kNavy : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  // Animated Exhaust Air Smoke Particles Layer (behind truck)
                  Positioned(
                    left: truckX - 16,
                    top: 26 - 10 + bounceY,
                    child: CustomPaint(
                      painter: _ExhaustAirPainter(particles: _particles),
                    ),
                  ),

                  // Animating Driving Truck Widget
                  Positioned(
                    left: truckX - 18,
                    top: 26 - 18 + bounceY,
                    child: Container(
                      width: 36,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7043), Color(0xFFF97316)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF97316).withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExhaustAirPainter extends CustomPainter {
  final List<_AirParticle> particles;

  _ExhaustAirPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = const Color(0xFFFFB74D).withValues(alpha: (p.opacity * 0.65).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(p.x, p.y + 12), p.radius, paint);

      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: (p.opacity * 0.85).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(p.x, p.y + 12), max(0.8, p.radius * 0.4), corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExhaustAirPainter oldDelegate) => true;
}
