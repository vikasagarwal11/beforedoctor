import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../../../../core/services/native_glb_parser_service.dart';
import 'native_3d_model_renderer.dart';

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

/// Loads GLB assets as raw bytes for native parsing
Future<Uint8List> loadGLBBytes(String assetPath) async {
  final Logger logger = Logger();
  
  try {
    logger.i('🎭 Loading GLB asset as bytes: $assetPath');
    
    // Load asset directly in main isolate since rootBundle requires binding
    final ByteData data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    
    logger.i('✅ GLB bytes loaded: ${bytes.length} bytes');
    return bytes;
    
  } catch (e, stackTrace) {
    logger.e('❌ Failed to load GLB bytes: $assetPath', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

/// 3D Mouse Character Widget with Native GLB Parser
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
  Model3D? _model;
  String? _error;
  
  // Character selection - simplified to single character
  final String _selectedCharacter = 'jaguar'; // Use jaguar for best performance

  @override
  void initState() {
    super.initState();
    // Delay heavy operations to prevent frame skipping
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    try {
      _logger.i('🎭 Loading 3D character: $_selectedCharacter...');
      await _loadSelectedCharacter();
    } catch (e) {
      _logger.e('❌ Error initializing Mouse3D: $e');
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadSelectedCharacter() async {
    try {
      final glbBytes = await loadGLBBytes('assets/3d/$_selectedCharacter.glb');
      _logger.i('💡 ✅ GLB bytes loaded: ${glbBytes.length} bytes');
      
      // Use automatic LOD optimization for best performance
      final targetFaceCount = _getOptimalFaceCount(glbBytes.length);
      _logger.i('🎯 Target face count for LOD: $targetFaceCount');
      
      // Use async parsing with LOD optimization to prevent main thread blocking
      final model = await NativeGLBParserService().parseGLBAsync(
        glbBytes, 
        modelKey: _selectedCharacter,
        targetFaceCount: targetFaceCount,
      );
      
      if (model != null) {
        setState(() {
          _model = model;
        });
        
        _logger.i('💡 ✅ 3D model parsed successfully');
        
        // Notify parent about model ready
        if (widget.onReady != null) {
          widget.onReady!(model);
        }
      } else {
        setState(() {
          _error = 'Failed to parse GLB data';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
      _logger.e('❌ Error loading 3D character: $e');
    }
  }

  /// Calculate optimal face count based on file size for LOD optimization
  int _getOptimalFaceCount(int fileSizeBytes) {
    // Base face count based on file size - optimized for voice interaction
    if (fileSizeBytes > 5000000) { // >5MB - very complex model
      return 2000; // Base: 2K faces for smooth performance
    } else if (fileSizeBytes > 2000000) { // >2MB - complex model
      return 5000; // Base: 5K faces for good performance
    } else if (fileSizeBytes > 1000000) { // >1MB - medium model
      return 10000; // Base: 10K faces for balanced performance
    } else {
      return 15000; // Base: 15K faces for simple models
    }
  }

  @override
  void dispose() {
    _logger.i('🧹 Disposing Mouse3D widget - cleaning up native 3D resources');
    
    // Clear model references
    _model = null;
    
    super.dispose();
    _logger.i('✅ Mouse3D widget disposed successfully');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            // 3D Model Display (Essential - Keep)
            if (_model != null) ...[
              Container(
                width: constraints.maxWidth,
                height: 300, // Reduced from 400 to prevent overflow
                margin: const EdgeInsets.all(4), // Further reduced margin
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Native3DModelRenderer(
                  model: _model!,
                  width: constraints.maxWidth,
                  height: 300, // Match container height
                  enableRotation: true,
                ),
              ),
            ] else if (_error != null) ...[
              // Error State
              Container(
                width: constraints.maxWidth,
                height: 300, // Reduced from 400 to prevent overflow
                margin: const EdgeInsets.all(4), // Further reduced margin
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error, color: Colors.red[600], size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading 3D Model',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Loading State (Essential - Keep)
              Container(
                width: constraints.maxWidth,
                height: 300, // Reduced from 400 to prevent overflow
                margin: const EdgeInsets.all(4), // Further reduced margin
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Prevent overflow
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading 3D Character...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selected: $_selectedCharacter',
                        style: TextStyle(
                          color: Colors.blue[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
