import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fires a "+N" badge that flies in a comet-trail arc from [start]
/// (usually the tap position on the button the user pressed) to the
/// center of whatever widget is registered under [targetKey] (usually
/// the score number in ReflectoScoreSection).
///
/// Call [onLanded] to bump the actual score state right when the badge
/// arrives, so the score-section pop animation and the flight feel
/// like one continuous motion.
class ScoreFlyOverlay {
  ScoreFlyOverlay._();

  static void fly({
    required BuildContext context,
    required Offset start,
    required GlobalKey targetKey,
    required int points,
    Color color = const Color(0xFF4CAF50),
    VoidCallback? onLanded,
  }) {
    final targetContext = targetKey.currentContext;
    if (targetContext == null) {
      // Target not on screen (e.g. scrolled away) — just apply the
      // score change without the flight animation.
      onLanded?.call();
      return;
    }

    final overlayState = Overlay.of(context, rootOverlay: true);
    final targetBox = targetContext.findRenderObject() as RenderBox;
    final targetPosition = targetBox.localToGlobal(
      Offset(targetBox.size.width / 2, targetBox.size.height / 2),
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => _FlyingScoreBadge(
            start: start,
            end: targetPosition,
            points: points,
            color: color,
            onComplete: () {
              entry.remove();
              onLanded?.call();
            },
          ),
    );

    overlayState.insert(entry);
  }
}

class _FlyingScoreBadge extends StatefulWidget {
  final Offset start;
  final Offset end;
  final int points;
  final Color color;
  final VoidCallback onComplete;

  const _FlyingScoreBadge({
    required this.start,
    required this.end,
    required this.points,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_FlyingScoreBadge> createState() => _FlyingScoreBadgeState();
}

class _FlyingScoreBadgeState extends State<_FlyingScoreBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  final List<Offset> _trail = [];
  late final Offset _control;

  @override
  void initState() {
    super.initState();

    // Arc the path upward — a straight line reads as a "slide", a bow
    // reads as a "flight". Lift scales with distance so short and long
    // hops both look natural.
    final mid = Offset.lerp(widget.start, widget.end, 0.5)!;
    final dx = widget.end.dx - widget.start.dx;
    final dy = widget.end.dy - widget.start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final lift = math.max(50.0, distance * 0.35);
    _control = Offset(mid.dx, mid.dy - lift);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);

    _controller.addListener(() {
      setState(() {
        _trail.add(_positionAt(_t.value));
        if (_trail.length > 12) _trail.removeAt(0);
      });
    });

    _controller.forward().whenComplete(widget.onComplete);
  }

  // Quadratic bezier between start, control, end.
  Offset _positionAt(double t) {
    final u = 1 - t;
    final x =
        u * u * widget.start.dx +
        2 * u * t * _control.dx +
        t * t * widget.end.dx;
    final y =
        u * u * widget.start.dy +
        2 * u * t * _control.dy +
        t * t * widget.end.dy;
    return Offset(x, y);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t.value;
    final position = _positionAt(t);

    // Quick pop-in, then a slight shrink as it approaches the target,
    // then a fast fade in the last 15% so it doesn't visibly overlap
    // the number it's about to bump.
    final popIn = t < 0.15 ? Curves.easeOutBack.transform(t / 0.15) : 1.0;
    final shrink = t > 0.15 ? 1.0 - (t - 0.15) * 0.3 : 1.0;
    final scale = (popIn * shrink).clamp(0.0, 1.3);
    final opacity = t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15).clamp(0.0, 1.0);

    return IgnorePointer(
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _TrailPainter(
              points: List.of(_trail),
              color: widget.color,
            ),
          ),
          Positioned(
            left: position.dx - 22,
            top: position.dy - 14,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    '+${widget.points}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the fading comet tail behind the flying badge.
class _TrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  _TrailPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final progress = i / points.length;
      final paint =
          Paint()
            ..color = color.withOpacity(progress * 0.45)
            ..strokeWidth = 1.5 + progress * 4
            ..strokeCap = StrokeCap.round;
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) => true;
}
