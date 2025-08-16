import 'package:flutter/material.dart';

/// Enhanced Particle system for background animation
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}

/// Enhanced Custom painter for particle system
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;

  ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;
      
      // Upward motion with diagonal drift
      final x = (particle.x + animation * particle.speed * 100) % size.width;
      final y = (particle.y - animation * particle.speed * 50) % size.height;
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Only repaint if animation value changed significantly (performance optimization)
    if (oldDelegate is ParticlePainter) {
      return (animation - oldDelegate.animation).abs() > 0.01;
    }
    return true;
  }
}
