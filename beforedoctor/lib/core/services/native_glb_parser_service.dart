import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert';
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
  final int length;
  final int type;
  final Uint8List data;

  GLBChunk({
    required this.length,
    required this.type,
    required this.data,
  });

  @override
  String toString() => 'GLBChunk(type: $type, length: $length bytes)';
}

/// Native GLB Parser Service
/// Parses GLB files and extracts 3D geometry for rendering
class NativeGLBParserService {
  final Logger _logger = Logger();
  
  /// Parse GLB file and return 3D model data
  Future<Model3D?> parseGLB(Uint8List glbData) async {
    try {
      _logger.i('🧩 Starting GLB parsing...');
      
      // GLB Header: 12 bytes
      if (glbData.length < 12) {
        throw Exception('GLB file too small');
      }
      
      // Check GLB magic number (0x46546C67 = "glTF")
      final magic = glbData.sublist(0, 4);
      if (magic[0] != 0x67 || magic[1] != 0x6C || magic[2] != 0x54 || magic[3] != 0x46) {
        throw Exception('Invalid GLB magic number');
      }
      
      // Parse version and length
      final version = _readUint32(glbData, 4);
      final totalLength = _readUint32(glbData, 8);
      
      _logger.i('✅ GLB header validated: version $version, total length: $totalLength bytes');
      
      // Parse chunks
      final chunks = _parseChunks(glbData, 12);
      _logger.i('📦 Found ${chunks.length} GLB chunks');
      
      // Try to parse real GLB data
      final realModel = _parseRealGLBData(chunks);
      if (realModel != null) {
        _logger.i('✅ Successfully parsed real GLB data: $realModel');
        return realModel;
      }
      
      // Fallback to placeholder if real parsing fails
      _logger.w('⚠️ Real GLB parsing failed, falling back to placeholder model');
      return _createPlaceholderModel('hippo.glb');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to parse GLB: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Parse GLB chunks from binary data
  List<GLBChunk> _parseChunks(Uint8List data, int startOffset) {
    final chunks = <GLBChunk>[];
    int offset = startOffset;
    
    while (offset < data.length - 8) {
      final length = _readUint32(data, offset);
      final type = _readUint32(data, offset + 4);
      
      if (length <= 0 || offset + 8 + length > data.length) {
        _logger.w('⚠️ Invalid chunk at offset $offset: length=$length');
        break;
      }
      
      final chunkData = data.sublist(offset + 8, offset + 8 + length);
      chunks.add(GLBChunk(
        length: length,
        type: type,
        data: chunkData,
      ));
      
      _logger.i('📦 Chunk: type=$type, length=$length bytes');
      offset += 8 + length;
    }
    
    return chunks;
  }

  /// Try to parse real GLB data from chunks
  Model3D? _parseRealGLBData(List<GLBChunk> chunks) {
    try {
      // Find JSON chunk (type 0x4E4F534A = "JSON")
      final jsonChunk = chunks.firstWhere(
        (chunk) => chunk.type == 0x4E4F534A,
        orElse: () => throw Exception('No JSON chunk found'),
      );
      
      // Find BIN chunk (type 0x004E4942 = "BIN")
      final binChunk = chunks.firstWhere(
        (chunk) => chunk.type == 0x004E4942,
        orElse: () => throw Exception('No BIN chunk found'),
      );
      
      _logger.i('📄 JSON chunk: ${jsonChunk.length} bytes');
      _logger.i('💾 BIN chunk: ${binChunk.length} bytes');
      
      // Parse JSON metadata
      final jsonString = utf8.decode(jsonChunk.data);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      // Extract basic info
      final asset = jsonData['asset'] as Map<String, dynamic>?;
      final modelName = asset?['generator'] ?? 'Unknown Model';
      
      _logger.i('🏷️ Model: $modelName');
      
      // For now, create a more realistic model based on GLB data
      // In a full implementation, we would parse the actual mesh data
      return _createRealisticModel(modelName, jsonData, binChunk);
      
    } catch (e) {
      _logger.w('⚠️ Real GLB parsing failed: $e');
      return null;
    }
  }

  /// Create a realistic model based on GLB data
  Model3D _createRealisticModel(String modelName, Map<String, dynamic> jsonData, GLBChunk binChunk) {
    _logger.i('🎨 Creating realistic 3D model: $modelName');
    
    try {
      // Extract mesh information from JSON
      final meshes = jsonData['meshes'] as List<dynamic>? ?? [];
      final accessors = jsonData['accessors'] as List<dynamic>? ?? [];
      final bufferViews = jsonData['bufferViews'] as List<dynamic>? ?? [];
      
      _logger.i('📊 GLB contains: ${meshes.length} meshes, ${accessors.length} accessors, ${bufferViews.length} buffer views');
      
      if (meshes.isEmpty || accessors.isEmpty || bufferViews.isEmpty) {
        _logger.w('⚠️ No valid mesh data found, falling back to placeholder');
        return _createPlaceholderModel(modelName);
      }
      
      // Find the first mesh with vertex data
      final mesh = meshes.first as Map<String, dynamic>;
      final primitives = mesh['primitives'] as List<dynamic>? ?? [];
      
      if (primitives.isEmpty) {
        _logger.w('⚠️ No primitives found in mesh, falling back to placeholder');
        return _createPlaceholderModel(modelName);
      }
      
      final primitive = primitives.first as Map<String, dynamic>;
      final attributes = primitive['attributes'] as Map<String, dynamic>? ?? {};
      
      // Find position, normal, and index accessors
      final positionAccessorIndex = attributes['POSITION'] as int?;
      final normalAccessorIndex = attributes['NORMAL'] as int?;
      final indicesAccessorIndex = primitive['indices'] as int?;
      
      if (positionAccessorIndex == null) {
        _logger.w('⚠️ No position data found, falling back to placeholder');
        return _createPlaceholderModel(modelName);
      }
      
      // Get accessor data
      final positionAccessor = accessors[positionAccessorIndex] as Map<String, dynamic>;
      final positionBufferViewIndex = positionAccessor['bufferView'] as int?;
      
      if (positionBufferViewIndex == null) {
        _logger.w('⚠️ No buffer view for positions, falling back to placeholder');
        return _createPlaceholderModel(modelName);
      }
      
      final positionBufferView = bufferViews[positionBufferViewIndex] as Map<String, dynamic>;
      final positionOffset = positionBufferView['byteOffset'] as int? ?? 0;
      final positionCount = positionAccessor['count'] as int? ?? 0;
      final positionComponentType = positionAccessor['componentType'] as int? ?? 5126; // GL_FLOAT
      final positionType = positionAccessor['type'] as String? ?? 'VEC3';
      
      _logger.i('📐 Position data: count=$positionCount, type=$positionType, offset=$positionOffset');
      
      // Parse vertex positions from binary data
      final vertices = <Vertex3D>[];
      final colors = <Color>[];
      
      if (positionType == 'VEC3' && positionComponentType == 5126) { // GL_FLOAT
        final floatCount = positionCount * 3; // x, y, z
        final dataOffset = positionOffset;
        
        for (int i = 0; i < positionCount; i++) {
          final baseOffset = dataOffset + (i * 12); // 3 floats * 4 bytes
          
          if (baseOffset + 11 < binChunk.data.length) {
            final x = _readFloat32(binChunk.data, baseOffset);
            final y = _readFloat32(binChunk.data, baseOffset + 4);
            final z = _readFloat32(binChunk.data, baseOffset + 8);
            
            // Generate color based on position
            final color = _generateColor(x, y, z);
            
            vertices.add(Vertex3D(
              x: x,
              y: y,
              z: z,
              nx: 0, // Will calculate later
              ny: 0,
              nz: 0,
              u: 0,
              v: 0,
            ));
            colors.add(color);
          }
        }
      }
      
      if (vertices.isEmpty) {
        _logger.w('⚠️ No vertices parsed, falling back to placeholder');
        return _createPlaceholderModel(modelName);
      }
      
      // Parse indices if available
      final faces = <Face3D>[];
      if (indicesAccessorIndex != null) {
        final indicesAccessor = accessors[indicesAccessorIndex] as Map<String, dynamic>;
        final indicesBufferViewIndex = indicesAccessor['bufferView'] as int?;
        
        if (indicesBufferViewIndex != null) {
          final indicesBufferView = bufferViews[indicesBufferViewIndex] as Map<String, dynamic>;
          final indicesOffset = indicesBufferView['byteOffset'] as int? ?? 0;
          final indicesCount = indicesAccessor['count'] as int? ?? 0;
          final indicesComponentType = indicesAccessor['componentType'] as int? ?? 5123; // GL_UNSIGNED_SHORT
          
          _logger.i('🔗 Indices data: count=$indicesCount, type=$indicesComponentType, offset=$indicesOffset');
          
          if (indicesComponentType == 5123) { // GL_UNSIGNED_SHORT
            for (int i = 0; i < indicesCount; i += 3) {
              final baseOffset = indicesOffset + (i * 2); // 2 bytes per index
              
              if (baseOffset + 5 < binChunk.data.length) {
                final v1 = _readUint16(binChunk.data, baseOffset);
                final v2 = _readUint16(binChunk.data, baseOffset + 2);
                final v3 = _readUint16(binChunk.data, baseOffset + 4);
                
                if (v1 < vertices.length && v2 < vertices.length && v3 < vertices.length) {
                  faces.add(Face3D(v1: v1, v2: v2, v3: v3));
                }
              }
            }
          }
        }
      }
      
      // If no faces were parsed, create simple triangulation
      if (faces.isEmpty && vertices.length >= 3) {
        _logger.i('🔗 Creating simple triangulation from ${vertices.length} vertices');
        for (int i = 0; i < vertices.length - 2; i++) {
          faces.add(Face3D(v1: i, v2: i + 1, v3: i + 2));
        }
      }
      
      // Calculate bounding box
      double minX = double.infinity, minY = double.infinity, minZ = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity, maxZ = -double.infinity;
      
      for (final vertex in vertices) {
        minX = math.min(minX, vertex.x);
        minY = math.min(minY, vertex.y);
        minZ = math.min(minZ, vertex.z);
        maxX = math.max(maxX, vertex.x);
        maxY = math.max(maxY, vertex.y);
        maxZ = math.max(maxZ, vertex.z);
      }
      
      final boundingBox = BoundingBox(
        minX: minX, minY: minY, minZ: minZ,
        maxX: maxX, maxY: maxY, maxZ: maxZ,
      );
      
      final model = Model3D(
        vertices: vertices,
        faces: faces,
        colors: colors,
        boundingBox: boundingBox,
        modelName: modelName,
        originalVertexCount: vertices.length,
        originalFaceCount: faces.length,
      );
      
      _logger.i('✅ Real GLB mesh data parsed: Model3D($modelName: ${vertices.length} vertices, ${faces.length} faces)');
      return model;
      
    } catch (e) {
      _logger.w('⚠️ Error parsing real GLB mesh data: $e');
      _logger.i('🔄 Falling back to placeholder model');
      return _createPlaceholderModel(modelName);
    }
  }

  /// Generate colors based on vertex position
  Color _generateColor(double x, double y, double z) {
    // Create vibrant, varied colors with better contrast
    final r = ((x + 1) * 0.5 * 200 + 55).clamp(0, 255).toInt(); // Avoid too dark
    final g = ((y + 1) * 0.5 * 200 + 55).clamp(0, 255).toInt(); // Avoid too dark
    final b = ((z + 1) * 0.5 * 200 + 55).clamp(0, 255).toInt(); // Avoid too dark
    
    // Ensure minimum brightness for visibility
    final minBrightness = 100;
    if (r + g + b < minBrightness * 3) {
      final factor = minBrightness * 3 / (r + g + b);
      return Color.fromARGB(255, 
        (r * factor).clamp(0, 255).toInt(),
        (g * factor).clamp(0, 255).toInt(),
        (b * factor).clamp(0, 255).toInt(),
      );
    }
    
    return Color.fromARGB(255, r, g, b);
  }

  /// Create a placeholder 3D model for testing
  Model3D _createPlaceholderModel(String modelName) {
    _logger.i('🎨 Creating placeholder 3D model: $modelName');
    
    // Create a simple cube
    final vertices = <Vertex3D>[
      // Front face
      Vertex3D(x: -1, y: -1, z: 1, nx: 0, ny: 0, nz: 1, u: 0, v: 0),
      Vertex3D(x: 1, y: -1, z: 1, nx: 0, ny: 0, nz: 1, u: 1, v: 0),
      Vertex3D(x: 1, y: 1, z: 1, nx: 0, ny: 0, nz: 1, u: 1, v: 1),
      Vertex3D(x: -1, y: 1, z: 1, nx: 0, ny: 0, nz: 1, u: 0, v: 1),
      
      // Back face
      Vertex3D(x: -1, y: -1, z: -1, nx: 0, ny: 0, nz: -1, u: 1, v: 0),
      Vertex3D(x: 1, y: -1, z: -1, nx: 0, ny: 0, nz: -1, u: 0, v: 0),
      Vertex3D(x: 1, y: 1, z: -1, nx: 0, ny: 0, nz: -1, u: 0, v: 1),
      Vertex3D(x: -1, y: 1, z: -1, nx: 0, ny: 0, nz: -1, u: 1, v: 1),
      
      // Left face
      Vertex3D(x: -1, y: -1, z: -1, nx: -1, ny: 0, nz: 0, u: 0, v: 0),
      Vertex3D(x: -1, y: -1, z: 1, nx: -1, ny: 0, nz: 0, u: 1, v: 0),
      Vertex3D(x: -1, y: 1, z: 1, nx: -1, ny: 0, nz: 0, u: 1, v: 1),
      Vertex3D(x: -1, y: 1, z: -1, nx: -1, ny: 0, nz: 0, u: 0, v: 1),
      
      // Right face
      Vertex3D(x: 1, y: -1, z: -1, nx: 1, ny: 0, nz: 0, u: 1, v: 0),
      Vertex3D(x: 1, y: -1, z: 1, nx: 1, ny: 0, nz: 0, u: 0, v: 0),
      Vertex3D(x: 1, y: 1, z: 1, nx: 1, ny: 0, nz: 0, u: 0, v: 1),
      Vertex3D(x: 1, y: 1, z: -1, nx: 1, ny: 0, nz: 0, u: 1, v: 1),
      
      // Top face
      Vertex3D(x: -1, y: 1, z: -1, nx: 0, ny: 1, nz: 0, u: 0, v: 1),
      Vertex3D(x: 1, y: 1, z: -1, nx: 0, ny: 1, nz: 0, u: 1, v: 1),
      Vertex3D(x: 1, y: 1, z: 1, nx: 0, ny: 1, nz: 0, u: 1, v: 0),
      Vertex3D(x: -1, y: 1, z: 1, nx: 0, ny: 1, nz: 0, u: 0, v: 0),
      
      // Bottom face
      Vertex3D(x: -1, y: -1, z: -1, nx: 0, ny: -1, nz: 0, u: 1, v: 1),
      Vertex3D(x: 1, y: -1, z: -1, nx: 0, ny: -1, nz: 0, u: 0, v: 1),
      Vertex3D(x: 1, y: -1, z: 1, nx: 0, ny: -1, nz: 0, u: 0, v: 0),
      Vertex3D(x: -1, y: -1, z: 1, nx: 0, ny: -1, nz: 0, u: 1, v: 0),
    ];
    
    // Create faces (triangles) for the cube
    final faces = <Face3D>[
      // Front face
      Face3D(v1: 0, v2: 1, v3: 2),
      Face3D(v1: 0, v2: 2, v3: 3),
      
      // Back face
      Face3D(v1: 4, v2: 5, v3: 6),
      Face3D(v1: 4, v2: 6, v3: 7),
      
      // Left face
      Face3D(v1: 8, v2: 9, v3: 10),
      Face3D(v1: 8, v2: 10, v3: 11),
      
      // Right face
      Face3D(v1: 12, v2: 13, v3: 14),
      Face3D(v1: 12, v2: 14, v3: 15),
      
      // Top face
      Face3D(v1: 16, v2: 17, v3: 18),
      Face3D(v1: 16, v2: 18, v3: 19),
      
      // Bottom face
      Face3D(v1: 20, v2: 21, v3: 22),
      Face3D(v1: 20, v2: 22, v3: 23),
    ];
    
    // Create colors for each face
    final colors = <Color>[
      Colors.blue,    // Front
      Colors.blue,    // Front
      Colors.green,   // Back
      Colors.green,   // Back
      Colors.red,     // Left
      Colors.red,     // Left
      Colors.orange,  // Right
      Colors.orange,  // Right
      Colors.yellow,  // Top
      Colors.yellow,  // Top
      Colors.purple,  // Bottom
      Colors.purple,  // Bottom
    ];
    
    final boundingBox = BoundingBox(
      minX: -1, minY: -1, minZ: -1,
      maxX: 1, maxY: 1, maxZ: 1,
    );
    
    final model = Model3D(
      vertices: vertices,
      faces: faces,
      colors: colors,
      boundingBox: boundingBox,
      modelName: modelName,
      originalVertexCount: vertices.length,
      originalFaceCount: faces.length,
    );
    
    _logger.i('✅ Placeholder 3D model created: $model');
    return model;
  }

  /// Read 32-bit unsigned integer from byte array
  int _readUint32(Uint8List data, int offset) {
    return data[offset] |
           (data[offset + 1] << 8) |
           (data[offset + 2] << 16) |
           (data[offset + 3] << 24);
  }

  /// Read 32-bit floating point number from byte array
  double _readFloat32(Uint8List data, int offset) {
    final bytes = data.sublist(offset, offset + 4);
    return bytes.buffer.asFloat32List()[0];
  }

  /// Read 16-bit unsigned integer from byte array
  int _readUint16(Uint8List data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }

  /// Calculate model statistics
  Map<String, dynamic> getModelStats(Model3D model) {
    return {
      'vertexCount': model.vertices.length,
      'faceCount': model.faces.length,
      'colorCount': model.colors.length,
      'boundingBox': model.boundingBox.toString(),
      'memoryUsage': '${(model.vertices.length * 8 * 8 + model.faces.length * 3 * 4) / 1024} KB',
      'modelName': model.modelName,
      'originalVertexCount': model.originalVertexCount,
      'originalFaceCount': model.originalFaceCount,
    };
  }
}
