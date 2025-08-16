import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/native_glb_parser_service.dart';

/// 3D Offset class for proper 3D transformations
class Offset3D {
  final double x, y, z;
  const Offset3D(this.x, this.y, this.z);
  
  @override
  String toString() => 'Offset3D(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}

/// Native 3D Model Renderer with Proper 3D Math
/// Renders 3D models using real 3D transformations and proper depth sorting
class Native3DModelRenderer extends StatefulWidget {
  final Model3D model;
  final double width;
  final double height;
  final bool enableRotation;
  final double targetFPS;

  const Native3DModelRenderer({
    super.key,
    required this.model,
    required this.width,
    required this.height,
    this.enableRotation = true,
    this.targetFPS = 30.0,
  });

  @override
  State<Native3DModelRenderer> createState() => _Native3DModelRendererState();
}

class _Native3DModelRendererState extends State<Native3DModelRenderer>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  
  // Performance optimization variables
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;
  
  // Gesture state tracking
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  
  // 3D mesh normalization data
  late Offset3D _meshCenter = const Offset3D(0, 0, 0); // Safe default
  late double _normalizationScale = 1.0; // Safe default
  late List<Offset3D> _normalizedVertices = const []; // Safe default

  @override
  void initState() {
    super.initState();
    
    // Initialize rotation controller
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..addListener(() {
        // CRITICAL FIX: Trigger repaint on each rotation tick
        if (mounted) setState(() {});
      });
    
    // Prepare mesh normalization
    _prepareMeshNormalization();
    
    // Start rotation if enabled
    if (widget.enableRotation) {
      _rotationController.repeat();
    }
  }

  void _prepareMeshNormalization() {
    if (widget.model.vertices.isEmpty) return;
    
    // DEBUG: Log raw model data to understand what we're working with
    if (kDebugMode) {
      print('🎭 DEBUG: Raw model data:');
      print('🎭 DEBUG: - Vertices: ${widget.model.vertices.length}');
      print('🎭 DEBUG: - Faces: ${widget.model.faces.length}');
      print('🎭 DEBUG: - Colors: ${widget.model.colors.length}');
      
      // Log first few vertices to see coordinate ranges
      for (int i = 0; i < math.min(5, widget.model.vertices.length); i++) {
        final v = widget.model.vertices[i];
        print('🎭 DEBUG: - Vertex $i: (${v.x.toStringAsFixed(2)}, ${v.y.toStringAsFixed(2)}, ${v.z.toStringAsFixed(2)})');
      }
      
      // Log first few faces to see if they're valid
      for (int i = 0; i < math.min(5, widget.model.faces.length); i++) {
        final f = widget.model.faces[i];
        print('🎭 DEBUG: - Face $i: v1=${f.v1}, v2=${f.v2}, v3=${f.v3}');
      }
      
      // Validate face indices
      bool hasInvalidFaces = false;
      for (int i = 0; i < widget.model.faces.length; i++) {
        final f = widget.model.faces[i];
        if (f.v1 >= widget.model.vertices.length || 
            f.v2 >= widget.model.vertices.length || 
            f.v3 >= widget.model.vertices.length) {
          print('🎭 ERROR: Face $i has invalid vertex indices: v1=${f.v1}, v2=${f.v2}, v3=${f.v3} (max: ${widget.model.vertices.length - 1})');
          hasInvalidFaces = true;
        }
      }
      if (hasInvalidFaces) {
        print('🎭 ERROR: Model has invalid face indices - this will cause rendering issues!');
      }
    }
    
    // Calculate mesh bounds
    final xs = widget.model.vertices.map((v) => v.x);
    final ys = widget.model.vertices.map((v) => v.y);
    final zs = widget.model.vertices.map((v) => v.z);
    
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);
    final minZ = zs.reduce(math.min);
    final maxZ = zs.reduce(math.max);
    
    // Calculate center
    _meshCenter = Offset3D(
      (minX + maxX) / 2,
      (minY + maxY) / 2,
      (minZ + maxZ) / 2,
    );
    
    // Calculate normalization scale to fit in [-1, 1] range
    final extentX = maxX - minX;
    final extentY = maxY - minY;
    final extentZ = maxZ - minZ;
    final maxExtent = math.max(math.max(extentX, extentY), extentZ);
    
    _normalizationScale = maxExtent == 0 ? 1.0 : 2.0 / maxExtent;
    
