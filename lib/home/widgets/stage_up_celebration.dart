import 'dart:math';
import 'package:flutter/material.dart';

class StageUpCelebration {
  static void show(
    BuildContext context, {
    required String stageLabel,
    required IconData icon,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (context) => _CelebrationOverlay(
            stageLabel: stageLabel,
            icon: icon,
            onComplete: () => entry.remove(),
          ),
    );
    overlay.insert(entry);
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final String stageLabel;
  final IconData icon;
  final VoidCallback onComplete;

  const _CelebrationOverlay({
    required this.stageLabel,
    required this.icon,
    required this.onComplete,
  });

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _colors = [
    Color(0xFFFFC107),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFFFF7043),
  ];

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _particles = List.generate(30, (_) {
      return _Particle(
        x: rnd.nextDouble(),
        delay: rnd.nextDouble() * 0.25,
        speed: 0.7 + rnd.nextDouble() * 0.6,
        drift: (rnd.nextDouble() - 0.5) * 0.5,
        color: _colors[rnd.nextInt(_colors.length)],
        size: 6 + rnd.nextDouble() * 6,
        rotationSpeed: (rnd.nextDouble() - 0.5) * 6,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          double bannerOpacity;
          if (t < 0.1) {
            bannerOpacity = t / 0.1;
          } else if (t > 0.85) {
            bannerOpacity = ((1 - t) / 0.15).clamp(0.0, 1.0);
          } else {
            bannerOpacity = 1.0;
          }
          final bannerScale = 0.8 + 0.2 * (t < 0.1 ? t / 0.1 : 1.0);

          return Stack(
            children: [
              CustomPaint(
                size: size,
                painter: _ConfettiPainter(particles: _particles, progress: t),
              ),
              Center(
                child: Opacity(
                  opacity: bannerOpacity,
                  child: Transform.scale(
                    scale: bannerScale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(
                                0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'You grew into',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            widget.stageLabel,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x, delay, speed, drift, size, rotationSpeed;
  final Color color;
  _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.color,
    required this.size,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final localT = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final y = -20 + localT * p.speed * (size.height + 40);
      final x = p.x * size.width + p.drift * size.width * localT;
      final opacity = localT > 0.85 ? (1 - localT) / 0.15 : 1.0;

      final paint =
          Paint()..color = p.color.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(localT * p.rotationSpeed * pi);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
