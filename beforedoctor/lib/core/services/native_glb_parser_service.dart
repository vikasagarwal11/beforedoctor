import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// 3D Vertex with position, normal, and texture coordinates
class Vertex3D {
  final double x, y, z;
  final double nx, ny, nz;
  final double u, v;

  Vertex3D({
    required this.x,
    required this.y,
    required this.z,
    this.nx = 0.0,
    this.ny = 0.0,
    this.nz = 0.0,
    this.u = 0.0,
    this.v = 0.0,
  });

  @override
  String toString() => 'Vertex3D(x: $x, y: $y, z: $z)';
}

/// 3D Face (triangle) defined by three vertex indices
class Face3D {
  final int v1, v2, v3;

  Face3D({
    required this.v1,
    required this.v2,
    required this.v3,
  });

  @override
  String toString() => 'Face3D($v1, $v2, $v3)';
}

/// Parsed 3D Model data
class Model3D {
  final List<Vertex3D> vertices;
  final List<Face3D> faces;
  final List<Color> colors;
  final BoundingBox boundingBox;
  final String modelName;
  final int originalVertexCount;
  final int originalFaceCount;

  Model3D({
    required this.vertices,
    required this.faces,
    required this.colors,
    required this.boundingBox,
    required this.modelName,
    required this.originalVertexCount,
    required this.originalFaceCount,
  });

  @override
  String toString() => 'Model3D($modelName: ${vertices.length} vertices, ${faces.length} faces)';
}

/// 3D Bounding Box for model positioning
class BoundingBox {
  final double minX, minY, minZ;
  final double maxX, maxY, maxZ;

  BoundingBox({
    required this.minX,
    required this.minY,
    required this.minZ,
    required this.maxX,
    required this.maxY,
    required this.maxZ,
  });

  double get width => maxX - minX;
  double get height => maxY - minY;
  double get depth => maxZ - minZ;
  double get centerX => (minX + maxX) / 2;
  double get centerY => (minY + maxY) / 2;
  double get centerZ => (minZ + maxZ) / 2;

  @override
  String toString() => 'BoundingBox(w: ${width.toStringAsFixed(2)}, h: ${height.toStringAsFixed(2)}, d: ${depth.toStringAsFixed(2)})';
}

/// GLB Chunk Header
class GLBChunk {
  final int type;
  final int length;
  final Uint8List data;

  GLBChunk(this.type, this.length, this.data);

  @override
  String toString() => 'GLBChunk(type: $type, length: $length bytes)';
}

/// Parse request with LOD parameters
class ParseRequest {
  final Uint8List glbBytes;
  final int? targetFaceCount;
  
  ParseRequest(this.glbBytes, this.targetFaceCount);
}

/// Native GLB Parser Service with Performance Optimization
/// Parses GLB files asynchronously to prevent main thread blocking
class NativeGLBParserService {
  final Logger _logger = Logger();
  
  // Performance optimization: cache parsed models
  final Map<String, Model3D> _modelCache = {};
  final Map<String, Map<String, dynamic>> _statsCache = {};
  
  // Async parsing queue to prevent blocking
  static final Queue<Completer<Model3D>> _parsingQueue = Queue();
  static bool _isProcessing = false;

  /// Parse GLB data asynchronously to prevent main thread blocking
  Future<Model3D?> parseGLBAsync(Uint8List glbBytes, {String? modelKey, int? targetFaceCount}) async {
    final key = modelKey ?? _generateModelKey(glbBytes);
    
    // Check cache first
    if (_modelCache.containsKey(key)) {
      _logger.i('💾 Returning cached model: $key');
      return _modelCache[key];
    }
    
    // Add to parsing queue
    final completer = Completer<Model3D>();
    _parsingQueue.add(completer);
    
    // Process queue if not already processing
    if (!_isProcessing) {
      _processParsingQueue(glbBytes, key, targetFaceCount);
    }
    
    return completer.future;
  }