    // Pre-compute normalized vertices
    _normalizedVertices = widget.model.vertices.map((v) => Offset3D(
      (v.x - _meshCenter.x) * _normalizationScale,
      (v.y - _meshCenter.y) * _normalizationScale,
      (v.z - _meshCenter.z) * _normalizationScale,
    )).toList();
    
    if (kDebugMode) {
      print('🎭 DEBUG: Mesh normalized - Center: $_meshCenter, Scale: ${_normalizationScale.toStringAsFixed(4)}');
      print('🎭 DEBUG: Normalized bounds - X: ${_normalizedVertices.map((v) => v.x).reduce(math.min).toStringAsFixed(2)} to ${_normalizedVertices.map((v) => v.x).reduce(math.max).toStringAsFixed(2)}');
      print('🎭 DEBUG: Normalized bounds - Y: ${_normalizedVertices.map((v) => v.y).reduce(math.min).toStringAsFixed(2)} to ${_normalizedVertices.map((v) => v.y).reduce(math.max).toStringAsFixed(2)}');
      print('🎭 DEBUG: Normalized bounds - Z: ${_normalizedVertices.map((v) => v.z).reduce(math.min).toStringAsFixed(2)} to ${_normalizedVertices.map((v) => v.z).reduce(math.max).toStringAsFixed(2)}');
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    // Handle scale start
    _startScale = _currentScale;
    _startOffset = _currentOffset;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 1) {
      // Pan gesture
      setState(() {
        _currentOffset = _startOffset + details.focalPointDelta;
      });
    } else if (details.scale != 1.0) {
      // Scale gesture
      setState(() {
        _currentScale = (_startScale * details.scale).clamp(0.1, 5.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _Model3DPainter(
            model: widget.model,
            normalizedVertices: _normalizedVertices,
            rotation: _rotationController.value * 2 * math.pi,
            scale: _currentScale,
            offset: _currentOffset,
            // Removed unused parameters: meshCenter, normalizationScale
          ),
          size: Size(widget.width, widget.height),
        ),
      ),
    );
  }
}

/// Custom Painter for 3D Model Rendering with Real 3D Math
class _Model3DPainter extends CustomPainter {
  final Model3D model;
  final List<Offset3D> normalizedVertices;
  final double rotation;
  final double scale;
  final Offset offset;

  _Model3DPainter({
    required this.model,
    required this.normalizedVertices,
    required this.rotation,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (model.vertices.isEmpty || model.faces.isEmpty) {
      // Debug: Log when model is empty
      if (kDebugMode) {
        print('🎭 DEBUG: Model has ${model.vertices.length} vertices and ${model.faces.length} faces');
      }
      
      // Fallback: Draw a colored rectangle to show the widget is working
      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      
      // Draw text to indicate no model
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'No 3D Model\nVertices: ${model.vertices.length}\nFaces: ${model.faces.length}',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ));
      
      return;
    }
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Debug: Log model dimensions (only occasionally to prevent spam)
    if (kDebugMode && (DateTime.now().millisecond % 30 == 0)) {
      final minX = normalizedVertices.map((v) => v.x).reduce(math.min);
      final maxX = normalizedVertices.map((v) => v.x).reduce(math.max);
      final minY = normalizedVertices.map((v) => v.y).reduce(math.min);
      final maxY = normalizedVertices.map((v) => v.y).reduce(math.max);
      final minZ = normalizedVertices.map((v) => v.z).reduce(math.min);
      final maxZ = normalizedVertices.map((v) => v.z).reduce(math.max);
      print('🎭 DEBUG: Normalized bounds - X: ${minX.toStringAsFixed(2)} to ${maxX.toStringAsFixed(2)}, Y: ${minY.toStringAsFixed(2)} to ${maxY.toStringAsFixed(2)}, Z: ${minZ.toStringAsFixed(2)} to ${maxZ.toStringAsFixed(2)}');
    }
    
    // Apply only pan/zoom transformations to canvas (not 3D rotation)
    canvas.save();
    canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
    canvas.scale(scale);
    
    // Render the 3D model using real 3D transformations
    _renderModelWith3DTransformations(canvas, size);
    
