import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
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

class _Mouse3DState extends State<Mouse3D> {
  final Logger _logger = Logger();
  String? _src;
  dynamic _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
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
        widget.onReady?.call(_controller);
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
            // 3D Model Viewer
            ModelViewer(
              key: ValueKey(_src),
              src: _src!,
              alt: '3D Mouse Character',
              autoPlay: true,
              autoRotate: true,
              autoRotateDelay: 0,
              cameraControls: true,
              ar: false,
              interactionPrompt: InteractionPrompt.none,
              backgroundColor: Colors.transparent,
              onWebViewCreated: (controller) async {
                _controller = controller;
                _logger.i('🎭 WebView created for 3D model');
                
                // For now, just notify that controller is ready
                // JavaScript injection will be handled by CharacterAnimator
                widget.onReady?.call(controller);
              },
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
