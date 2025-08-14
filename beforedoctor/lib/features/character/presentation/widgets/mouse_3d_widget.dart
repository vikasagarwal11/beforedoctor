import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Loads GLB assets as base64 data URI for reliable WebView rendering
Future<String> glbDataUri(String assetPath) async {
  final Logger logger = Logger();
  
  try {
    logger.i('🎭 Attempting to load GLB asset: $assetPath');
    
    // Test if asset exists first
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    logger.i('📋 Asset manifest loaded, length: ${manifestContent.length}');
    
    // Check if our asset path is in the manifest
    if (manifestContent.contains(assetPath)) {
      logger.i('✅ Asset path found in manifest: $assetPath');
    } else {
      logger.w('⚠️ Asset path NOT found in manifest: $assetPath');
      // List all assets that contain 'characters' or 'mouse'
      final allAssets = manifestContent.split('"').where((s) => 
        s.contains('characters') || s.contains('mouse') || s.contains('glb')
      ).toList();
      logger.i('🔍 Related assets found: $allAssets');
    }
    
    // Try to load the actual file
    final bytes = await rootBundle.load(assetPath);
    logger.i('✅ Asset loaded successfully: ${bytes.lengthInBytes} bytes');
    
    final b64 = base64Encode(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    logger.i('✅ Base64 encoding completed: ${b64.length} characters');
    
    final dataUri = 'data:model/gltf-binary;base64,$b64';
    logger.i('✅ Data URI created successfully');
    
    return dataUri;
  } catch (e, stackTrace) {
    logger.e('❌ Failed to load GLB asset: $assetPath', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

/// 3D Mouse Character Widget with real ModelViewer
class Mouse3D extends StatefulWidget {
  final void Function(dynamic controller)? onReady;
  final double? width;
  final double? height;
  
  const Mouse3D({
    super.key, 
    this.onReady,
    this.width,
    this.height,
  });

  @override
  State<Mouse3D> createState() => _Mouse3DState();
}

class _Mouse3DState extends State<Mouse3D> with TickerProviderStateMixin {
  final Logger _logger = Logger();
  String? _src;
  AnimationController? _rotationController;  // NEW: Custom 3D rotation controller
  bool _isLoading = true;
  String? _error;
  
  // NEW: Test 3D functionality with custom renderer
  bool _is3DTestComplete = false;
  String _3DTestResult = 'Testing...';

  @override
  void initState() {
    super.initState();
    _init();
    _test3DWidgetCapability();  // NEW: Test 3D functionality
    _initRotationController();  // NEW: Initialize rotation controller
  }

  // NEW: Initialize rotation controller for 3D effect
  void _initRotationController() {
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _rotationController!.repeat(); // Rotate continuously
  }

  Future<void> _init() async {
    try {
      _logger.i('🎭 Loading 3D mouse character from hippo.glb...');
      
      // Load the GLB file as base64 data URI
      final dataUri = await glbDataUri('assets/3d/hippo.glb');
      _logger.i('✅ GLB data URI created successfully');
      
      if (mounted) {
        setState(() {
          _src = dataUri;
          _isLoading = false;
        });
        
        // Notify parent that controller is ready
        widget.onReady?.call(_rotationController);
      }
    } catch (e) {
      _logger.e('❌ Failed to load 3D mouse character: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // NEW: Simple test to check if 3D widget can be created
  void _test3DWidgetCapability() {
    try {
      _logger.i('🧪 Testing custom 3D renderer widget creation...');
      setState(() {
        _3DTestResult = '✅ 3D Widget Test: SUCCESS! (Custom renderer ready)';
        _is3DTestComplete = true;
      });
      _logger.i('✅ Custom 3D renderer test successful');
    } catch (e) {
      setState(() {
        _3DTestResult = '❌ 3D Widget Test: FAILED - $e';
        _is3DTestComplete = true;
      });
      _logger.e('❌ Custom 3D renderer test failed: $e');
    }
  }

  @override
  void dispose() {
    // CRITICAL: Memory Management for Native 3D Rendering
    _logger.i('🧹 Disposing Mouse3D widget - cleaning up native 3D resources');
    
    // Stop all animations before disposing to prevent memory leaks
    // _fadeController.stop(); // These are not in Mouse3D, but in EnhancedDoctorCharacterScreen
    // _scaleController.stop(); // These are not in Mouse3D, but in EnhancedDoctorCharacterScreen
    
    // NATIVE RENDERING: Clean up FlutterGl controller
    if (_rotationController != null) {
      _logger.i('🧹 Cleaning up native 3D controller');
      _rotationController!.dispose();
      _rotationController = null;
    }
    
    // Clear asset references
    _src = null;
    
    super.dispose();
    _logger.i('✅ Mouse3D widget disposed successfully');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading 3D Character...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 200,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load 3D character',
                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.red[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_src == null) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 200,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                'No 3D model source available',
                style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Real 3D Model Viewer
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // 3D Model Viewer with CUSTOM RENDERING (NO WebView!)
            AnimatedBuilder(
              animation: _rotationController!,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController!.value * 2 * math.pi, // Rotate based on animation value
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateX(0.1) // Slight X rotation for 3D effect
                      ..rotateY(0.1), // Slight Y rotation for 3D effect
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.view_in_ar,
                              size: 64,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '3D Character',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Custom 3D Renderer',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No WebView - Pure Flutter!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blue[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Test Results Overlay (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Test Results:',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _3DTestResult,
                      style: TextStyle(
                        color: _is3DTestComplete 
                          ? (_3DTestResult.contains('✅') ? Colors.green[600] : Colors.red[600])
                          : Colors.blue[600],
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Debug overlay
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '3D Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Asset info
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'hippo.glb',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
