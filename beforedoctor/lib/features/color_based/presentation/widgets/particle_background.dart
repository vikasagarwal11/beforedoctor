import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/models/particle.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/app_models.dart';

/// Animated particle background widget
class ParticleBackground extends StatefulWidget {
  final AppStatus currentStatus;
  final bool reduceMotion;

  const ParticleBackground({
    super.key,
    required this.currentStatus,
    required this.reduceMotion,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late Animation<double> _particleAnimation;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
  }

  void _initializeAnimations() {
    _particleController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));
    
    _particleController.repeat();
  }

  void _generateParticles() {
    for (int i = 0; i < 25; i++) {
      _particles.add(Particle(
        x: math.Random().nextDouble() * 400,
        y: math.Random().nextDouble() * 800,
        size: math.Random().nextDouble() * 2 + 1,
        speed: math.Random().nextDouble() * 1.5 + 0.5,
        color: _getParticleColor(),
      ));
    }
  }

  Color _getParticleColor() {
    final random = math.Random();
    final warmColorChance = widget.currentStatus == AppStatus.processing ? 0.08 : 0.15;
    
    if (random.nextDouble() < warmColorChance) {
      final warmColors = [
        ClinicColors.amber,
        ClinicColors.coral,
        ClinicColors.mint,
      ];
      return warmColors[random.nextInt(warmColors.length)].withOpacity(0.3);
    }
    
    switch (widget.currentStatus) {
      case AppStatus.listening:
        return ClinicColors.sea.withOpacity(0.3);
      case AppStatus.processing:
        return ClinicColors.amber.withOpacity(0.3);
      case AppStatus.speaking:
        return ClinicColors.speak.withOpacity(0.3);
      case AppStatus.complete:
        return ClinicColors.secondary.withOpacity(0.3);
      case AppStatus.concerned:
        return ClinicColors.coral.withOpacity(0.3);
      case AppStatus.ready:
      default:
        return ClinicColors.primary.withOpacity(0.3);
    }
  }

  void _regenerateParticles() {
    _particles.clear();
    _generateParticles();
  }

  void _addBurstEffect() {
    for (int i = 0; i < 8; i++) {
      final random = math.Random();
      Color burstColor;
      
      if (random.nextDouble() < 0.5) {
        final warmColors = [
          ClinicColors.amber,
          ClinicColors.coral,
          ClinicColors.mint,
        ];
        burstColor = warmColors[random.nextInt(warmColors.length)];
      } else {
        burstColor = _getParticleColor();
      }
      
      _particles.add(Particle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        size: random.nextDouble() * 3 + 2,
        speed: random.nextDouble() * 3 + 2,
        color: burstColor.withOpacity(0.5),
      ));
    }
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _particles.length > 25) {
        setState(() {
          _particles.removeRange(25, _particles.length);
        });
      }
    });
  }

  @override
  void didUpdateWidget(ParticleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _regenerateParticles();
      _addBurstEffect();
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlePainter(
              particles: _particles,
              animation: _particleAnimation.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
