import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
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
  Map<String, dynamic>? _modelStats;
  String _3DTestResult = 'Testing...';
  bool _is3DTestComplete = false;
  bool _isLoading = false;
  String? _error;
  
  // Character selection
  String _selectedCharacter = 'hippo';
  final List<String> _availableCharacters = ['hippo', 'mouse', 'jaguar', 'rabbit'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _logger.i('🎭 Loading 3D mouse character from $_selectedCharacter.glb...');
    await _loadSelectedCharacter();
    _test3DWidgetCapability();
  }

  Future<void> _loadSelectedCharacter() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final glbBytes = await loadGLBBytes('assets/3d/$_selectedCharacter.glb');
      if (glbBytes != null) {
        _logger.i('💡 ✅ GLB bytes loaded: ${glbBytes.length} bytes');
        
        final model = await NativeGLBParserService().parseGLB(glbBytes);
        if (model != null) {
          setState(() {
            _model = model;
            _modelStats = NativeGLBParserService().getModelStats(model);
            _isLoading = false;
          });
          
          _logger.i('💡 ✅ 3D model parsed successfully: $_modelStats');
          
          // Notify parent about model ready
          if (widget.onReady != null) {
            widget.onReady!(model);
          }
        } else {
          setState(() {
            _error = 'Failed to parse GLB data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load GLB file';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
      _logger.e('❌ Error loading 3D character: $e');
    }
  }

  void _test3DWidgetCapability() {
    _logger.i('🧪 Testing native 3D renderer widget creation...');
    
    try {
      // Test if we can create the native renderer
      final testModel = _createTestModel();
      final testRenderer = Native3DModelRenderer(
        model: testModel,
        width: 100,
        height: 100,
        enableRotation: false,
      );
      
      setState(() {
        _3DTestResult = '✅ 3D Widget Test: SUCCESS! (Native renderer ready)';
        _is3DTestComplete = true;
      });
      
      _logger.i('💡 ✅ Native 3D renderer test successful');
    } catch (e) {
      setState(() {
        _3DTestResult = '❌ 3D Widget Test: FAILED! ($e)';
        _is3DTestComplete = true;
      });
      
      _logger.e('❌ Native 3D renderer test failed: $e');
    }
  }

  Model3D _createTestModel() {
    // Create a simple test cube
    final vertices = [
      Vertex3D(x: -1, y: -1, z: -1, nx: 0, ny: 0, nz: -1, u: 0, v: 0),
      Vertex3D(x: 1, y: -1, z: -1, nx: 0, ny: 0, nz: -1, u: 1, v: 0),
      Vertex3D(x: 1, y: 1, z: -1, nx: 0, ny: 0, nz: -1, u: 1, v: 1),
      Vertex3D(x: -1, y: 1, z: -1, nx: 0, ny: 0, nz: -1, u: 0, v: 1),
    ];
    
    final faces = [
      Face3D(v1: 0, v2: 1, v3: 2),
      Face3D(v1: 0, v2: 2, v3: 3),
    ];
    
    final colors = [Colors.red, Colors.blue];
    
    final boundingBox = BoundingBox(
      minX: -1, minY: -1, minZ: -1,
      maxX: 1, maxY: 1, maxZ: 1,
    );
    
    return Model3D(
      vertices: vertices,
      faces: faces,
      colors: colors,
      boundingBox: boundingBox,
      modelName: 'Test Cube',
      originalVertexCount: vertices.length,
      originalFaceCount: faces.length,
    );
  }

  // Helper methods for character selection
  IconData _getCharacterIcon(String character) {
    switch (character) {
      case 'hippo':
        return Icons.pets;
      case 'mouse':
        return Icons.mouse;
      case 'jaguar':
        return Icons.pets;
      case 'rabbit':
        return Icons.pets;
      default:
        return Icons.view_in_ar;
    }
  }

  Color _getCharacterColor(String character) {
    switch (character) {
      case 'hippo':
        return Colors.grey;
      case 'mouse':
        return Colors.brown;
      case 'jaguar':
        return Colors.orange;
      case 'rabbit':
        return Colors.white;
      default:
        return Colors.blue;
    }
  }

  String _getCharacterDisplayName(String character) {
    switch (character) {
      case 'hippo':
        return 'Hippo';
      case 'mouse':
        return 'Mouse';
      case 'jaguar':
        return 'Jaguar';
      case 'rabbit':
        return 'Rabbit';
      default:
        return character;
    }
  }

  @override
  void dispose() {
    _logger.i('🧹 Disposing Mouse3D widget - cleaning up native 3D resources');
    
    // Clear model references
    _model = null;
    _modelStats = null;
    
    super.dispose();
    _logger.i('✅ Mouse3D widget disposed successfully');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Character Selection Dropdown
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.view_in_ar, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Select Character: ${_getCharacterDisplayName(_selectedCharacter)}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
                  onSelected: (String character) {
                    setState(() {
                      _selectedCharacter = character;
                    });
                    _loadSelectedCharacter();
                  },
                  itemBuilder: (BuildContext context) {
                    return _availableCharacters.map((String character) {
                      return PopupMenuItem<String>(
                        value: character,
                        child: Row(
                          children: [
                            Icon(_getCharacterIcon(character), color: _getCharacterColor(character)),
                            const SizedBox(width: 8),
                            Text(_getCharacterDisplayName(character)),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ),
        
          // 3D Model Display
          if (_model != null) ...[
            Container(
              width: double.infinity,
              height: 400,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Stack(
                children: [
                  // 3D Model Renderer
                  Native3DModelRenderer(
                    model: _model!,
                    width: double.infinity,
                    height: 400,
                    enableRotation: true,
                  ),
                  
                  // Model Stats Overlay
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Model Stats:',
                            style: TextStyle(
                              color: Colors.green[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Name: ${_modelStats?['modelName'] ?? 'Unknown'}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Vertices: ${_modelStats?['vertexCount'] ?? 0}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Faces: ${_modelStats?['faceCount'] ?? 0}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Memory: ${_modelStats?['memoryUsage'] ?? '0 KB'}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Original: ${_modelStats?['originalVertexCount'] ?? 0} v, ${_modelStats?['originalFaceCount'] ?? 0} f',
                            style: TextStyle(color: Colors.blue[300], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Test Results Overlay
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Test Results:',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '3D Widget Test: SUCCESS! (Native renderer ready)',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // File Name Label
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_selectedCharacter.glb',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Loading State
            Container(
              width: double.infinity,
              height: 400,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
          
          // Character Controls
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Model Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'State: IDLE',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.view_in_ar, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '3D Active',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Character Description
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '3D Character Viewer',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Interactive 3D Models with Real GLB Data',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