  /// Process the parsing queue to prevent multiple simultaneous operations
  void _processParsingQueue(Uint8List glbBytes, String key, int? targetFaceCount) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      while (_parsingQueue.isNotEmpty) {
        final completer = _parsingQueue.removeFirst();
        
        try {
          // Parse on background thread with LOD optimization
          final model = await compute(_parseGLBOnBackground, ParseRequest(glbBytes, targetFaceCount));
          
          if (model != null) {
            // Cache the parsed model
            _modelCache[key] = model;
            _statsCache[key] = getModelStats(model);
            
            completer.complete(model);
            _logger.i('✅ Model parsed and cached: $key (${model.faces.length} faces)');
          } else {
            completer.completeError('Failed to parse GLB data');
          }
        } catch (e) {
          completer.completeError('Parsing error: $e');
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Parse GLB data on background thread with LOD optimization
  static Model3D? _parseGLBOnBackground(ParseRequest request) {
    // This runs on a background thread
    try {
      final model = _parseGLBInternal(request.glbBytes);
      if (model != null && request.targetFaceCount != null) {
        return _applyLODOptimization(model, request.targetFaceCount!);
      }
      return model;
    } catch (e) {
      return null;
    }
  }

  /// Internal GLB parsing logic (runs on background thread)
  static Model3D? _parseGLBInternal(Uint8List glbBytes) {
    try {
      // Validate GLB header
      if (glbBytes.length < 12) return null;
      
      final magic = String.fromCharCodes(glbBytes.take(4));
      if (magic != 'glTF') return null;
      
      final version = _readUint32(glbBytes, 4);
      final totalLength = _readUint32(glbBytes, 8);
      
      if (glbBytes.length != totalLength) return null;
      
      // Parse chunks
      final chunks = _parseChunksInternal(glbBytes);
      if (chunks.length < 2) return null;
      
      // Find JSON and BIN chunks
      final jsonChunk = chunks.firstWhere((c) => c.type == 0x4E4F534A, orElse: () => chunks[0]);
      final binChunk = chunks.firstWhere((c) => c.type == 0x004E4942, orElse: () => chunks[0]);
      
      if (jsonChunk.type != 0x4E4F534A || binChunk.type != 0x004E4942) {
        return null;
      }
      
      // Parse JSON data
      final jsonString = String.fromCharCodes(jsonChunk.data);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      // Extract model name
      final modelName = jsonData['asset']?['generator'] ?? 'Unknown Model';
      
      // Create realistic model from parsed data
      return _createRealisticModelInternal(modelName, jsonData, binChunk);
      
    } catch (e) {
      return null;
    }
  }

  /// Parse GLB chunks on background thread
  static List<GLBChunk> _parseChunksInternal(Uint8List glbBytes) {
    final chunks = <GLBChunk>[];
    int offset = 12; // Skip header
    
    while (offset < glbBytes.length) {
      if (offset + 8 > glbBytes.length) break;
      
      final chunkLength = _readUint32(glbBytes, offset);
      final chunkType = _readUint32(glbBytes, offset + 4);
      
      if (offset + 8 + chunkLength > glbBytes.length) break;
      
      final chunkData = glbBytes.sublist(offset + 8, offset + 8 + chunkLength);
      chunks.add(GLBChunk(chunkType, chunkLength, chunkData));
      
      offset += 8 + chunkLength;
    }
    
    return chunks;
  }

  /// Create realistic model from parsed GLB data (background thread)
  static Model3D _createRealisticModelInternal(String modelName, Map<String, dynamic> jsonData, GLBChunk binChunk) {
    try {
      // Extract mesh information
      final meshes = jsonData['meshes'] as List<dynamic>? ?? [];
      final accessors = jsonData['accessors'] as List<dynamic>? ?? [];
      final bufferViews = jsonData['bufferViews'] as List<dynamic>? ?? [];
      
      if (meshes.isEmpty || accessors.isEmpty || bufferViews.isEmpty) {
        return _createPlaceholderModelInternal(modelName);
      }
      
      // Find position and index accessors
      final positionAccessor = _findPositionAccessor(accessors, meshes);
      final indexAccessor = _findIndexAccessor(accessors, meshes);
      
      if (positionAccessor == null || indexAccessor == null) {
        return _createPlaceholderModelInternal(modelName);
      }
      
      // Parse vertex positions
      final vertices = _parseVertexPositions(binChunk, positionAccessor, bufferViews);
      
      // Parse face indices
      final faces = _parseFaceIndices(binChunk, indexAccessor, bufferViews);
      
      if (vertices.isEmpty || faces.isEmpty) {
        return _createPlaceholderModelInternal(modelName);
      }
      
      // Generate colors and create model
      final colors = _generateColors(vertices.length);
      final boundingBox = _calculateBoundingBox(vertices);
      
      return Model3D(
        vertices: vertices,
        faces: faces,
        colors: colors,
        boundingBox: boundingBox,
        modelName: modelName,
        originalVertexCount: vertices.length,
        originalFaceCount: faces.length,
      );
      
    } catch (e) {
      return _createPlaceholderModelInternal(modelName);
    }
  }

  /// Find position accessor for mesh data
  static Map<String, dynamic>? _findPositionAccessor(List<dynamic> accessors, List<dynamic> meshes) {
    try {
      for (final mesh in meshes) {
        final primitives = mesh['primitives'] as List<dynamic>? ?? [];
        for (final primitive in primitives) {
          final attributes = primitive['attributes'] as Map<String, dynamic>? ?? {};
          final positionAccessorIndex = attributes['POSITION'];
          if (positionAccessorIndex != null && positionAccessorIndex < accessors.length) {
            return accessors[positionAccessorIndex] as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      // Continue with fallback
    }
    return null;
  }

  /// Find index accessor for mesh data
  static Map<String, dynamic>? _findIndexAccessor(List<dynamic> accessors, List<dynamic> meshes) {
    try {
      for (final mesh in meshes) {
        final primitives = mesh['primitives'] as List<dynamic>? ?? [];
        for (final primitive in primitives) {
          final indicesAccessorIndex = primitive['indices'];
          if (indicesAccessorIndex != null && indicesAccessorIndex < accessors.length) {
            return accessors[indicesAccessorIndex] as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      // Continue with fallback
    }
    return null;
  }

  /// Parse vertex positions from binary data
  static List<Vertex3D> _parseVertexPositions(GLBChunk binChunk, Map<String, dynamic> accessor, List<dynamic> bufferViews) {
    try {
      final count = accessor['count'] as int? ?? 0;
      final bufferViewIndex = accessor['bufferView'] as int? ?? 0;
      
      if (bufferViewIndex >= bufferViews.length) return [];
      
      final bufferView = bufferViews[bufferViewIndex] as Map<String, dynamic>;
      final offset = bufferView['byteOffset'] as int? ?? 0;
      final byteStride = bufferView['byteStride'] as int? ?? 12; // 3 floats * 4 bytes
      
      final vertices = <Vertex3D>[];
      
      for (int i = 0; i < count; i++) {
        final byteOffset = offset + (i * byteStride);
        if (byteOffset + 12 <= binChunk.data.length) {
          final x = _readFloat32(binChunk.data, byteOffset);
          final y = _readFloat32(binChunk.data, byteOffset + 4);
          final z = _readFloat32(binChunk.data, byteOffset + 8);
          
          vertices.add(Vertex3D(
            x: x, y: y, z: z,
            nx: 0, ny: 0, nz: 1, // Default normal
            u: 0, v: 0, // Default UV
          ));
        }
      }
      
      return vertices;
    } catch (e) {
      return [];
    }
  }

  /// Parse face indices from binary data
  static List<Face3D> _parseFaceIndices(GLBChunk binChunk, Map<String, dynamic> accessor, List<dynamic> bufferViews) {
    try {
      final count = accessor['count'] as int? ?? 0;
      final bufferViewIndex = accessor['bufferView'] as int? ?? 0;
      
      if (bufferViewIndex >= bufferViews.length) return [];
      
      final bufferView = bufferViews[bufferViewIndex] as Map<String, dynamic>;
      final offset = bufferView['byteOffset'] as int? ?? 0;
      final componentType = accessor['componentType'] as int? ?? 5125; // GL_UNSIGNED_SHORT
      
      final faces = <Face3D>[];
      final indicesPerFace = 3; // Triangles
      
      for (int i = 0; i < count; i += indicesPerFace) {
        if (i + 2 < count) {
          int v1, v2, v3;
          
          if (componentType == 5125) { // GL_UNSIGNED_SHORT
            v1 = _readUint16(binChunk.data, offset + (i * 2));
            v2 = _readUint16(binChunk.data, offset + ((i + 1) * 2));
            v3 = _readUint16(binChunk.data, offset + ((i + 2) * 2));
          } else { // GL_UNSIGNED_INT
            v1 = _readUint32(binChunk.data, offset + (i * 4));
            v2 = _readUint32(binChunk.data, offset + ((i + 1) * 4));
            v3 = _readUint32(binChunk.data, offset + ((i + 2) * 4));
          }
          
          faces.add(Face3D(v1: v1, v2: v2, v3: v3));
        }
      }
      
      return faces;
    } catch (e) {
      return [];
    }
  }

  /// Generate colors for vertices
  static List<Color> _generateColors(int count) {
    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      final hue = (i * 137.5) % 360; // Golden angle for good distribution
      final saturation = 0.7;
      final value = 0.8;
      colors.add(HSVColor.fromAHSV(1.0, hue, saturation, value).toColor());
    }
    return colors;
  }

  /// Calculate bounding box for vertices
  static BoundingBox _calculateBoundingBox(List<Vertex3D> vertices) {
    if (vertices.isEmpty) {
      return BoundingBox(minX: -1, minY: -1, minZ: -1, maxX: 1, maxY: 1, maxZ: 1);
    }
    
    double minX = vertices[0].x, maxX = vertices[0].x;
    double minY = vertices[0].y, maxY = vertices[0].y;
    double minZ = vertices[0].z, maxZ = vertices[0].z;
    
    for (final vertex in vertices) {
      minX = math.min(minX, vertex.x);
      maxX = math.max(maxX, vertex.x);
      minY = math.min(minY, vertex.y);
      maxY = math.max(maxY, vertex.y);
      minZ = math.min(minZ, vertex.z);
      maxZ = math.max(maxZ, vertex.z);
    }
    
    return BoundingBox(
      minX: minX, minY: minY, minZ: minZ,
      maxX: maxX, maxY: maxY, maxZ: maxZ,
    );
  }

  /// Apply Level of Detail optimization to reduce model complexity
  static Model3D _applyLODOptimization(Model3D model, int targetFaceCount) {
    if (model.faces.length <= targetFaceCount) {
      return model; // No optimization needed
    }
    
    // Calculate reduction factor
    final reductionFactor = targetFaceCount / model.faces.length;
    final vertexReductionFactor = math.sqrt(reductionFactor); // Square root for 2D surface area
    
    // Create simplified model
    final simplifiedVertices = <Vertex3D>[];
    final simplifiedFaces = <Face3D>[];
    final simplifiedColors = <Color>[];
    
    // Sample vertices based on reduction factor
    final vertexStep = (1.0 / vertexReductionFactor).round();
    final faceStep = (1.0 / reductionFactor).round();
    
    // Sample vertices
    for (int i = 0; i < model.vertices.length; i += vertexStep) {
      if (i < model.vertices.length) {
        simplifiedVertices.add(model.vertices[i]);
        if (i < model.colors.length) {
          simplifiedColors.add(model.colors[i]);
        }
      }
    }
    
    // Sample faces (ensure we don't exceed target)
    for (int i = 0; i < model.faces.length && simplifiedFaces.length < targetFaceCount; i += faceStep) {
      if (i < model.faces.length) {
        final face = model.faces[i];
        // Ensure face indices are within bounds of simplified vertices
        if (face.v1 < simplifiedVertices.length && 
            face.v2 < simplifiedVertices.length && 
            face.v3 < simplifiedVertices.length) {
          simplifiedFaces.add(face);
        }
      }
    }
    
    // If we still have too many faces, use random sampling
    if (simplifiedFaces.length > targetFaceCount) {
      final random = math.Random(42); // Fixed seed for consistency
      final shuffledFaces = List<Face3D>.from(simplifiedFaces);
      shuffledFaces.shuffle(random);
      simplifiedFaces.clear();
      simplifiedFaces.addAll(shuffledFaces.take(targetFaceCount));
    }
    
    // Create simplified bounding box
    final simplifiedBoundingBox = _calculateBoundingBox(simplifiedVertices);
    
    return Model3D(
      vertices: simplifiedVertices,
      faces: simplifiedFaces,
      colors: simplifiedColors,
      boundingBox: simplifiedBoundingBox,
      modelName: '${model.modelName} (LOD: ${simplifiedFaces.length}/${model.faces.length})',
      originalVertexCount: model.originalVertexCount,
      originalFaceCount: model.originalFaceCount,
    );
  }

  /// Create placeholder model (fallback)
  static Model3D _createPlaceholderModelInternal(String modelName) {
    // Create a simple cube as fallback
    final vertices = [
      Vertex3D(x: -1, y: -1, z: -1, nx: 0, ny: 0, nz: -1, u: 0, v: 0),
      Vertex3D(x: 1, y: -1, z: -1, nx: 0, ny: 0, nz: -1, u: 1, v: 0),
      Vertex3D(x: 1, y: 1, z: -1, nx: 0, ny: 0, nz: -1, u: 1, v: 1),
      Vertex3D(x: -1, y: 1, z: -1, nx: 0, ny: 0, nz: -1, u: 0, v: 1),
      Vertex3D(x: -1, y: -1, z: 1, nx: 0, ny: 0, nz: 1, u: 0, v: 0),
      Vertex3D(x: 1, y: -1, z: 1, nx: 0, ny: 0, nz: 1, u: 1, v: 0),
      Vertex3D(x: 1, y: 1, z: 1, nx: 0, ny: 0, nz: 1, u: 1, v: 1),
      Vertex3D(x: -1, y: 1, z: 1, nx: 0, ny: 0, nz: 1, u: 0, v: 1),
    ];
    
    final faces = [
      Face3D(v1: 0, v2: 1, v3: 2), Face3D(v1: 0, v2: 3, v3: 2), // Front
      Face3D(v1: 1, v2: 5, v3: 6), Face3D(v1: 1, v2: 6, v3: 2), // Right
      Face3D(v1: 5, v2: 4, v3: 7), Face3D(v1: 5, v2: 7, v3: 6), // Back
      Face3D(v1: 4, v2: 0, v3: 3), Face3D(v1: 4, v2: 3, v3: 7), // Left
      Face3D(v1: 3, v2: 2, v3: 6), Face3D(v1: 3, v2: 6, v3: 7), // Top
      Face3D(v1: 4, v2: 5, v3: 1), Face3D(v1: 4, v2: 1, v3: 0), // Bottom
    ];
    
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple, Colors.orange];
    
    return Model3D(
      vertices: vertices,
      faces: faces,
      colors: colors,
      boundingBox: BoundingBox(minX: -1, minY: -1, minZ: -1, maxX: 1, maxY: 1, maxZ: 1),
      modelName: '$modelName (Placeholder)',
      originalVertexCount: vertices.length,
      originalFaceCount: faces.length,
    );
  }

  // Helper methods for binary data reading
  static int _readUint32(Uint8List data, int offset) {
    return data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) | (data[offset + 3] << 24);
  }

  static int _readUint16(Uint8List data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }

  static double _readFloat32(Uint8List data, int offset) {
    final bytes = data.sublist(offset, offset + 4);
    final buffer = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    return buffer.getFloat32(0, Endian.little);
  }

  /// Get model statistics (cached)
  Map<String, dynamic> getModelStats(Model3D model) {
    final key = model.modelName;
    if (_statsCache.containsKey(key)) {
      return _statsCache[key]!;
    }
    
    final stats = _calculateModelStats(model);
    _statsCache[key] = stats;
    return stats;
  }

  /// Calculate model statistics
  Map<String, dynamic> _calculateModelStats(Model3D model) {
    final vertexCount = model.vertices.length;
    final faceCount = model.faces.length;
    final colorCount = model.colors.length;
    
    // Calculate memory usage (approximate)
    final vertexMemory = vertexCount * 32; // 8 floats * 4 bytes
    final faceMemory = faceCount * 12; // 3 ints * 4 bytes
    final colorMemory = colorCount * 4; // 1 int * 4 bytes
    final totalMemory = vertexMemory + faceMemory + colorMemory;
    
    // Calculate bounding box dimensions
    final bb = model.boundingBox;
    final width = (bb.maxX - bb.minX).abs();
    final height = (bb.maxY - bb.minY).abs();
    final depth = (bb.maxZ - bb.minZ).abs();
    
    return {
      'vertexCount': vertexCount,
      'faceCount': faceCount,
      'colorCount': colorCount,
      'boundingBox': BoundingBox(
        minX: bb.minX,
        minY: bb.minY,
        minZ: bb.minZ,
        maxX: bb.maxX,
        maxY: bb.maxY,
        maxZ: bb.maxZ,
      ),
      'memoryUsage': '${(totalMemory / 1024).toStringAsFixed(2)} KB',
      'modelName': model.modelName,
      'originalVertexCount': model.originalVertexCount,
      'originalFaceCount': model.originalFaceCount,
    };
  }

  /// Clear model cache to free memory
  void clearCache() {
    _modelCache.clear();
    _statsCache.clear();
    _logger.i('🧹 Model cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedModels': _modelCache.length,
      'cachedStats': _statsCache.length,
      'totalMemory': '${(_modelCache.length * 1024).toStringAsFixed(2)} KB (estimated)',
    };
  }

  /// Generate a unique key for model caching
  String _generateModelKey(Uint8List glbBytes) {
    // Use first 100 bytes as a simple hash for caching
    final hash = glbBytes.take(100).fold(0, (prev, byte) => prev + byte);
    return 'model_$hash';
  }
}
