import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'dart:math' as math;
import '../../../../core/services/real_voice_service.dart';

/// Voice State Aware UI Component
/// Changes colors and animations based on current voice state
class VoiceStateAwareUI extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Duration animationDuration;
  final bool showPulseEffect;
  final bool showWaveAnimation;

  const VoiceStateAwareUI({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showPulseEffect = true,
    this.showWaveAnimation = true,
  });

  @override
  State<VoiceStateAwareUI> createState() => _VoiceStateAwareUIState();
}

class _VoiceStateAwareUIState extends State<VoiceStateAwareUI>
    with TickerProviderStateMixin {
  late AnimationController _colorController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  
  late Animation<Color?> _colorAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  VoiceState _currentState = VoiceState.idle;
  Color _currentColor = Colors.grey.shade300;
  
  // Color scheme for different voice states
  static const Map<VoiceState, Color> _stateColors = {
    VoiceState.idle: Color(0xFFE0E0E0),        // Neutral grey
    VoiceState.listening: Color(0xFF2196F3),   // Calm blue
    VoiceState.activeListening: Color(0xFF03A9F4), // Bright blue
    VoiceState.thinking: Color(0xFFFF9800),    // Thinking orange
    VoiceState.speaking: Color(0xFF4CAF50),    // Speaking green
    VoiceState.serious: Color(0xFFF44336),     // Serious red
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _colorController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Initialize animations
    _initializeAnimations();
    
    // Listen to voice state changes
    _listenToVoiceState();
  }

  void _initializeAnimations() {
    // Color transition animation
    _colorAnimation = ColorTween(
      begin: _currentColor,
      end: _currentColor,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
    
    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Wave animation
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
  }

  void _listenToVoiceState() {
    RealVoiceService.instance.stateStream.listen((state) {
      if (mounted) {
        _updateVoiceState(state);
      }
    });
  }

  void _updateVoiceState(VoiceState newState) {
    if (_currentState == newState) return;
    
    setState(() {
      _currentState = newState;
    });
    
    // Update color
    _updateColor(_stateColors[newState] ?? _stateColors[VoiceState.idle]!);
    
    // Update animations based on state
    _updateAnimations(newState);
    
    print('🎨 UI updated for voice state: ${newState.name}');
  }

  void _updateColor(Color newColor) {
    _colorAnimation = ColorTween(
      begin: _currentColor,
      end: newColor,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
    
    _currentColor = newColor;
    _colorController.forward(from: 0.0);
  }

  void _updateAnimations(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        _stopAllAnimations();
        break;
        
      case VoiceState.listening:
        _startListeningAnimations();
        break;
        
      case VoiceState.activeListening:
        _startActiveListeningAnimations();
        break;
        
      case VoiceState.thinking:
        _startThinkingAnimations();
        break;
        
      case VoiceState.speaking:
        _startSpeakingAnimations();
        break;
        
      case VoiceState.serious:
        _startSeriousAnimations();
        break;
    }
  }

  void _startListeningAnimations() {
    if (widget.showPulseEffect) {
      _pulseController.repeat(reverse: true);
    }
    if (widget.showWaveAnimation) {
      _waveController.repeat();
    }
  }

  void _startActiveListeningAnimations() {
    if (widget.showPulseEffect) {
      _pulseController.repeat(reverse: true);
      _pulseController.duration = const Duration(milliseconds: 500);
    }
    if (widget.showWaveAnimation) {
      _waveController.repeat();
      _waveController.duration = const Duration(milliseconds: 1000);
    }
  }

  void _startThinkingAnimations() {
    if (widget.showPulseEffect) {
      _pulseController.repeat(reverse: true);
      _pulseController.duration = const Duration(milliseconds: 800);
    }
    if (widget.showWaveAnimation) {
      _waveController.repeat();
      _waveController.duration = const Duration(milliseconds: 1500);
    }
  }

  void _startSpeakingAnimations() {
    if (widget.showPulseEffect) {
      _pulseController.repeat(reverse: true);
      _pulseController.duration = const Duration(milliseconds: 600);
    }
    if (widget.showWaveAnimation) {
      _waveController.repeat();
      _waveController.duration = const Duration(milliseconds: 1200);
    }
  }

  void _startSeriousAnimations() {
    if (widget.showPulseEffect) {
      _pulseController.repeat(reverse: true);
      _pulseController.duration = const Duration(milliseconds: 300);
    }
    if (widget.showWaveAnimation) {
      _waveController.repeat();
      _waveController.duration = const Duration(milliseconds: 800);
    }
  }

  void _stopAllAnimations() {
    _pulseController.stop();
    _waveController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _colorController,
        _pulseController,
        _waveController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: _colorAnimation.value?.withOpacity(0.3) ?? Colors.transparent,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Stack(
              children: [
                // Main content
                widget.child,
                
                // Wave animation overlay
                if (widget.showWaveAnimation && _currentState != VoiceState.idle)
                  _buildWaveOverlay(),
                
                // State indicator
                _buildStateIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: WavePainter(
          waveAnimation: _waveAnimation.value,
          color: _currentColor.withOpacity(0.2),
          state: _currentState,
        ),
      ),
    );
  }

  Widget _buildStateIndicator() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStateIcon(),
            const SizedBox(width: 4),
            Text(
              _getStateText(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _currentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIcon() {
    IconData iconData;
    Color iconColor = _currentColor;
    
    switch (_currentState) {
      case VoiceState.idle:
        iconData = Icons.mic_off;
        break;
      case VoiceState.listening:
        iconData = Icons.mic;
        iconColor = Colors.blue;
        break;
      case VoiceState.activeListening:
        iconData = Icons.mic;
        iconColor = Colors.lightBlue;
        break;
      case VoiceState.thinking:
        iconData = Icons.psychology;
        iconColor = Colors.orange;
        break;
      case VoiceState.speaking:
        iconData = Icons.record_voice_over;
        iconColor = Colors.green;
        break;
      case VoiceState.serious:
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
    }
    
    return Icon(
      iconData,
      size: 12,
      color: iconColor,
    );
  }

  String _getStateText() {
    switch (_currentState) {
      case VoiceState.idle:
        return 'Idle';
      case VoiceState.listening:
        return 'Listening';
      case VoiceState.activeListening:
        return 'Voice Detected';
      case VoiceState.thinking:
        return 'Thinking';
      case VoiceState.speaking:
        return 'Speaking';
      case VoiceState.serious:
        return 'Serious';
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

/// Custom painter for wave animation
class WavePainter extends CustomPainter {
  final double waveAnimation;
  final Color color;
  final VoiceState state;

  WavePainter({
    required this.waveAnimation,
    required this.color,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    
    // Create wave pattern based on state
    switch (state) {
      case VoiceState.listening:
        _drawListeningWave(canvas, size, paint);
        break;
      case VoiceState.activeListening:
        _drawActiveListeningWave(canvas, size, paint);
        break;
      case VoiceState.thinking:
        _drawThinkingWave(canvas, size, paint);
        break;
      case VoiceState.speaking:
        _drawSpeakingWave(canvas, size, paint);
        break;
      case VoiceState.serious:
        _drawSeriousWave(canvas, size, paint);
        break;
      default:
        break;
    }
  }

  void _drawListeningWave(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final y = size.height * 0.5 + (i - 1) * 20;
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 5) {
        final waveY = y + math.sin((x + waveAnimation * 50) * 0.1) * 10;
        path.lineTo(x, waveY);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawActiveListeningWave(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final y = size.height * 0.5 + (i - 2) * 15;
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 3) {
        final waveY = y + math.sin((x + waveAnimation * 100) * 0.15) * 15;
        path.lineTo(x, waveY);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawThinkingWave(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final centerY = size.height * 0.5;
    for (double x = 0; x < size.width; x += 4) {
      final waveY = centerY + math.sin((x + waveAnimation * 30) * 0.08) * 20;
      if (x == 0) {
        path.moveTo(x, waveY);
      } else {
        path.lineTo(x, waveY);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawSpeakingWave(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final y = size.height * 0.5 + (i - 1.5) * 25;
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 6) {
        final waveY = y + math.sin((x + waveAnimation * 40) * 0.12) * 12;
        path.lineTo(x, waveY);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawSeriousWave(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    paint.strokeWidth = 3.0;
    for (int i = 0; i < 2; i++) {
      final y = size.height * 0.5 + (i - 0.5) * 30;
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 8) {
        final waveY = y + math.sin((x + waveAnimation * 80) * 0.2) * 25;
        path.lineTo(x, waveY);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