    canvas.restore();
  }

  void _renderModelWith3DTransformations(Canvas canvas, Size size) {
    // Build rotation matrices for 3D transformation
    final double ry = rotation;          // Y-axis rotation (left-right spin)
    final double rx = 0.2 * math.sin(rotation); // X-axis rotation (subtle nod)
    
    final double cosY = math.cos(ry), sinY = math.sin(ry);
    final double cosX = math.cos(rx), sinX = math.sin(rx);
    
    // Transform all vertices with 3D rotation
    final transformedVertices = List<Offset3D>.generate(normalizedVertices.length, (i) {
      final v = normalizedVertices[i];
      
      // Apply Y-axis rotation
      final xY = v.x * cosY + v.z * sinY;
      final zY = -v.x * sinY + v.z * cosY;
      
      // Apply X-axis rotation
      final yX = v.y * cosX - zY * sinX;
      final zX = v.y * sinX + zY * cosX;
      
      return Offset3D(xY, yX, zX);
    });
    
    // Depth sort faces using transformed Z coordinates (back-to-front)
    final faceOrder = List<int>.generate(model.faces.length, (i) => i)
      ..sort((a, b) {
        final faceA = model.faces[a];
        final faceB = model.faces[b];
        
        final zA = (transformedVertices[faceA.v1].z + 
                     transformedVertices[faceA.v2].z + 
                     transformedVertices[faceA.v3].z) / 3;
        final zB = (transformedVertices[faceB.v1].z + 
                     transformedVertices[faceB.v2].z + 
                     transformedVertices[faceB.v3].z) / 3;
        
        return zB.compareTo(zA); // Back to front
      });
    
    // Projection function with proper perspective
    Offset project3DTo2D(double x, double y, double z) {
      final depth = 2.2; // Camera distance in normalized units
      final factor = depth / (depth - z); // Z in front is < depth
      final viewportScale = size.shortestSide * 0.8; // INCREASED from 0.45 to 0.8 for bigger model
      
      return Offset(
        x * factor * viewportScale,
        -y * factor * viewportScale, // Flip Y for screen coordinates
      );
    }
    
    final paint = Paint()..style = PaintingStyle.fill;
    final wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    
    int drawnFaces = 0;
    int skippedFaces = 0;
    
    // Render faces in depth order
    for (final faceIndex in faceOrder) {
      final face = model.faces[faceIndex];
      
      // Get transformed vertices for this face
      final v1 = transformedVertices[face.v1];
      final v2 = transformedVertices[face.v2];
      final v3 = transformedVertices[face.v3];
      
      // Project to 2D
      final p1 = project3DTo2D(v1.x, v1.y, v1.z);
      final p2 = project3DTo2D(v2.x, v2.y, v2.z);
      final p3 = project3DTo2D(v3.x, v3.y, v3.z);
      
      // Simple backface culling using screen-space area sign
      // TEMPORARILY DISABLED FOR TESTING - uncomment when model is visible
      // final area = ((p2.dx - p1.dx) * (p3.dy - p1.dy) - 
      //                (p3.dx - p1.dx) * (p2.dy - p1.dy));
      // if (area >= 0) {
      //   skippedFaces++;
      //   continue; // Skip back faces
      // }
      
      // Skip faces that are too small - REDUCED THRESHOLD FOR TESTING
      final area = ((p2.dx - p1.dx) * (p3.dy - p1.dy) - 
                     (p3.dx - p1.dx) * (p2.dy - p1.dy));
      if (area.abs() < 0.1) { // REDUCED from 2.0 to 0.1 to show ALL faces
        skippedFaces++;
        continue;
      }
      
      // Get color for this face
      final color = faceIndex < model.colors.length 
          ? model.colors[faceIndex] 
          : _generateDynamicColor(faceIndex);
      
      // Draw filled face
      paint.color = color;
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, paint);
      
      // Draw wireframe (subtle)
      wirePaint.color = color.withOpacity(0.15);
      canvas.drawPath(path, wirePaint);
      
      drawnFaces++;
    }
    
    // Debug: Log rendering statistics (only in debug mode)
    if (kDebugMode) {
      print('🎭 DEBUG: Rendered $drawnFaces faces, skipped $skippedFaces faces');
    }
  }

  Color _generateDynamicColor(int index) {
    // Generate colors based on face index for variety
    final hue = (index * 137.5) % 360; // Golden angle for good distribution
    final saturation = 0.7;
    final value = 0.8;
    
    return HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
  }

  @override
  bool shouldRepaint(covariant _Model3DPainter oldDelegate) {
    // Only repaint when necessary for performance
    return oldDelegate.rotation != rotation ||
           oldDelegate.scale != scale ||
           oldDelegate.offset != offset;
  }
}
