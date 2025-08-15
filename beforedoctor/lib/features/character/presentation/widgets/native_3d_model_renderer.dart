import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../../core/services/native_glb_parser_service.dart';

/// Native 3D Model Renderer Widget
/// Renders 3D models using Flutter's Canvas API
class Native3DModelRenderer extends StatefulWidget {
  final Model3D? model;
  final double width;
  final double height;
  final bool enableRotation;
  final Duration rotationDuration;

  const Native3DModelRenderer({
    Key? key,
    this.model,
    this.width = 300,
    this.height = 300,
    this.enableRotation = true,
    this.rotationDuration = const Duration(seconds: 10),
  }) : super(key: key);

  @override
  State<Native3DModelRenderer> createState() => _Native3DModelRendererState();
}

class _Native3DModelRendererState extends State<Native3DModelRenderer>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  
  // Camera/viewport settings
  double _cameraDistance = 3.0;
  double _cameraAngleX = 0.3;
  double _cameraAngleY = 0.0;
  
  // Touch interaction
  Offset? _lastFocalPoint;
  double _panSensitivity = 0.01;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _rotationController = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    if (widget.enableRotation) {
      _rotationController.repeat();
    }
    
    _scaleController.value = 1.0;
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.model == null) {
      return _buildPlaceholder();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          child: AnimatedBuilder(
            animation: Listenable.merge([_rotationController, _scaleController]),
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _Model3DPainter(
                  model: widget.model!,
                  rotationAngle: _rotationController.value * 2 * math.pi,
                  scale: _scaleController.value,
                  cameraDistance: _cameraDistance,
                  cameraAngleX: _cameraAngleX,
                  cameraAngleY: _cameraAngleY,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No 3D Model',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Load a model to render',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    // Stop rotation when scaling
    if (widget.enableRotation) {
      _rotationController.stop();
    }
    _lastFocalPoint = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_lastFocalPoint == null) return;
    
    // Handle pan (translation)
    if (details.pointerCount == 1) {
      final delta = details.focalPoint - _lastFocalPoint!;
      setState(() {
        _cameraAngleY += delta.dx * _panSensitivity;
        _cameraAngleX += delta.dy * _panSensitivity;
        
        // Clamp camera angles
        _cameraAngleX = _cameraAngleX.clamp(-math.pi / 3, math.pi / 3);
        _cameraAngleY = _cameraAngleY.clamp(-math.pi, math.pi);
      });
    }
    
    // Handle scale
    if (details.scale != 1.0) {
      setState(() {
        final newScale = (_scaleController.value * details.scale).clamp(0.5, 3.0);
        _scaleController.value = newScale;
      });
    }
    
    _lastFocalPoint = details.focalPoint;
  }
}

/// Custom Painter for 3D Model Rendering
class _Model3DPainter extends CustomPainter {
  final Model3D model;
  final double rotationAngle;
  final double scale;
  final double cameraDistance;
  final double cameraAngleX;
  final double cameraAngleY;

  _Model3DPainter({
    required this.model,
    required this.rotationAngle,
    required this.scale,
    required this.cameraDistance,
    required this.cameraAngleX,
    required this.cameraAngleY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Apply transformations
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    
    // Apply camera rotation
    canvas.rotate(cameraAngleY);
    canvas.transform(Matrix4.rotationX(cameraAngleX).storage);
    
    // Apply model rotation
    canvas.rotate(rotationAngle);
    
    // Render the 3D model
    _renderModel(canvas, size);
    
    canvas.restore();
  }

  void _renderModel(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;
    
    // Sort faces by Z-depth for proper rendering order
    final sortedFaces = List<int>.generate(model.faces.length, (i) => i);
    sortedFaces.sort((a, b) {
      final faceA = model.faces[a];
      final faceB = model.faces[b];
      
      final zA = (model.vertices[faceA.v1].z + 
                   model.vertices[faceA.v2].z + 
                   model.vertices[faceA.v3].z) / 3;
      final zB = (model.vertices[faceB.v1].z + 
                   model.vertices[faceB.v2].z + 
                   model.vertices[faceB.v3].z) / 3;
      
      return zB.compareTo(zA); // Back to front
    });
    
    // Render each face
    for (final faceIndex in sortedFaces) {
      final face = model.faces[faceIndex];
      final color = model.colors[faceIndex];
      
      // Get vertices for this face
      final v1 = model.vertices[face.v1];
      final v2 = model.vertices[face.v2];
      final v3 = model.vertices[face.v3];
      
      // Project 3D points to 2D
      final p1 = _project3DTo2D(v1.x, v1.y, v1.z);
      final p2 = _project3DTo2D(v2.x, v2.y, v2.z);
      final p3 = _project3DTo2D(v3.x, v3.y, v3.z);
      
      // Draw solid triangle with enhanced color
      paint.color = _enhanceColor(color, faceIndex);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      
      canvas.drawPath(path, paint);
      
      // Draw subtle wireframe for definition (much less visible)
      paint.style = PaintingStyle.stroke;
      paint.color = Colors.black.withOpacity(0.1); // Reduced from 0.3 to 0.1
      paint.strokeWidth = 0.5; // Thinner lines
      canvas.drawPath(path, paint);
      paint.style = PaintingStyle.fill;
    }
  }

  /// Enhance colors for better visibility
  Color _enhanceColor(Color baseColor, int faceIndex) {
    // Add some variation and brightness
    final brightness = 0.8 + (faceIndex % 3) * 0.1; // Vary brightness
    final saturation = 0.9 + (faceIndex % 2) * 0.1; // Vary saturation
    
    return HSVColor.fromColor(baseColor)
        .withValue(brightness)
        .withSaturation(saturation)
        .toColor();
  }

  /// Project 3D coordinates to 2D screen coordinates
  Offset _project3DTo2D(double x, double y, double z) {
    // Simple perspective projection
    final factor = cameraDistance / (cameraDistance + z);
    final projectedX = x * factor * 100; // Scale factor
    final projectedY = y * factor * 100;
    
    return Offset(projectedX, projectedY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
